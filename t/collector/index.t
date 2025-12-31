
=head1 DESCRIPTION

This tests the L<CPAN::Testers::Collector::Index> module which manages
an index (based on timestamp) of the CPAN Testers reports.

=cut

use Mojo::Base -signatures;
use Test2::V0;
use Data::GUID qw( guid_string );
use CPAN::Testers::Collector::Index;
use Mojo::SQLite;

subtest 'list reports by timestamp' => sub {
    my $idx = CPAN::Testers::Collector::Index->new(
      SQLite => Mojo::SQLite->new(),
    );
    my $day = '2025-01-01';

    my @uuids = ();
    for my $i (0..20) {
        my $uuid = lc guid_string();
        push @uuids, $uuid;
        my $timestamp = sprintf '%sT%02d:01:00', $day, $i;
        $idx->insert( $uuid, $timestamp );
    }

    subtest 'get all' => sub {
        my @got_uuids = $idx->select( from => "${day}T00:00:00", to => "${day}T23:59:59" )->each;
        is \@got_uuids, \@uuids;
    };

    subtest 'get some hours' => sub {
        my @got_uuids = $idx->select( from => "${day}T05:00:00", to => "${day}T08:59:59" )->each;
        is \@got_uuids, [@uuids[5..8]];
    };
};

done_testing;
