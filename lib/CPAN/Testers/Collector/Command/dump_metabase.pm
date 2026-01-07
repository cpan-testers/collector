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
use JSON::XS qw( decode_json encode_json );
use Log::Any qw( $LOG );
use IO::Async::Routine;
use IO::Async::Channel;
use IO::Async::Loop;

# The main loop will fetch from the Metabase and hand off processing
# each report to an async worker.
sub run ($self, @args) {
  my %opt = (
    max => 2_000_000_000, # High enough to get all of them
    page => 5000,
    jobs => 10,
  );

  GetOptionsFromArray(\@args, \%opt, 'max=i', 'page=i', 'jobs=i' ) or pod2usage(1);
  $LOG->info('Starting ' . __PACKAGE__ );
  my ( $start_id ) = @args;
  $start_id //= 0;

  my $storage = $self->app->storage;
  $LOG->info('Connecting to CPAN::Testers::Schema');
  my $schema = CPAN::Testers::Schema->connect_from_config;
  my $rs = $schema->resultset('TestReport');

  $LOG->info('Spawning workers');
  my $loop = IO::Async::Loop->new;
  my %worker_ch;
  my %done_ch;
  for my $worker_id ( 0..$opt{jobs}-1 ) {
    my $done_ch = IO::Async::Channel->new;
    my $worker_ch = IO::Async::Channel->new;
    my $worker = IO::Async::Routine->new(
       channels_in  => [ $worker_ch ],
       channels_out => [ $done_ch ],
       code => sub {
         $LOG->debug('Worker loop start', { worker_id => $worker_id });
         while (my $mb_row = $worker_ch->recv) {
           $LOG->debug('Worker received', { worker_id => $worker_id, uuid => $mb_row->{guid} });
           write_report($storage, $rs, $mb_row, %opt );
           $done_ch->send($worker_id);
           $LOG->debug('Worker wrote report', { worker_id => $worker_id, uuid => $mb_row->{guid} });
         }
	       $LOG->debug('Worker loop end', { worker_id => $worker_id });
	       return 0;
       },
       on_finish => sub {
	       $LOG->debug('Worker ended', { worker_id => $worker_id });
       },
    );
    $worker_ch{ $worker_id } = $worker_ch;
    $done_ch{ $worker_id } = $done_ch;
    $loop->add( $worker );
  }

  # Start crawling through the metabase.metabase table
  $LOG->info('Connecting to Metabase');
  my $dbi = $schema->storage->dbh;
  my $sth = $dbi->prepare('SELECT * FROM metabase.metabase WHERE id >= ? LIMIT ' . $opt{page});
  my $total_processed = 0;
  my $got_rows = 0;

  $LOG->info('Executing Metabase read', { total_processed => $total_processed, page_size => $opt{page}, start_id => $start_id });
  $sth->execute($start_id);
  for my $worker_id ( keys %worker_ch ) {
    my $mb_row = $sth->fetchrow_hashref;
    last if !$mb_row;
    $got_rows++;
    $start_id = $mb_row->{id} + 1;

    # Let a worker signal it is done
    $done_ch{$worker_id}->configure(on_recv => sub {
		  my ($ch, $worker_id) = @_;
	    $LOG->debug( "Manager receive done", { worker_id => $worker_id } );
	    $total_processed++;
	    # ... and then add another
	    my $mb_row = $sth->fetchrow_hashref;
	    if (!$mb_row && $got_rows >= $opt{page}) {
	      # We're out of rows on this execution, so let's find the next page
	      $LOG->info( "Read rows from Metabase", { got_rows => $got_rows, page_size => $opt{page}, next_start_id => $start_id });
	      return if $total_processed >= $opt{max};

	      $LOG->info('Executing Metabase read', { total_processed => $total_processed, page_size => $opt{page}, start_id => $start_id });
	      $got_rows = 0;
	      $sth->execute($start_id);
	      $mb_row = $sth->fetchrow_hashref;
	    }
	    return if !$mb_row;
	    $got_rows++;
	    $start_id = $mb_row->{id} + 1;
	    $LOG->debug( "Manager send", { worker_id => $worker_id } );
	    $worker_ch{$worker_id}->send($mb_row);
    });
    # Add an initial row to each worker
    $LOG->debug( "Manager send", { worker_id => $worker_id, uuid => $mb_row->{guid} } );
    $worker_ch{$worker_id}->send($mb_row);
  }

  $LOG->debug('Starting loop');
  $loop->run;
  $LOG->info("Finished converting Metabase");

  return 0;
}

sub write_report( $storage, $rs, $mb_row, %opt ) {
  my $metabase_report = $rs->parse_metabase_report( $mb_row );
  my $test_report_row = $rs->convert_metabase_report( $metabase_report );
  $storage->write( $test_report_row->{id}, encode_json( $test_report_row->{report} ) );
}
