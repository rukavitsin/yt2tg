package Tgph::Content;

use v5.36;
use strict;
use warnings;
use Encode qw(decode FB_CROAK);

sub read {
    my ($fh) = @_;

    binmode $fh;

    my $data = '';

    while (1) {
        my $length = sysread($fh, my $buffer, 65536);

        die "read error: $!\n" unless defined $length;
        last if $length == 0;

        $data .= $buffer;
    }

    my $bytes = length($data);
    my $text  = decode('UTF-8', $data, FB_CROAK);

    return {
        text  => $text,
        bytes => $bytes,
    };
}

1;
