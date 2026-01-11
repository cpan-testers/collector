package CPAN::Testers::Collector::Command::dump_metabase;
our $VERSION = '0.001';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long qw( GetOptionsFromArray :config pass_through );
use CPAN::Testers::Collector::Storage;
use CPAN::Testers::Schema;
use DBIx::Connector;
use JSON::XS qw( decode_json encode_json );
use Log::Any qw( $LOG );
use Parallel::ForkManager;
use YAML::XS qw( Dump );
use POSIX;

# The main loop will fetch from the Metabase and dump to object storage.
sub run ($self, @args) {
  my %opt = (
    page => 50000,
    jobs => 10,
  );

  GetOptionsFromArray(\@args, \%opt, 'page=i', 'jobs=i') or pod2usage(1);
  $LOG->info('Starting ' . __PACKAGE__ );

  my $app = $self->app;

  my $storage = $app->storage('metabase_dump');

  $LOG->info("Connecting to " . $app->config->{db}{dsn});
  my $conn = DBIx::Connector->new($app->config->{db}->@{qw( dsn username password args )});
  $conn->mode('fixup');
  $conn->disconnect_on_destroy(0);
  my $pm = Parallel::ForkManager->new($opt{jobs});
  $pm->set_waitpid_blocking_sleep(0);

  # Start crawling through the metabase.metabase table
  $LOG->info('Connecting to Metabase');

  # Dump will dump files to storage with a single page of rows
  # Then workers can read those files and fix them
  my ( $min, $max ) = $conn->dbh->selectrow_array( 'SELECT MIN(id), MAX(id) FROM metabase.metabase' );
  my $index = 1;
  my $start = $args[0] || ( $min - ( $min % $opt{page} ) );
  my $end = $start + $opt{page};
  while ( $start <= $max ) {
    $pm->wait_for_available_procs();
    my $filename = "metabase.$start.yaml";
    $conn->run(sub {
      $LOG->info( "Executing metabase query", {start => $start, end => $end, index => $index, pid => $$} );
      my $sth = $_->prepare( "SELECT * FROM metabase.metabase WHERE id >= ? AND id < ?" );
      $sth->execute( $start, $end );

      $LOG->info( "Fetching rows", {start => $start, end => $end, index => $index, pid => $$, filename => $filename} );
      open my $fh, '>', $filename;
      while ( my $row = $sth->fetchrow_hashref ) {
          say { $fh } Dump( $row );
      }
      close $fh;
      $sth->finish;
    });

    # Handle the actual upload in a child process so we can keep reading from the database.
    unless ($pm->start) {
      my $s3 = $storage->driver;
      $LOG->info( "Compressing", {start => $start, end => $end, index => $index, pid => $$, filename => $filename} );
      system "gzip", $filename;
      $filename .= '.gz';
      $LOG->info( "Uploading", {start => $start, end => $end, index => $index, pid => $$, filename => $filename} );
      system "s3cmd", "put", '--access_key', $s3->access_key_id, '--secret_key', $s3->secret_access_key, '--host', $s3->endpoint, '--host-bucket', '%(bucket)s.' . $s3->endpoint, $filename, "s3://" . $s3->bucket;
      $LOG->info( "Deleting", {start => $start, end => $end, index => $index, pid => $$, filename => $filename} );
      unlink $filename;
      $LOG->info( "Finishing", {start => $start, end => $end, index => $index, pid => $$, filename => $filename} );
      $pm->finish(0);
      $LOG->info( "Finished", {start => $start, end => $end, index => $index, pid => $$, filename => $filename} );
      return 0;
    }

    $start = $end;
    $end = $start + $opt{page};
    $index++;
  }
  $LOG->info("Waiting for children to finish");
  $pm->wait_all_children;

  return 0;
}

1;
