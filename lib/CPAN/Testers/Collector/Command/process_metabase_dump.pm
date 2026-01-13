package CPAN::Testers::Collector::Command::process_metabase_dump;
our $VERSION = '0.001';

=head1 SYNOPSIS

  script/collector process_metabase_dump --shard 0/10

=head1 DESCRIPTION

This script lists all the metabase archives in the C<metabase_dump> storage
(placed there by L<CPAN::Testers::Collector::Command::dump_metabase>)
and processes a shard of them based on the C<--shard> option. C<--shard> should be
a string of C<index/total> where C<index> is this job's index (0-based) and C<total>
is the total number of jobs (so, 10 shards would have indexes from 0-9).

C<--jobs> is the number of parallel processing/uploading workers to run.

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Command', -signatures, -async_await;
use Getopt::Long qw( GetOptionsFromArray :config pass_through );
use CPAN::Testers::Collector::Storage;
use CPAN::Testers::Schema;
use JSON::XS qw( decode_json encode_json );
use Log::Any qw( $LOG );
use IO::Async::Function;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use YAML::XS qw( Load );

# The main loop will fetch from the Metabase dump and hand off processing
# each report to an async worker.
sub run ($self, @args) {
  my %opt = (
    jobs => 10,
    shard => '0/1',
    # Same as from dump_metabase. Used to handle start_id argument.
    page => 50000,
  );

  GetOptionsFromArray(\@args, \%opt, 'jobs=i', 'shard=s', 'page=i' ) or pod2usage(1);
  if ($opt{shard} !~ m{^\s*\d+\s*/\s*\d+\s*$}) {
    pod2usage("--shard must be #/#");
    return 1;
  }
  my $start_id = $args[0] // 0;
  my $first_batch_start_id = $start_id > 0 ? $start_id - ($start_id % $opt{page}) : 0;

  $LOG->info('Starting ' . __PACKAGE__ );
  my $app = $self->app;
  my $metabase_dump_storage = $app->storage('metabase_dump');
  my $loop = IO::Async::Loop->new;

  # List the files from the S3 storage.
  my $s3 = $metabase_dump_storage->driver;
  my $cmd = join " ", "s3cmd", "ls", '--access_key', $s3->access_key_id, '--secret_key', $s3->secret_access_key, '--host', $s3->endpoint, '--host-bucket', q{'%(bucket)s.} . $s3->endpoint . q{'}, "s3://" . $s3->bucket;
  my @lines = qx{$cmd};
  my @files;
  for my $line (@lines) {
    my (undef, undef, undef, $uri) = split /\s+/, $line;
    my ($file_path) = $uri =~ m{^s3://[^/]+/(.+)$};
    push @files, $file_path;
  }
  @files = map { $_->[0] }
    # Sort by the ID inside the filename so shards work on the right file
    sort { $a->[1] <=> $b->[1] }
    # Remove files before the one containing the start_id
    grep { $_->[1] >= $first_batch_start_id }
    # Get the numeric ID from the filename
    map { [ $_, m{(\d+)} ] } @files;
  $LOG->debug('Got file list', { count => scalar @files });

  # Prepare the worker process for reformatting and uploading individual files.
  my $proc = IO::Async::Function->new(
    code => sub( $count, $mb_row ) {
      # This doesn't actually need to connect to the schema, but
      # there are data migration routines in the TestReport resultset
      # class that we need.
      state $schema;
      if (!$schema) {
        $LOG->info('Worker starting', { pid => $$, uuid => $mb_row->{guid}, count => $count, });
        if ( $app->config->{db} ) {
            $LOG->debug("Connecting to " . $app->config->{db}{dsn}, { pid => $$, count => $count, });
            $schema = CPAN::Testers::Schema->connect( $app->config->{db}->@{qw( dsn username password args )} );
        }
        else {
          $LOG->debug('Connecting to CPAN::Testers::Schema', { pid => $$, count => $count, });
          $schema = CPAN::Testers::Schema->connect_from_config;
        }
      }
      state $rs = $schema->resultset('TestReport');
      state $report_storage = $app->storage;

      $LOG->debug('Worker received', { pid => $$, uuid => $mb_row->{guid}, count => $count, });
      # See if we need to actually process this file
      local $@;
      eval {
        $app->storage->driver->_bucket->file($mb_row->{guid});
      };
      if (!$@) {
        $LOG->debug('File exists, skipping', { uuid => $mb_row->{guid}, count => $count });
        return;
      }
      # File must not exist, so let's go!
      eval {
        write_report($report_storage, $rs, $mb_row );
      };
      if (my $e = $@) {
        $LOG->error('Worker error', { pid => $$, uuid => $mb_row->{guid}, error => $e, count => $count, });
        die $e;
      }
      $LOG->debug('Worker wrote report', { pid => $$, uuid => $mb_row->{guid}, count => $count, });
    },
    max_workers => $opt{jobs},
    # Prevent memory leakage by recycling workers
    max_worker_calls => 100,
  );
  $loop->add($proc);
  $proc->start;

  # Start crawling through the files created by dump_metabase
  my ($shard_index, $shard_total) = split m{/}, $opt{shard};
  # Every shard should do one page based on its shard index and then skip the $shard_total pages to
  # get the next page it should work on.
  my $iteration = 0;
  my $current_index = ($iteration*$shard_total)+$shard_index;
  my $processed_count = 0;
  while ($current_index < @files) {
    my $file = $files[$current_index];
    $LOG->info('Downloading file from s3', {i => $iteration, index => $current_index, file => $file});

    # Download the compressed file, because s3cmd doesn't support streaming.
    # Why would it? Nobody writes shell scripts anymore, and there's no such
    # thing as integration of heterogeneous systems. Use the SDK for your
    # Amazon-approved programming language, pleb.
    system "s3cmd", "get",
      '--access_key', $s3->access_key_id,
      '--secret_key', $s3->secret_access_key,
      '--host', $s3->endpoint,
      '--host-bucket', '%(bucket)s.' . $s3->endpoint,
      "s3://" . $s3->bucket . '/' . $file,
      $file;

    # Stream the decompression of the file to reduce memory usage. As we get single YAML
    # documents, pass them off to workers to process.
    $LOG->info('Reading file', {i => $iteration, index => $current_index, file => $file});
    my $yaml_buffer = '';
    my @promises;
    open my $fh, '-|', "gunzip -c $file" or die "Could not open pipe to gunzip: $!";
    while (my $line = <$fh>) {
      #$LOG->debug('Got line', { line => $line });
      # Look for document markers. We're ignoring any document tags because
      # I didn't add them in the dump_metabase command, and I don't feel like
      # dealing with it.
      # TODO: Find or write an IO::Async::Handle for iterating over single YAML
      # documents?
      if ($line =~ m{^---\s*$} && $yaml_buffer) {
        $processed_count++;
        my $mb_row = YAML::XS::Load($yaml_buffer);
        $LOG->debug('Sending job to worker', { uuid => $mb_row->{guid}, processed_count => $processed_count });
        push @promises, $proc->call(args => [$processed_count, $mb_row]);
        $yaml_buffer = '';
      }

      $yaml_buffer .= $line;
    }
    close $fh;

    # After we're done with a single file, wait for a sync check. I'm not sure what the
    # high water mark on calls to IO::Async::Function is, so I don't want to just
    # toss everything at it and let memory grow unbounded as we queue up jobs.
    # TODO: Ask Leonerd about high water mark for IO::Async::Function?
    my $waiting_since = "".gmtime;
    my $timer = IO::Async::Timer::Periodic->new(
      interval => 30,
      first_interval => 0,
      on_tick => sub {
        $LOG->info('Waiting for workers', {i => $iteration, index => $current_index, file => $file, since => $waiting_since});
      },
    );
    $loop->add($timer);
    $timer->start;
    my $future = Future->wait_all( @promises )->then(sub { $loop->stop });
    $loop->run;
    $loop->remove( $timer );
    $timer->stop;

    # Let's go to the next file!
    $LOG->info('Deleting file', {i => $iteration, index => $current_index, file => $file});
    unlink $file;

    $iteration++;
    $current_index = ($iteration*$shard_total)+$shard_index;
  }

  $LOG->info("Finished converting Metabase",{ last_index => $current_index, count => scalar @files });
  return 0;
}

sub write_report( $storage, $rs, $mb_row ) {
  my $metabase_report = $rs->parse_metabase_report( $mb_row );
  my $test_report_row = $rs->convert_metabase_report( $metabase_report );
  $storage->write( $test_report_row->{id}, encode_json( $test_report_row->{report} ) );
}

1;
