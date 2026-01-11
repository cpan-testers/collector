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
      storage => {
        Local => '/mnt/reports',
      },
      index => {
        SQLite => ':temp:',
      },
  }

The possible configuration keys are below:

=over

=item * storage

Configure where reports are stored. A hash of arguments for L<CPAN::Testers::Collector::Storage/new>.

=item * index

Configure how reports are indexed. A hash of arguments for L<CPAN::Testers::Collector::Index/new>.

=back

=head1 SEE ALSO

L<http://github.com/cpan-testers>,
L<http://www.cpantesters.org>,
L<Mojolicious>,
L<Mojolicious::Plugin::OpenAPI>

=cut

use builtin ':5.40';
use OpenTelemetry::SDK;
use Mojo::Base 'Mojolicious', -signatures;
use File::Share qw( dist_dir dist_file );
use Log::Any::Adapter 'Multiplex' =>
  # Set up Log::Any to log to OpenTelemetry and Stderr so we can still
  # see the local logs.
  adapters => {
    'OpenTelemetry' => [],
    'Stderr' => [],
  };
use Log::Any qw($LOG);
use Mojo::File qw( path );
use Mojo::JSON qw( decode_json );
use OpenAPI::Modern;
use CPAN::Testers::Collector::Storage;
use CPAN::Testers::Collector::Index;

=method startup

  # Called automatically by Mojolicious

This method starts up the application, loads any plugins, sets up routes,
and registers helpers.

=cut

has moniker => 'collector';

sub startup ( $app ) {
  # Remove Mojo::Log from STDERR so that we don't double-log
  $app->log(Mojo::Log->new(handle => undef));
  # Forward Mojo::Log logs to the Log::Any logger, so that from there
  # they will be forwarded to OpenTelemetry.
  # Modules should prefer to log with Log::Any because it supports
  # structured logging.
  $app->log->on( message => sub ( $, $level, @lines ) {
    $LOG->$level(@lines);
  });

  # FIXME: I don't know why, but the OpenTelemetry plugin seems to make the process
  # hang when running Command classes. This is especially noticable when using
  # forked children, as the forked child never exits, and so the parent waits
  # forever.
  # I don't know if it was because I did not
  # use the IO::Async::Loop::Mojo or if Command classes never start the loop
  # and therefore something blocks until the loop is allowed to run. Either way,
  # something in the OpenTelemetry space needs to detect that it is time to die,
  # whether that's detecting global destruction or detecting that we aren't in
  # the async loop and it shouldn't block until we are...
  # Disabling the OpenTelemetry plugin until I no longer need Command classes or
  # until I decide to figure out the real problem...
  #$app->plugin('OpenTelemetry');

  unshift @{ $app->renderer->paths },
    path( dist_dir( 'CPAN-Testers-Collector' ), 'templates' );
  unshift @{ $app->static->paths },
    path( dist_dir( 'CPAN-Testers-Collector' ), 'public' );
  push @{$app->commands->namespaces}, 'CPAN::Testers::Collector::Command';

  $app->plugin( Config => {
    default => {
      storage => {
        Local => './var/reports',
      },
      index => {
        SQLite => ':temp:',
      },
      # A temporary dump of a block of Metabase records,
      # for better parallelization of migration.
      metabase_dump => {
        Local => './var/metabase',
      },
    },
  } );

  $app->plugin( Moai => [ 'Bootstrap4', { version => '4.4.1' } ] );

  # This initializes and returns Storage objects based on config keys.
  # TODO: I really like this pattern of constructor arguments in config,
  # so it might be nice to modularize it.
  $app->helper( storage => sub ($c, $key='storage') {
    state $storage = {};
    return $storage->{$key} ||= CPAN::Testers::Collector::Storage->new(
      %{ $c->config->{$key} || {} },
    );
  });

  $app->helper( index => sub ($c) {
    state $index = CPAN::Testers::Collector::Index->new(
      %{ $c->config->{index} || {} },
    );
    return $index;
  });

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
  $r->get( '/' => sub ($c) { $c->render('index') } );
  $r->get( '/help/:tmpl' => [ tmpl => [qw( report api )]], => sub ($c) { $c->render('help/' . $c->stash('tmpl')) } );

  # API routes
  #my $v1 = $r->under('/v1', sub ($c) { 1 });
  # FIXME: I can't figure out a way to make a good `under` that does
  # validation since I wire up the route to an operation ID by
  # specifying the operation_id stash value. By the time the `under` is
  # called, the stash for the final endpoint hasn't been resolved yet.
  $r->post('/v1/report')->to('report#report_post', operation_id => 'report_post');
  $r->post('/v1/report/:uuid')->to('report#report_post', operation_id => 'report_post_id');
  $r->get('/v1/report/:uuid')->to('report#report_get', operation_id => 'report_get');
  $r->get('/v1/timestamp/:year/:month/:day')->to('report#report_list', operation_id => 'report_list_day');
  $r->get('/v1/timestamp/:year/:month/:day/:hour')->to('report#report_list', operation_id => 'report_list_hour');
  $r->get('/v1/timestamp/:year/:month/:day/:hour/:minute')->to('report#report_list', operation_id => 'report_list_minute');

  # Build API schema
  # I think I have to do all this in order to get the separate JSON
  # schema in the right place with the right URL so it doesn't cause
  # a web request that might fail (it'd potentially be a different
  # version entirely...)
  $app->plugin( 'OpenAPI::Modern' => {
    document_uri => 'api/v1.json',
    document_filename => dist_file('CPAN-Testers-Collector' => 'public/api/v1.json'),
  } );

  my $schema_path = Mojo::File->new( dist_file( 'CPAN-Testers-Collector' => 'public/schema/v1/report.json' ) );
  $app->openapi->evaluator->add_schema(
    'schema/v1/report.json',
    decode_json( $schema_path->slurp ),
  );
}

1;

