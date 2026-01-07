
=head1 DESCRIPTION

This tests the L<CPAN::Testers::Collector::Storage::S3> module which manages
the storage of raw CPAN Testers reports to an S3-compatible object store.

=cut

use Mojo::Base -signatures;
use Test2::V0;
use File::Temp qw( );
use Mojo::File qw( path );
use Data::GUID qw( guid_string );
use CPAN::Testers::Collector::Storage;
use CPAN::Testers::Collector::Storage::S3;

my %create_args = (
  endpoint => 'localhost',
  region => 'us-sea-1',
  access_key_id => 'fake',
  secret_access_key => 'fake also',
  bucket => 'reports-v3',
);

subtest 'write report' => sub {
  my ($got_bucket, $got_key, $got_content);
  my $mock = mock 'AWS::S3' => override => [
    new => sub ($class, %attrs) {
      return mock { attrs => \%attrs } => add => [
        bucket => sub ($aws, $name) {
          $got_bucket = $name;
          return mock { name => $name } => add => [
            add_file => sub ($bucket, %args) {
              $got_key = $args{key};
              $got_content = $args{contents}->$*;
            },
          ];
        },
      ];
    },
  ];

  my $uuid = lc guid_string();
  my $content = 'report';

  my $rd = CPAN::Testers::Collector::Storage->new( S3 => %create_args );
  $rd->write( $uuid, $content );

  is $got_bucket, $create_args{bucket};
  is $got_key, $uuid;
  is $got_content, $content;
};

subtest 'read report' => sub {
  my $uuid = lc guid_string();
  my $content = 'report';

  my ( $got_bucket, $got_key );
  my $mock = mock 'AWS::S3' => override => [
    new => sub ($class, %attrs) {
      return mock { attrs => \%attrs } => add => [
        bucket => sub ($aws, $name) {
          $got_bucket = $name;
          return mock { name => $name } => add => [
            file => sub ($bucket, $key) {
              $got_key = $key;
              return mock { bucket => $bucket, key => $key }, add => [
                contents => sub ($self) {
                  return \$content;
                }
              ];
            }
          ];
        },
      ];
    },
  ];

  my $rd = CPAN::Testers::Collector::Storage->new( S3 => %create_args );
  my $got_content = $rd->read( $uuid );

  is $got_bucket, $create_args{bucket};
  is $got_key, $uuid;
  is $got_content, $content;
};

done_testing;
