
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
    my $timestamp = '2025-01-01T00:01:00';

    my $rd = CPAN::Testers::Collector::Storage->new( root => $tmp->dirname );
    $rd->write( $uuid, $content, timestamp => $timestamp );

    my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
    my $got = path($tmp->dirname, 'report', $xx, $yy, $uuid);
    ok -e $got, 'report file exists';
    is $got->slurp, $content, 'report content correct';
};

subtest 'read report' => sub {
    my $tmp = File::Temp->newdir;
    my $uuid = lc guid_string();
    my $content = 'report';
    my $timestamp = '2025-01-01T00:01:00';
    my ( $xx, $yy ) = $uuid =~ m{^(.{2})(.{2})};
    my $path = path($tmp->dirname, 'report', $xx, $yy, $uuid);
    $path->dirname->make_path;
    $path->spew($content);

    my $rd = CPAN::Testers::Collector::Storage->new( root => $tmp->dirname );
    my $got_content = $rd->read( $uuid );

    is $got_content, $content;
};

done_testing;
