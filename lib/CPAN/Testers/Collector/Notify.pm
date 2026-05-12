package CPAN::Testers::Collector::Notify;

use builtin ':5.40';
use OpenTelemetry;
use Mojo::Base -base, -signatures, -async_await;
use Log::Any qw($LOG);
use List::Util qw( pairs );
use Mojo::Loader qw( load_class );

=attr on_report

=cut

has on_report => sub { [] };

=attr on_parse

=cut

has on_parse => sub { [] };

=method new

=cut

sub new( $class, @args ) {
  my $self = $class->SUPER::new(@args);
  for my $event (qw( on_report on_parse )) {
    my @drivers;
    for my $pair (pairs $self->$event->@*) {
      my $class = "CPAN::Testers::Collector::Notify::$pair->[0]";
      load_class $class;
      push @drivers, $class->new($pair->[1]);
    }
    $self->$event(\@drivers);
  }
  return $self;
}

=method publish

Publish the given event to all configured notifiers.

=cut

async sub publish( $self, $event, $uuid ) {
  await Mojo::Promise->all( map { $_->publish( $event, $uuid ) } $self->$event->@* );
}

1;
