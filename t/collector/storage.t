
=head1 DESCRIPTION

This tests the L<CPAN::Testers::Collector::Storage> module which manages
the storage of raw CPAN Testers reports.

=cut

use Mojo::Base -signatures;
use Test2::V0;
use File::Temp qw( );
use Mojo::File qw( path );
use Data::GUID qw( guid_string );
use CPAN::Testers::Collector::Storage;

subtest 'write report' => sub {
    my $tmp = File::Temp->newdir;
    my $uuid = lc guid_string();
    my $content = 'report';

    my $rd = CPAN::Testers::Collector::Storage->new( Local => $tmp->dirname );
    $rd->write( $uuid, $content );

    my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
    my $got = path($tmp->dirname, $xx, $yy, $uuid);
    ok -e $got, 'report file exists';
    is $got->slurp, $content, 'report content correct';
};

subtest 'read report' => sub {
    my $tmp = File::Temp->newdir;
    my $uuid = lc guid_string();
    my $content = 'report';
    my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
    my $path = path($tmp->dirname, $xx, $yy, $uuid);
    $path->dirname->make_path;
    $path->spew($content);

    my $rd = CPAN::Testers::Collector::Storage->new( Local => $tmp->dirname );
    my $got_content = $rd->read( $uuid );

    is $got_content, $content;
};

subtest 'list' => sub {
  my $tmp = File::Temp->newdir;
  my @uuids = map { lc guid_string() } 0..4;
  my $content = 'report';
  for my $uuid ( @uuids ) {
    my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
    my $path = path($tmp->dirname, $xx, $yy, $uuid);
    $path->dirname->make_path;
    $path->spew($content);
  }

  # Also add related data to a report
  my ( $xx, $yy ) = $uuids[0] =~ m{^(.{2})(.{2})};
  path($tmp->dirname, $xx, $yy, "$uuids[0].orig")->spew('original');

  # Also add completely unrelated data
  path($tmp->dirname, 'MANIFEST')->spew('manifest index');
  path($tmp->dirname, 'MANIFEST.1')->spew('manifest 1');

  my $rd = CPAN::Testers::Collector::Storage->new( Local => $tmp->dirname );

  subtest 'report UUIDs' => sub {
    my $iter = $rd->list;
    my @got_uuids;
    while ( my @uuids = $iter->() ) {
      push @got_uuids, @uuids;
    }
    like \@got_uuids, bag { item $_ for @uuids; end() };
  };

  subtest 'report variants' => sub {
    my $iter = $rd->list($uuids[0]);
    my @got_files;
    while ( my @files = $iter->() ) {
      push @got_files, @files;
    }
    like \@got_files, bag { item $_ for $uuids[0], "$uuids[0].orig"; end() };
  };

  subtest 'manifests' => sub {
    my $iter = $rd->list('MANIFEST');
    my @got_files;
    while ( my @files = $iter->() ) {
      push @got_files, @files;
    }
    like \@got_files, bag { item $_ for 'MANIFEST', 'MANIFEST.1'; end() };
  };
};

subtest 'multi-storage' => sub {
  subtest 'write to all storages' => sub {
      my $tmp_first = File::Temp->newdir;
      my $tmp_second = File::Temp->newdir;
      my $uuid = lc guid_string();
      my $content = 'report';

      my $rd = CPAN::Testers::Collector::Storage->new(
        Local => $tmp_first->dirname,
        Local => $tmp_second->dirname,
      );
      $rd->write( $uuid, $content );

      my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
      my $got = path($tmp_first->dirname, $xx, $yy, $uuid);
      ok -e $got, 'report file exists in first storage';
      is $got->slurp, $content, 'report content correct in first storage';
      $got = path($tmp_second->dirname, $xx, $yy, $uuid);
      ok -e $got, 'report file exists in second storage';
      is $got->slurp, $content, 'report content correct in second storage';
  };

  subtest 'read from first storage' => sub {
      my $tmp_first = File::Temp->newdir;
      my $tmp_second = File::Temp->newdir;
      my $uuid = lc guid_string();
      my $content = 'report';
      my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
      my $path = path($tmp_first->dirname, $xx, $yy, $uuid);
      $path->dirname->make_path;
      $path->spew($content);

      my $rd = CPAN::Testers::Collector::Storage->new(
        Local => $tmp_first->dirname,
        Local => $tmp_second->dirname,
      );
      my $got_content = $rd->read( $uuid );

      is $got_content, $content;
  };

  subtest 'read from second storage' => sub {
      my $tmp_first = File::Temp->newdir;
      my $tmp_second = File::Temp->newdir;
      my $uuid = lc guid_string();
      my $content = 'report';
      my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
      my $path = path($tmp_second->dirname, $xx, $yy, $uuid);
      $path->dirname->make_path;
      $path->spew($content);

      my $rd = CPAN::Testers::Collector::Storage->new(
        Local => $tmp_first->dirname,
        Local => $tmp_second->dirname,
      );
      my $got_content = $rd->read( $uuid );

      is $got_content, $content;
  };
};

done_testing;
