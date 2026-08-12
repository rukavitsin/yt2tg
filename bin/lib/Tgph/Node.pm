package Tgph::Node;

use v5.36;
use strict;
use warnings;

sub text {
    my ($text) = @_;

    die "text node requires defined text\n"
        unless defined $text;

    return $text;
}

sub raw {
    my ($node) = @_;

    die "node must be a hash reference\n"
        unless ref($node) eq 'HASH';

    return $node;
}

1;
