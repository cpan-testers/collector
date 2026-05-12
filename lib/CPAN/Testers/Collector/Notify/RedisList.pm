package CPAN::Testers::Collector::Notify::RedisList;

use builtin ':5.40';
use OpenTelemetry;
use Mojo::Base -base, -signatures, -async_await;
use Log::Any qw($LOG);
use Async::Redis;

=attr redis_uri

URI to Redis, a la C<redis://user:pass@host:port/db>.

=cut

has redis_uri => sub { die "redis_uri is required" };

=attr key

Key for the list

=cut

has key => sub { die 'key is required' };

#=attr _redis
#
# An L<Async::Redis> object.
#
#=cut
has _redis => sub( $self ) {
  return Async::Redis->new(
    uri => $self->redis_uri,
    reconnect => 1,
    otel_tracer => OpenTelemetry->tracer_provider->tracer('redis'),
    otel_meter  => OpenTelemetry->meter_provider->meter('redis'),
  );
};

=method publish

=cut

async sub publish( $self, $event, $uuid ) {
  await $self->_redis->lpush($self->key, $uuid);
}

1;
