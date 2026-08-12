use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use Encode qw(encode_utf8);
use JSON::PP ();

my $has_cmark = system('command -v cmark >/dev/null 2>&1') == 0;

if (!$has_cmark) {
    plan skip_all => 'cmark is not available';
}

my $script = "$Bin/../../bin/tgph-md2content";

sub run_command {
    my (@command) = @_;
    my $output = qx{@command 2>&1};
    my $status = $? >> 8;
    return ($status, $output);
}

my $tmpdir = tempdir(CLEANUP => 1);

{
    my $md = "---\ntitle: Test Title\n---\n\n# Test Title\n\nIntro text.\n\n## Section\n\nMore text.\n";
    my $md_file = "$tmpdir/article.md";
    open my $fh, '>:raw', $md_file or die;
    print {$fh} encode_utf8($md);
    close $fh;

    my $title_file = "$tmpdir/title.txt";

    my ($status, $output) =
        run_command("'$script' --title-out '$title_file' '$md_file'");

    is($status, 0, 'md2content exits OK');

    open my $tfh, '<:raw', $title_file or die;
    my $title = do { local $/; <$tfh> };
    close $tfh;
    is($title, encode_utf8('Test Title'), 'front matter title written');

    my $content = JSON::PP::decode_json($output);

    is(ref($content), 'ARRAY', 'output is content array');
    isnt(
        ref($content->[0]) eq 'HASH' ? $content->[0]{tag} : '',
        'h1',
        'leading h1 removed when fm title present',
    );

    my @tags = map { ref($_) ? $_->{tag} : 'TEXT' } @$content;
    is_deeply(
        \@tags,
        ['p', 'h2', 'p'],
        'content structure matches cmark output without h1',
    );
}

{
    my $md = "# Only Heading\n\nBody.\n";
    my $md_file = "$tmpdir/no_fm.md";
    open my $fh, '>:raw', $md_file or die;
    print {$fh} encode_utf8($md);
    close $fh;

    my $title_file = "$tmpdir/no_fm_title.txt";

    my ($status, $output) =
        run_command("'$script' --title-out '$title_file' '$md_file'");

    is($status, 0, 'md without front matter exits OK');
    ok(!-e $title_file, 'title file not created without front matter');

    my $content = JSON::PP::decode_json($output);
    my @tags = map { ref($_) ? $_->{tag} : 'TEXT' } @$content;
    is_deeply(\@tags, ['h1', 'p'], 'h1 preserved when no fm title');
}

{
    my $md_file = "$tmpdir/bad_utf8.md";
    open my $fh, '>:raw', $md_file or die;
    print {$fh} "\xFF\xFE bad";
    close $fh;

    my ($status, $output) = run_command("'$script' '$md_file'");

    is($status, 2, 'invalid UTF-8 exits INPUT');
    like($output, qr/not valid UTF-8/, 'invalid UTF-8 reports an error');
}

{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/^Usage: tgph-md2content/m, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

done_testing;
