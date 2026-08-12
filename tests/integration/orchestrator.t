use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use Encode qw(encode_utf8);
use JSON::PP ();

my $script = "$Bin/../../bin/pubtgph";

sub run {
    my ($cmd) = @_;
    my $output = `$cmd 2>&1`;
    my $status = $? >> 8;
    return ($status, $output);
}

my $tmpdir = tempdir(CLEANUP => 1);
my $home = "$tmpdir/home";
mkdir $home;

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} encode_utf8($text);
    close $fh;
}

# Test 1: --help
{
    my ($status, $output) = run("HOME='$home' sh '$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/Usage: pubtgph/, '--help shows usage');
    like($output, qr/ARTICLE_MD/, 'usage mentions markdown input');
}

# Test 2: missing input
{
    my ($status, $output) = run("HOME='$home' sh '$script'");
    is($status, 1, 'missing input exits USAGE');
    like($output, qr/ARTICLE_MD file is required/, 'reports missing input');
}

# Test 3: nonexistent input
{
    my ($status, $output) =
        run("HOME='$home' sh '$script' /nonexistent/file.md");
    is($status, 2, 'nonexistent file exits INPUT');
    like($output, qr/cannot open/, 'reports open error');
}

# Test 4: front matter title wins
{
    my $md = "$tmpdir/fm.md";
    write_file($md, "---\ntitle: FM Title\n---\n\n# FM Title\n\nText here.\n");

    my ($status, $output) =
        run("HOME='$home' sh '$script' --dry-run --title 'CLI Title' '$md'");
    is($status, 0, 'fm title dry-run exits OK');

    my $data = JSON::PP::decode_json($output);
    is($data->[0]{fields}{title}, 'FM Title', 'front matter title wins over CLI');
    ok(!exists $data->[0]{fields}{access_token}, 'no token without config');
}

# Test 5: h1 title when no front matter
{
    my $md = "$tmpdir/h1.md";
    write_file($md, "# Head One\n\nText here.\n");

    my ($status, $output) =
        run("HOME='$home' sh '$script' --dry-run '$md'");
    is($status, 0, 'h1 title dry-run exits OK');

    my $data = JSON::PP::decode_json($output);
    is($data->[0]{fields}{title}, 'Head One', 'h1 used when no front matter');
}

# Test 6: CLI title when no fm and no h1
{
    my $md = "$tmpdir/plain.md";
    write_file($md, "Just text, no headings.\n");

    my ($status, $output) =
        run("HOME='$home' sh '$script' --dry-run --title 'CLI Title' '$md'");
    is($status, 0, 'CLI title dry-run exits OK');

    my $data = JSON::PP::decode_json($output);
    is($data->[0]{fields}{title}, 'CLI Title', 'CLI title used when no fm/h1');
}

# Test 7: file name as last resort
{
    my $md = "$tmpdir/sample-name.md";
    write_file($md, "Just text, no headings.\n");

    my ($status, $output) =
        run("HOME='$home' sh '$script' --dry-run '$md'");
    is($status, 0, 'filename title dry-run exits OK');

    my $data = JSON::PP::decode_json($output);
    is($data->[0]{fields}{title}, 'sample-name',
        'file name used as last resort');
}

# Test 8: ~/.tgrc provides token
{
    write_file("$home/.tgrc", "TP_TOKEN=\"sekret\"\nTP_URL=\"https://api.telegra.ph\"\n");

    my $md = "$tmpdir/tok.md";
    write_file($md, "# T\n\nBody.\n");

    my ($status, $output) =
        run("HOME='$home' sh '$script' --dry-run '$md'");
    is($status, 0, 'config token dry-run exits OK');

    my $data = JSON::PP::decode_json($output);
    is($data->[0]{fields}{access_token}, '***',
        'token from ~/.tgrc is passed and masked');

    unlink "$home/.tgrc";
}

done_testing;
