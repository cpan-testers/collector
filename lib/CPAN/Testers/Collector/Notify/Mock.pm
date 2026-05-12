package CPAN::Testers::Collector::Notify::Mock;

use builtin ':5.40';
use Mojo::Base -base, -signatures, -async_await;
use Log::Any qw($LOG);

=attr events

An arrayref of events recorded by this instance.

=cut

has events => sub { [] };

=method publish

=cut

async sub publish( $self, $event, $uuid ) {
  push $self->events->@*, { $event, $uuid };
}

1;
