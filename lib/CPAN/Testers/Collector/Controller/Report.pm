package CPAN::Testers::Collector::Controller::Report;

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use builtin ':5.40';
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Log::Any qw( $LOG );
use Data::GUID;

sub _validate($c) {
  $LOG->debug('validating', { url => $c->req->url, operation_id => $c->stash->{operation_id} });
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
  my $uuid = $c->param('uuid') || Data::GUID->new->as_string;
  my $body = $c->req->body;
  if (length $body <= 0) {
    $c->log->error(sprintf 'Report %s has no content', $c->param('uuid') // 'submitted');
    return $c->render(
      status => 400,
      json => { error => 'No content' },
    );
  }
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

List CPAN Testers report UUIDs as a JSON array.

=cut

sub report_list( $c ) {
  return if !$c->_validate;
  my ($year, $mon, $day, $hour, $min) = $c->stash->@{qw(year month day hour minute)};

  my $format = "%04d-%02d-%02dT%02d:%02d:%02d%s";
  my $from = sprintf $format, $year, $mon, $day, $hour // 0, $min // 0, 0, '+0000';
  my $to = sprintf $format, $year, $mon, $day, $hour // 23, $min // 59, 59, '+0000';

  my @uuids = $c->index->select( from => $from, to => $to )->each;
  $c->render( json => \@uuids );
}

1;
