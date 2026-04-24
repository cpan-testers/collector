package CPAN::Testers::Collector::Storage::Local;
our $VERSION = '0.001';

=head1 SYNOPSIS

    my $driver = CPAN::Testers::Collector::Storage::Local->new($root_path);

=head1 DESCRIPTION

This module manages a plain-text database of CPAN Testers reports on a
local filesystem. This should be used as a driver for L<CPAN::Testers::Collector::Storage>.

=head1 SEE ALSO

L<CPAN::Testers::Collector::Storage>

=cut

use v5.40;
use Mojo::Base -base, -signatures;
use Mojo::File qw( path );
use Time::Piece;
use Scalar::Util qw( blessed );
use Log::Any qw( $LOG );

my $starts_with_uuid = qr/^[0-9a-f-]{36}/;
my $is_uuid = qr/$starts_with_uuid\Z/;

=attr root

The root directory of the reports. Individual reports are stored in directories
named after the reports' UUID.

=cut

has root => sub { die "root is required" };

=method new

Create a new storage driver. C<$root> is the root directory to store reports.

=cut

sub new( $class, $root ) {
  return $class->SUPER::new(root => $root);
}

=method write

Write a new report to the storage. The C<$uuid> is required and is
used as the path to write to. C<$content> is a string of content.

=cut

sub write( $self, $uuid, $content ) {
    $LOG->info('Writing to storage', {uuid => $uuid});
    my $path = $uuid =~ $starts_with_uuid ? $self->_uuid_path($uuid) : path($self->root, $uuid);
    $path->dirname->make_path;
    $path->spew($content);
}

=method read

Read a report by UUID. Returns the string content of the report.

=cut

sub read( $self, $uuid ) {
    my $path = $uuid =~ $starts_with_uuid ? $self->_uuid_path($uuid) : path($self->root, $uuid);
    if (-e $path) {
      return $path->slurp;
    }
    return undef;
}

#=method _uuid_path
#
# Create a Mojo::File object for the given UUID with the appropriate path
# parts broken out.
#
sub _uuid_path( $self, $uuid ) {
    $uuid = lc $uuid;
    my ($xx, $yy) = $uuid =~ m{^([0-9a-f]{2})([0-9a-f]{2})};
    my $path = path( $self->root, $xx, $yy, $uuid );
    return $path;
}

=method list

List reports. Returns a subref that returns sets of report UUIDs until there
are no more.

If a prefix is specified, returns any file in storage that matches the prefix.
Otherwise, will only list UUIDs. This way, we can have additional data attached
to reports by adding suffixes like C<.orig> or C<.yath>.

=cut

sub list($self, $prefix='') {
  my $re = $prefix ? qr/^$prefix/ : $is_uuid;
  return sub {
    state $fetched = 0;
    return () if $fetched;
    $fetched = my @files = path($self->root)->list_tree->map(sub { $_->basename })->grep($re)->each;
    say "Fetched $fetched";
    say for @files;
    return @files;
  };
}

1;
