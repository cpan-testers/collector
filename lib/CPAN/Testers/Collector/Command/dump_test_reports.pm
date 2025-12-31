package CPAN::Testers::Collector::Command::dump_test_reports;
our $VERSION = '0.001';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long qw( GetOptionsFromArray :config pass_through );
use CPAN::Testers::Schema;
use CPAN::Testers::Collector::Storage;
use JSON::XS qw( decode_json encode_json );
use Log::Any qw( $LOG );

sub run ($self, @args) {
  my %opt = (
    max => 2_000_000_000, # High enough to get all of them
    page => 100,
  );

  GetOptionsFromArray(\@args, \%opt, 'max=i', 'page=i' ) or pod2usage(1);
  $LOG->info('Starting ' . __PACKAGE__ );
  my ( $reports_root, $start_dt ) = @args;
  $start_dt //= '2000-01-01T00:00:00';

  my $rdb = CPAN::Testers::Collector::Storage->new( Local => $reports_root );
  $LOG->info('Connecting to CPAN::Testers::Schema');
  my $schema = CPAN::Testers::Schema->connect_from_config;
  my $rs = $schema->resultset('TestReport');
  my $total_processed = 0;
  my $got_rows = 0;
  my $dbh = $schema->dbh;

  # Start crawling through the test reports
  # XXX
  while ( $total_processed <= 0 || $got_rows >= $opt{page} ) {
    $LOG->info('Executing read', { total_processed => $total_processed, page_size => $opt{page}, start_dt => $start_dt });
    my $sth = $dbh->prepare('SELECT * FROM test_reports WHERE created >= ? LIMIT ' . $opt{page});
    $sth->execute($start_dt);
    $got_rows = 0;
    while ( my $row = $sth->fetchrow_hashref ) {
      $total_processed++;
      $got_rows++;
      $rdb->write( $row->{id}, encode_json( $row->{report} ), timestamp => $row->{created} );
      $start_dt = $row->{created};
    }
    $LOG->info( "Read rows", { got_rows => $got_rows, page_size => $opt{page}, next_start_dt => $start_dt });
    last if $total_processed >= $opt{max};
  }
  $LOG->info("Finished converting reports");

  return 0;
}
