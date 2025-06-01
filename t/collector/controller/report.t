
use Test::Mojo;
use Test2::V0;
use File::Temp;
use Data::GUID;
use Mojo::JSON qw( encode_json );

my $tempdir = File::Temp->newdir;

my $t = Test::Mojo->new('CPAN::Testers::Collector', {
  storage => {
    root => $tempdir->dirname,
  },
});

my $minimum_report = {
  reporter => {
    email => 'doug@example.com',
  },
  environment => {
    language => {
      name => 'Perl',
      version => '5.40.0',
      archname => 'x86_64-linux',
    },
    system => {
      osname => 'Linux',
    },
  },
  distribution => {
    name => 'Local-Example',
    version => '1.0.0',
  },
  result => {
    grade => 'pass',
    output => {
    },
  },
};

subtest 'report_post' => sub {
  $t->post_ok('/v1/report', json => $minimum_report)->status_is(201);
  $t->json_like('/0', qr{.{32}}, 'returns the report UUID');
  my $uuid = $t->tx->res->json->[0];
  ok $t->app->storage->read( $uuid ), 'report exists in storage';

  # XXX: should handle validation failures
};

subtest 'report_get' => sub {
  my $uuid = Data::GUID->new;
  $t->app->storage->write( $uuid => encode_json( $minimum_report ) );
  $t->get_ok('/v1/report/' . $uuid)->status_is(200)->json_is($minimum_report);

  # XXX: should work for both lc $uuid and uc $uuid
  # XXX: should handle 404s
};

done_testing;
