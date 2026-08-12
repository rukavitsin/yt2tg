use v5.36;
use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use Encode qw(encode_utf8);
use File::Temp qw(tempfile);
use Test::More;

use lib "$Bin/../../bin/lib";

use Tgph::IO;

sub byte_count_file {
    my ($data) = @_;

    my ($fh, $file) = tempfile();

    binmode $fh, ':raw';
    print {$fh} $data;
    close $fh
        or die "cannot close '$file': $!";

    open my $input, '<:raw', $file
        or die "cannot open '$file': $!";

    my $bytes = Tgph::IO::byte_count($input);

    close $input
        or die "cannot close '$file': $!";

    unlink $file;

    return $bytes;
}

is(
    byte_count_file(""),
    0,
    'empty input byte count',
);

is(
    byte_count_file("abc"),
    3,
    'ASCII byte count',
);

is(
    byte_count_file(encode_utf8("Привет")),
    12,
    'UTF-8 byte count',
);

is(
    byte_count_file(encode_utf8("abcПривет\n")),
    16,
    'mixed UTF-8 byte count',
);

done_testing;
