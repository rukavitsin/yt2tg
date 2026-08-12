use v5.36;
use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use Encode qw(encode_utf8);
use File::Temp qw(tempfile);
use Test::More;

use lib "$Bin/../../bin/lib";

use Tgph::Content;

sub read_content {
    my ($data) = @_;

    my ($fh, $file) = tempfile();

    binmode $fh, ':raw';
    print {$fh} $data;
    close $fh
        or die "cannot close '$file': $!";

    open my $input, '<:raw', $file
        or die "cannot open '$file': $!";

    my $content = Tgph::Content::read($input);

    close $input
        or die "cannot close '$file': $!";

    unlink $file;

    return $content;
}

{
    my $content = read_content('');

    is($content->{text}, '', 'empty content text');
    is($content->{bytes}, 0, 'empty content bytes');
}

{
    my $content = read_content('abc');

    is($content->{text}, 'abc', 'ASCII content text');
    is($content->{bytes}, 3, 'ASCII content bytes');
}

{
    my $content = read_content(encode_utf8('Привет'));

    is($content->{text}, 'Привет', 'UTF-8 content text');
    is($content->{bytes}, 12, 'UTF-8 content bytes');
}

{
    my $content = read_content(encode_utf8("abcПривет\n"));

    is($content->{text}, "abcПривет\n", 'mixed content text');
    is($content->{bytes}, 16, 'mixed content bytes');
}
{
    my ($fh, $file) = tempfile();

    binmode $fh, ":raw";
    print {$fh} "\xFF";
    close $fh
        or die "cannot close '$file': $!";

    open my $input, "<:raw", $file
        or die "cannot open '$file': $!";

    my $error;

    {
        local $@;

        eval {
            Tgph::Content::read($input);
            1;
        } or $error = $@;
    }

    close $input
        or die "cannot close '$file': $!";

    unlink $file;

    ok(
        defined($error) && length($error),
        "invalid UTF-8 is rejected",
    );
}
done_testing;
