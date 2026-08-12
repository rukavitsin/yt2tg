package Tgph::IO;
use v5.36;
use strict;
use warnings;

sub byte_count {
    my ($fh) = @_;
    binmode $fh;
    my $bytes = 0;
    while (1) {
        my $length = sysread($fh, my $buffer, 65536);
        die "read error: $!\n" unless defined $length;
        last if $length == 0;
        $bytes += $length;
    }
    return $bytes;
}

sub read_bytes {
    my ($fh) = @_;
    binmode $fh;
    my $data = '';
    while (1) {
        my $length = sysread($fh, my $buffer, 65536);
        die "read error: $!\n" unless defined $length;
        last if $length == 0;
        $data .= $buffer;
    }
    return $data;
}

1;
