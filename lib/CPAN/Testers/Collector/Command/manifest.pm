package CPAN::Testers::Collector::Command::manifest;
our $VERSION = '0.001';

=head1 SYNOPSIS

  script/collector manifest

=head1 DESCRIPTION

This creates a manifest in the S3 storage which can be used for batch
processing the entire data set. These files consist of a C<MANIFEST> file
with metadata for the manifest job and a set of C<MANIFEST.*> files containing
report IDs and some job-specific metadata.

=cut

use Mojo::Base 'Mojolicious::Command', -signatures, -async_await;
use Getopt::Long qw( GetOptionsFromArray :config pass_through );
use CPAN::Testers::Collector::Storage;
use Time::Piece ();
use JSON::XS qw( decode_json encode_json );
use Log::Any qw( $LOG );
use Parallel::ForkManager;

my $manifest_name = 'manifest';
my $manifest_prefix = $manifest_name . '.';

sub run ($self, @args) {
  my %opt = (
    force => 0,
    page => 1_000_000,
    jobs => 10,
    variants => 0,
  );
  GetOptionsFromArray(\@args, \%opt, 'force', 'variants', 'page=i', 'jobs=i') or pod2usage(1);

  $LOG->info('Starting ' . __PACKAGE__ );
  my $app = $self->app;
  my $storage = $app->storage;

  # First, check if we're already creating a manifest
  $LOG->info('Looking up manifest', {name => $manifest_name});
  my $meta = $storage->read($manifest_name);
  $LOG->info('Got manifest', {content => $meta});
  if ($meta && $meta =~ /Started (\S+)/) {
    if (!$opt{force}) {
      $LOG->error("Existing manifest job", {started => $1});
      return;
    }
    $LOG->info("Ignoring existing manifest job", {started => $1});
  }

  # Lock the manifest for our run
  my $start_dt = Time::Piece->new;
  $storage->write( $manifest_name => "Started " . $start_dt->datetime );

  my $pm = Parallel::ForkManager->new($opt{jobs});
  $pm->set_waitpid_blocking_sleep(0);

  my $page = 1;
  my $write_page = sub ($page_files) {
    my $content = '';
    for my $uuid ( @$page_files ) {
      my @variants;
      if ($opt{variants}) {
        @variants = $storage->variants($uuid);
      }
      $content .= join( ',', $uuid, @variants ) . "\n";
    }
    my $name = "$manifest_prefix$page";
    $storage->write( $name => $content );
    $pm->finish(0);
  };

  # Start listing
  my $iter = $storage->list;
  my @files;
  while (my @page = $iter->()) {
    push @files, @page;
    if (@files >= $opt{page}) {
      my @page_files = splice @files, 0, $opt{page};
      $pm->wait_for_available_procs();
      unless ($pm->start) {
        $write_page->(\@page_files);
        $pm->finish(0);
        return 0;
      }
      $page++;
    }
  }
  $write_page->(\@files) if @files;

  $LOG->info("Waiting for children to finish");
  $pm->wait_all_children;

  # When finished, update the MANIFEST metadata
  my $finish_dt = Time::Piece->new;
  $storage->write( $manifest_name => "Finished " . $finish_dt->datetime . "\n$page pages\n" );

  return 0;
}

1;
