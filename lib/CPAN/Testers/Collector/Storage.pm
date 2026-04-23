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

The drivers for the actual report storage. Each driver should be one of L<CPAN::Testers::Collector::Storage::Local>
or L<CPAN::Testers::Collector::Storage::S3>. Drivers are read from in order, and written to collectively.

=cut

has drivers => sub { [] };

=method new

=cut

sub new( $class, @args ) {
  my $self = $class->SUPER::new;
  while (@args) {
    my ($driver_type, $driver_arg) = (shift @args, shift @args);
    my $driver_class = "CPAN::Testers::Collector::Storage::${driver_type}";
    if (my $e = load_class $driver_class) {
      die ref $e ? "Exception: $e" : 'Not found!';
    }
    push $self->drivers->@*, $driver_class->new($driver_arg)
  }
  return $self;
}

=method write

Write a new report to the storage. The C<$uuid> is required and is
used as the path to write to. C<$content> is a string of content.

=cut

sub write( $self, $uuid, $content ) {
  for my $d ( $self->drivers->@* ) {
    $d->write( $uuid, $content );
  }
  return;
}

=method read

Read a report by UUID. Returns the string content of the report.

=cut

sub read( $self, $uuid ) {
  for my $d ( $self->drivers->@* ) {
    if (my $content = $d->read($uuid)) {
      return $content;
    }
  }
  return undef;
}

# TODO: Have a way to list all the reports in a storage so we can
# migrate between them.

1;
