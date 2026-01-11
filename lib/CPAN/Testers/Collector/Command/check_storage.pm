package CPAN::Testers::Collector::Command::check_storage;
our $VERSION = '0.001';

=head1 SYNOPSIS

  script/collector check_storage [config_key]

=head1 DESCRIPTION

This verifies that the given storage, or the default C<storage>, is able
to be written to and read from.

=head1 SEE ALSO

L<CPAN::Testers::Collector::Storage>

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long qw( GetOptionsFromArray :config pass_through );
use Log::Any qw( $LOG );

sub run ($self, @args) {
  $LOG->info('Starting ' . __PACKAGE__ );
  my $app = $self->app;
  my $storage = $app->storage($args[0]);

  $storage->write(check => scalar gmtime);
  say $storage->read('check');

  return 0;
}

1;
