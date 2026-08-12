package Tgph::Pretty;
use v5.36;
use strict;
use warnings;
use JSON::PP ();

my $PRETTY_JSON = JSON::PP->new
    ->pretty
    ->canonical
    ->utf8;

my $COMPACT_JSON = JSON::PP->new
    ->canonical
    ->utf8;

sub pretty {
    my ($data) = @_;
    return $PRETTY_JSON->encode($data);
}

sub compact {
    my ($data) = @_;
    return $COMPACT_JSON->encode($data);
}

1;
