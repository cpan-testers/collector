
use v5.40;
use Test::Mojo;
use Test2::V0;
use File::Temp;
use Data::GUID;
use Mojo::JSON qw( encode_json );
use Time::Piece;
use Mojo::SQLite;

my $minimum_report = {
  reporter => {
    email => 'doug@example.com',
  },
  environment => {
    language => {
      name => 'perl',
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

my $tempdir = File::Temp->newdir;
my $t = Test::Mojo->new('CPAN::Testers::Collector', {
  storage => {
    Local => $tempdir->dirname,
  },
  index => {
    SQLite => Mojo::SQLite->new(':temp:'),
  },
});

subtest 'report_post' => sub {
  $t->post_ok('/v1/report', json => $minimum_report)->status_is(201);
  $t->json_like('/0', qr{.{32}}, 'returns the report UUID');
  my $uuid = $t->tx->res->json->[0];
  ok $t->app->storage->read( $uuid ), 'report exists in storage';

  # XXX: should handle validation failures
};

subtest 'report_post with ID' => sub {
  my $uuid = Data::GUID->new;
  $t->post_ok('/v1/report/' . $uuid, json => $minimum_report)->status_is(201);
  $t->json_is('/0', $uuid, 'returns the report UUID');
  ok $t->app->storage->read( $uuid ), 'report exists in storage';
};

subtest 'report_get' => sub {
  my $uuid = Data::GUID->new;
  $t->app->storage->write( $uuid => encode_json( $minimum_report ) );
  $t->get_ok('/v1/report/' . $uuid)->status_is(200)->json_is($minimum_report);

  # XXX: should work for both lc $uuid and uc $uuid
  # XXX: should handle 404s
};

subtest 'report_list' => sub {
  my $uuid = Data::GUID->new;
  my $dt = Time::Piece->new;
  $t->app->index->insert( $uuid => $dt->datetime );

  $t->get_ok('/v1/timestamp/' . $dt->strftime('%Y/%m/%d'))->status_is(200)->json_is([$uuid]);
  $t->get_ok('/v1/timestamp/' . $dt->strftime('%Y/%m/%d/%H'))->status_is(200)->json_is([$uuid]);
  $t->get_ok('/v1/timestamp/' . $dt->strftime('%Y/%m/%d/%H/%M'))->status_is(200)->json_is([$uuid]);

  # XXX: check invalid date/time
  # XXX: check date/time with no reports
  # TODO: paginate with `next` link header
};

done_testing;
