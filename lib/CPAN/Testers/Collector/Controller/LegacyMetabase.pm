package CPAN::Testers::Collector::Controller::LegacyMetabase;

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Controller', -signatures;

=method user_post

Submit a new user resource, to be referenced by future reports.

=cut

sub user_post( $c ) {
}

=method report_post

Submit a new CPAN Testers report in the Metabase format.

=cut

sub report_post( $c ) {
}

1;
