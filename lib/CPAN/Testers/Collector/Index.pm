package CPAN::Testers::Collector::Index;
our $VERSION = '0.001';

=head1 SYNOPSIS

    my $index = CPAN::Testers::Collector::Index->new(
      # Use Postgres
      Pg => 'pg://...',
      Pg => Mojo::Pg->new(...),
      # or use SQLite
      SQLite => 'sqlite://...',
      SQLite => Mojo::SQLite->new(...),
    );

=head1 DESCRIPTION

This module manages indexing of the CPAN Testers reports for basic
synchronization.

=head1 SEE ALSO

L<CPAN::Testers::Collector::Storage>

=cut

use v5.40;
use Mojo::Base -base, -signatures;
use Log::Any qw( $LOG );
use Mojo::Loader qw( load_class );

=attr dbh

The database handle. Can be a L<Mojo::Pg> or L<Mojo::SQLite> object.

=cut

has dbh => sub { die "A database is required" };

=method new

When built, the appropriate DDL for the given database will be executed.

=cut

sub new( $class, $dbc, @args ) {
  my $db_class = "Mojo::${dbc}";
  if (my $e = load_class $db_class) {
    die "Could not load $db_class: " . $e;
  }

  my $dbh = $db_class->new(@args);
  my $self = $class->SUPER::new(dbh => $dbh);

  # Mojo::Pg and Mojo::SQLite allow cloning a database handle by
  # passing it in as an argument to new(), so we won't clobber
  # any existing migrations.
  $dbh->migrations->name('collector')->from_data(__PACKAGE__, $dbc)->migrate;

  return $self;
}

=method insert

Insert a new index record. The C<$uuid> and C<$timestamp> are required.
The timestamp should be in ISO8601 format.

=cut

sub insert( $self, $report_uuid, $timestamp ) {
  my $row = {report_uuid => $report_uuid, timestamp => $timestamp};
  $LOG->info('Inserting index record', $row);
  $self->dbh->db->insert( storage_index => $row );
}

=method select

Select reports from the index. Returns a L<Mojo::Collection> of report UUIDs.
Query can include the following fields:

    from - Timestamp to start search from in ISO8601 format
    to - Timestamp to search to (inclusive) in ISO8601 format

=cut

sub select( $self, %search ) {
  my %query = (
    -and => [
      ( $search{from} ? ( timestamp => { '>=' => $search{from} } ) : () ),
      ( $search{to} ? ( timestamp => { '<=' => $search{to} } ) : () ),
    ],
  );
  my $res = $self->dbh->db->select( storage_index => ['report_uuid'], \%query );
  return $res->arrays->map(sub { $_->[0] });
}

1;
__DATA__
## Migrations should be named after the short name of the database class, like
# Mojo::Pg -> Pg
# Mojo::SQLite -> SQLite

@@ Pg
-- 1 up

-- 1 down

@@ SQLite
-- 1 up
CREATE TABLE storage_index (
  report_uuid TEXT PRIMARY KEY NOT NULL COLLATE NOCASE,
  timestamp TEXT NOT NULL COLLATE NOCASE
) STRICT;
CREATE INDEX storage_index_timestamp
  ON storage_index (timestamp);

-- 1 down
DROP TABLE storage_index;
