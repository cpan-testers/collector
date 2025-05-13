package CPAN::Testers::Collector;
our $VERSION = '0.001';
# ABSTRACT: Collect, store, and synchronize CPAN Testers reports

=head1 SYNOPSIS

  $ cpantesters-api daemon
  Listening on http://*:5000

=head1 DESCRIPTION

XXX

=head1 CONFIG

This application can be configured by setting the C<MOJO_CONFIG>
environment variable to the path to a configuration file. The
configuration file is a Perl script containing a single hash reference,
like:

  # collector.conf
  {
      report_root => '/mnt/reports',
  }

The possible configuration keys are below:

=over

=item *

=back

=head1 SEE ALSO

L<http://github.com/cpan-testers>,
L<http://www.cpantesters.org>,
L<Mojolicious>,
L<Mojolicious::Plugin::OpenAPI>

=cut

use Mojo::Base 'Mojolicious', -signatures;
use File::Share qw( dist_dir dist_file );
use Log::Any::Adapter;
use Mojo::File qw( path );

=method startup

  # Called automatically by Mojolicious

This method starts up the application, loads any plugins, sets up routes,
and registers helpers.

=cut

sub startup ( $app ) {
  $app->log( Mojo::Log->new ); # Log only to STDERR
  # Forward Log::Any logs to the Mojo::Log logger
  Log::Any::Adapter->set( 'MojoLog', logger => $app->log );
  # TODO: Set up OpenTelemetry reporting to status.cpantesters.org

  unshift @{ $app->renderer->paths },
    path( dist_dir( 'CPAN-Testers-Collector' ), 'templates' );
  unshift @{ $app->static->paths },
    path( dist_dir( 'CPAN-Testers-Collector' ), 'public' );
  push @{$app->commands->namespaces}, 'CPAN::Testers::Collector::Command';

  $app->moniker( 'collector' );
  $app->plugin( Config => {
    default => {
      report_root => './var/reports',
    },
  } );

  # Allow CORS for everyone
  $app->hook( after_build_tx => sub {
    my ( $tx, $app ) = @_;
    $tx->res->headers->header( 'Access-Control-Allow-Origin' => '*' );
    $tx->res->headers->header( 'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS' );
    $tx->res->headers->header( 'Access-Control-Max-Age' => 3600 );
    $tx->res->headers->header( 'Access-Control-Allow-Headers' => 'Content-Type, X-Requested-With' );
  } );

  my $r = $app->routes;

  # Documentation routes
  $r->get( '/' => 'index' );

  # Legacy compatibility routes
  $r->post( '/api/v1/register' => 'LegacyMetabase#user_post' );
  $r->post( '/api/v1/submit' => 'LegacyMetabase#report_post' );

  # API routes
  $app->plugin( OpenAPI => {
    url => dist_file( 'CPAN-Testers-Collector' => 'public/api/v1.json' ),
    allow_invalid_ref => 1,
  } );
}

1;

