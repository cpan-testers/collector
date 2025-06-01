package CPAN::Testers::Collector::Controller::Report;

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use builtin ':5.40';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Log::Any qw( $LOG );
use Data::GUID;

sub _validate($c) {
  my $result = $c->openapi->validate_request($c->req, {operation_id => $c->stash->{operation_id}});
  if ($result->valid) {
    return true
  }
  $LOG->error( 'validation failed', { errors => [ $result->errors ] } );
  $c->render( status => 400, json => $result->TO_JSON );
  return false;
}

=method report_post

Submit a new CPAN Testers report.

=cut

sub report_post( $c ) {
  return if !$c->_validate;
  my $uuid = Data::GUID->new->as_string;
  $c->storage->write( $uuid, $c->req->body );
  return $c->render(
    status => 201,
    json => [ $uuid ],
  );
}

=method report_get

Get an existing CPAN Testers report.

=cut

sub report_get( $c ) {
  return if !$c->_validate;
  my $report = $c->storage->read( $c->stash('uuid') );
  $c->res->headers->content_type('application/json');
  $c->render( data => $report );
}

=method report_list

List CPAN Testers reports as JSON lines.

=cut

sub report_list( $c ) {
}

1;
