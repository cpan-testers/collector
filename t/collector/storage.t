
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

subtest 'write' => sub {
    my $tmp = File::Temp->newdir;
    my $rd = CPAN::Testers::Collector::Storage->new( Local => $tmp->dirname );
    my $uuid = lc guid_string();

    subtest 'write report' => sub {
        my $content = 'report';
        $rd->write( $uuid, $content );

        my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
        my $got = path($tmp->dirname, $xx, $yy, $uuid);
        ok -e $got, 'report file exists';
        is $got->slurp, $content, 'report content correct';
    };

    subtest 'write report variant' => sub {
        my $variant_name = "$uuid.variant";
        my $content = 'variant';
        $rd->write( $variant_name, $content );

        my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
        my $got = path($tmp->dirname, $xx, $yy, $variant_name);
        ok -e $got, 'report variant file exists';
        is $got->slurp, $content, 'report variant content correct';
    };

    subtest 'write unrelated file' => sub {
        my $content = 'manifest';
        my $manifest_name = 'MANIFEST';

        $rd->write( $manifest_name, $content );

        my $got = path($tmp->dirname, $manifest_name);
        ok -e $got, 'unrelated file exists';
        is $got->slurp, $content, 'unrelated content correct';
    };
};

subtest 'read' => sub {
    my $tmp = File::Temp->newdir;
    my $uuid = lc guid_string();
    my $content = 'report';
    my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
    my $path = path($tmp->dirname, $xx, $yy, $uuid);
    $path->dirname->make_path;
    $path->spew($content);

    my $variant_content = 'variant';
    my $variant_name = "$uuid.variant";
    path($tmp->dirname, $xx, $yy, $variant_name)->spew($variant_content);

    my $manifest_content = 'manifest';
    my $manifest_name = 'MANIFEST';
    path($tmp->dirname, $manifest_name)->spew($manifest_content);

    my $rd = CPAN::Testers::Collector::Storage->new( Local => $tmp->dirname );

    subtest 'read report' => sub {
      my $got_content = $rd->read( $uuid );
      is $got_content, $content;
    };

    subtest 'read report variant' => sub {
      my $got_content = $rd->read( $variant_name );
      is $got_content, $variant_content;
    };

    subtest 'read unrelated file' => sub {
      my $got_content = $rd->read( $manifest_name );
      is $got_content, $manifest_content;
    };
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
