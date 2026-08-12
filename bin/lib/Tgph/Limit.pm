package Tgph::Limit;

use v5.36;
use strict;
use warnings;

sub fits {
    my ($bytes, $limit) = @_;

    die "byte count must be a non-negative integer\n"
        unless defined($bytes)
            && $bytes =~ /\A\d+\z/;

    die "limit must be a positive integer\n"
        unless defined($limit)
            && $limit =~ /\A[1-9]\d*\z/;

    return $bytes <= $limit;
}

1;
