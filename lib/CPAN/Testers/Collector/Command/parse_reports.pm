package CPAN::Testers::Collector::Command::parse_reports;
our $VERSION = '0.001';

=head1 SYNOPSIS

  script/collector parse_reports --manifest <#>

=head1 DESCRIPTION

This takes a manifest file index (created by C<manifest>) and runs all
the reports in there through L<CPAN::Testers::Collector::Parse>. If there
is no C<.orig> original copy, it creates one before modifying the report.

=cut

use Mojo::Base 'Mojolicious::Command', -signatures, -async_await;
use Getopt::Long qw( GetOptionsFromArray :config pass_through );
use JSON::XS qw( decode_json encode_json );
use Log::Any qw( $LOG );
use Parallel::ForkManager;
use CPAN::Testers::Collector::Parse;

my $manifest_prefix = 'manifest.';
my $original_tag = 'orig';

sub run( $self, @args ) {
  my %opt = (
    manifest => 0,
    jobs => 20,
  );

  GetOptionsFromArray(\@args, \%opt, 'manifest=i', 'jobs=i') or pod2usage(1);

  $LOG->info('Starting ' . __PACKAGE__, {%opt} );
  my $app = $self->app;
  my $storage = $app->storage;
  my $parser = CPAN::Testers::Collector::Parse->new;

  my $pm = Parallel::ForkManager->new($opt{jobs});
  $pm->set_waitpid_blocking_sleep(0);

  # Download the manifest file we've been directed to use
  my $manifest_name = $manifest_prefix . $opt{manifest};
  my @lines = split /\n/, $storage->read($manifest_name);
  $LOG->info('Got manifest', {name => $manifest_name, size => scalar @lines});

  # Loop over the UUIDs
  my $started = 0;
  for my $lines ( @lines ) {
    if ($started++ % 1_000 == 0) {
      $LOG->info('Processed', {started => $started, total => scalar @uuids, pct => sprintf("%02f",($started/@lines)*100), });
    }
    my ($uuid, @variants) = map s/^\s+|\s+$//gr, split ',', $line;

    $pm->wait_for_available_procs;
    unless ($pm->start) {
      local $LOG->context->{pid} = $$;
      local $LOG->context->{uuid} = $uuid;
      local $SIG{__WARN__} = sub(@args) {
        chomp for @args;
        $LOG->warn(@args);
      };

      # Fetch the report
      my $report_json = $storage->read( $uuid );

      # Check if there is an original, otherwise create one.
      # Check the manifest first before trying to list from storage.
      unless ( grep /^$original_tag$/, @variants or grep /^$original_tag$/, $storage->variants($uuid) ) {
        $storage->write( "$uuid.$original_tag" => $report_json );
      }

      # Parse the report
      my $report = decode_json( $report_json );
      my $output = $parser->parse($report);

      # Write the report back
      $storage->write( $uuid => encode_json($output) );

      # Child process done
      $pm->finish(0);
      return 0;
    }
  }

  $LOG->info("Waiting for children to finish");
  $pm->wait_all_children;
}

1;
