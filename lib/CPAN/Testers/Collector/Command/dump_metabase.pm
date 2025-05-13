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

sub run ($self, @args) {
  my %opt = (
    raw => 0,
    max => 2_000_000_000, # High enough to get all of them
    page => 100,
  );

  GetOptionsFromArray(\@args, \%opt, 'raw|r', 'max=i', 'page=i' ) or pod2usage(1);
  $LOG->info('Starting ' . __PACKAGE__ );
  my ( $reports_root, $start_id ) = @args;
  $start_id //= 0;

  my $rdb = CPAN::Testers::Collector::Storage->new( root => $reports_root );
  $LOG->info('Connecting to CPAN::Testers::Schema');
  my $schema = CPAN::Testers::Schema->connect_from_config;
  my $rs = $schema->resultset('TestReport');
  my $total_processed = 0;
  my $got_rows = 0;

  # Start crawling through the metabase.metabase table
  $LOG->info('Connecting to Metabase');
  my $dbi = DBI->connect('dbi:mysql:mysql_read_default_file=~/.cpanstats.cnf;mysql_read_default_group=application;database=metabase');
  while ( $total_processed <= 0 || $got_rows >= $opt{page} ) {
    $LOG->info('Executing Metabase read', { total_processed => $total_processed, page_size => $opt{page}, start_id => $start_id });
    my $sth = $dbi->prepare('SELECT * FROM metabase.metabase WHERE id >= ? LIMIT ' . $opt{page});
    $sth->execute($start_id);
    $got_rows = 0;
    while ( my $mb_row = $sth->fetchrow_hashref ) {
      $total_processed++;
      $got_rows++;
      if ( $opt{raw} ) {
	$rdb->write( "$mb_row->{guid}.metabase", encode_json( $mb_row ), timestamp => Time::Piece->new( $mb_row->{updated} ) );
      }
      my $metabase_report = $rs->parse_metabase_report( $mb_row );
      my $test_report_row = $rs->convert_metabase_report( $metabase_report );
      $rdb->write( $test_report_row->{id}, encode_json( $test_report_row->{report} ), timestamp => $test_report_row->{created} );
      $start_id = $mb_row->{id} + 1;
    }
    $LOG->info( "Read rows from Metabase", { got_rows => $got_rows, page_size => $opt{page}, next_start_id => $start_id });
    last if $total_processed >= $opt{max};
  }
  $LOG->info("Finished converting Metabase");

  return 0;
}
