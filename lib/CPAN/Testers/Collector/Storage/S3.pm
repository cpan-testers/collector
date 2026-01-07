package CPAN::Testers::Collector::Storage::S3;
our $VERSION = '0.001';

=head1 SYNOPSIS

    my $driver = CPAN::Testers::Collector::Storage::S3->new(
      endpoint => '...',
      access_key_id => '...',
      secret_access_key => '...',
      bucket => '...',
    );

=head1 DESCRIPTION

This module manages a plain-text database of CPAN Testers reports on a
S3-compatible object storage. This should be used as a driver for L<CPAN::Testers::Collector::Storage>.

=head1 SEE ALSO

L<CPAN::Testers::Collector::Storage>

=cut

use v5.40;
use Mojo::Base -base, -signatures;
use Mojo::File qw( path );
use Time::Piece;
use Scalar::Util qw( blessed );
use Log::Any qw( $LOG );
use AWS::S3;

=attr endpoint

The S3-compatible endpoint.

=cut

has endpoint => sub { die 'endpoint is required' };

=attr access_key_id

The (public) access key. Should be read/write for the bucket.

=cut

has access_key_id => sub { die 'access_key_id is required' };

=attr secret_access_key

The secret key.

=cut

has secret_access_key => sub { die 'secret_access_key is required' };

=attr bucket

The name of the bucket.

=cut

has bucket => sub { die 'bucket is required' };

#=attr _svc
#
# The AWS::S3 instance
has _svc => sub ($self) {
  AWS::S3->new(
    endpoint => $self->endpoint,
    access_key_id => $self->access_key_id,
    secret_access_key => $self->secret_access_key,
  )
};

#=attr _bucket
#
# The AWS::S3::Bucket instance
has _bucket => sub ($self) { $self->_svc->bucket($self->bucket) };

=method write

Write a new report to the storage. The C<$uuid> is required and is
used as the path to write to. C<$content> is a string of content.

=cut

sub write( $self, $uuid, $content ) {
  $LOG->info('Writing to storage', {uuid => $uuid, endpoint => $self->endpoint, bucket => $self->bucket });
  $self->_bucket->file( $uuid )->contents(\$content);
}

=method read

Read a report by UUID. Returns the string content of the report.

=cut

sub read( $self, $uuid ) {
  $self->_bucket->file( $uuid )->contents->$*;
}

1;
