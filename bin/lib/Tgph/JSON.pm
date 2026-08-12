package Tgph::JSON;
use v5.36;
use strict;
use warnings;
use JSON::PP ();

my $JSON = JSON::PP->new
    ->canonical
    ->utf8
    ->allow_nonref;

sub encode {
    my ($nodes) = @_;
    die "nodes must be an array reference\n"
        unless ref($nodes) eq 'ARRAY';
    return $JSON->encode($nodes);
}

sub bytes {
    my ($nodes) = @_;
    return length(encode($nodes));
}

sub decode_bytes {
    my ($bytes) = @_;
    die "JSON input must be defined\n" unless defined $bytes;

    my $data;
    local $@;
    my $ok = eval {
        $data = $JSON->decode($bytes);
        1;
    };
    die "invalid JSON\n" unless $ok;

    return $data;
}

1;
