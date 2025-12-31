package CPAN::Testers::Collector::Storage;
our $VERSION = '0.001';

=head1 SYNOPSIS

    my $storage = CPAN::Testers::Collector::Storage->new(Local => $root_path);

=head1 DESCRIPTION

This module manages a plain-text database of CPAN Testers reports.

=head1 SEE ALSO

=cut

use v5.40;
use Mojo::Base -base, -signatures;
use Mojo::Loader qw( load_class );
use Log::Any qw( $LOG );

=attr driver

The driver for the actual report storage. Should be one of L<CPAN::Testers::Collector::Storage::Local>
or L<CPAN::Testers::Collector::Storage::S3>.

=cut

has driver => sub { die "Storage driver is required" };

=method new

=cut

sub new( $class, $driver_type, @args ) {
  my $driver_class = "CPAN::Testers::Collector::Storage::${driver_type}";
  if (my $e = load_class $driver_class) {
    die ref $e ? "Exception: $e" : 'Not found!';
  }
  return $class->SUPER::new(
    driver => $driver_class->new(@args),
  );
}

=method write

Write a new report to the storage. The C<$uuid> is required and is
used as the path to write to. C<$content> is a string of content.

=cut

sub write( $self, $uuid, $content ) {
  return $self->driver->write( $uuid, $content );
}

=method read

Read a report by UUID. Returns the string content of the report.

=cut

sub read( $self, $uuid ) {
  return $self->driver->read( $uuid );
}

# TODO: Have a way to list all the reports in a storage so we can
# migrate between them.

1;
