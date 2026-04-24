
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

  my $rd = CPAN::Testers::Collector::Storage->new( S3 => \%create_args );
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
              if ($key eq $uuid) {
                return mock { bucket => $bucket, key => $key }, add => [
                  contents => sub ($self) {
                    return \$content;
                  }
                ];
              }
              return undef;
            }
          ];
        },
      ];
    },
  ];

  my $rd = CPAN::Testers::Collector::Storage->new( S3 => \%create_args );
  my $got_content = $rd->read( $uuid );

  is $got_bucket, $create_args{bucket};
  is $got_key, $uuid;
  is $got_content, $content;

  subtest '404 not found' => sub {
    my $wrong_uuid = lc guid_string();
    my $got = $rd->read( $wrong_uuid );
    is $got, undef, 'returns undef on missing reports';
  };
};

subtest 'list()' => sub {
  my ( $given_files, $got_bucket, $got_args );
  my $mock = mock 'AWS::S3' => override => [
    new => sub ($class, %attrs) {
      return mock { attrs => \%attrs } => add => [
        bucket => sub ($aws, $name) {
          $got_bucket = $name;
          return mock { } => add => [
            files => sub ($self, %args) {
              $got_args = \%args;
              return mock { }, add => [
                next_page => sub($self) {
                  state $fetched = 0;
                  if (!$fetched) {
                    $fetched = 1;
                    return map {
                      mock { bucket => $name, key => $_ }, add => [
                        key => sub { shift->{key} },
                      ]
                    } @$given_files;
                  }
                  return ();
                },
              ];
            }
          ];
        },
      ];
    },
  ];

  my $rd = CPAN::Testers::Collector::Storage->new( S3 => \%create_args );

  subtest 'report UUIDs' => sub {
    $given_files = [ map { lc guid_string() } 0..4 ];
    my $iter = $rd->list;
    my @got_uuids;
    while ( my @uuids = $iter->() ) {
      push @got_uuids, @uuids;
    }
    like \@got_uuids, bag { item $_ for @$given_files; end() };
    like $got_args, { prefix => DNE() };
  };

  subtest 'report variants' => sub {
    my $uuid = lc guid_string();
    $given_files = [ $uuid, "$uuid.orig" ];
    my $iter = $rd->list($uuid);
    my @got_files;
    while ( my @files = $iter->() ) {
      push @got_files, @files;
    }
    like \@got_files, bag { item $_ for $uuid, "$uuid.orig"; end() };
    like $got_args, { prefix => $uuid };
  };

  subtest 'manifests' => sub {
    $given_files = [ qw( MANIFEST MANIFEST.1 ) ];
    my $iter = $rd->list('MANIFEST');
    my @got_files;
    while ( my @files = $iter->() ) {
      push @got_files, @files;
    }
    like \@got_files, bag { item $_ for 'MANIFEST', 'MANIFEST.1'; end() };
    like $got_args, { prefix => 'MANIFEST' };
  };
};
done_testing;
