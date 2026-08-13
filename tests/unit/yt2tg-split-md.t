use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use Encode qw(encode_utf8);
my $script = "$Bin/../../bin/yt2tg-split-md";
sub run_command {
    my (@command) = @_;
    my $output = qx{@command 2>&1};
    my $status = $? >> 8;
    return ($status, $output);
}
{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/Usage: yt2tg-split-md/, '--help reports usage');
}
{
    my ($status, $output) = run_command("'$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}
{
    my ($status, $output) = run_command("'$script'");
    is($status, 1, 'missing --out-dir exits USAGE');
    like($output, qr/--out-dir is required/, 'missing out-dir reports error');
}
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $input = "$tmpdir/input.md";
    open my $fh, '>:raw', $input or die;
    print {$fh} encode_utf8("### 1. Sec1\nContent1\n### 2. Sec2\nContent2\n");
    close $fh;
    my $outdir = "$tmpdir/out";
    my ($status, $output) = run_command("'$script' --out-dir '$outdir' '$input'");
    is($status, 0, 'split exits OK');
    ok(-f "$outdir/section1.md", 'section1.md created');
    ok(-f "$outdir/section234.md", 'section234.md created');
    open my $f1, '<:raw', "$outdir/section1.md" or die;
    my $s1 = do { local $/; <$f1> };
    close $f1;
    like($s1, qr/Sec1/, 'section1 contains expected content');
    open my $f2, '<:raw', "$outdir/section234.md" or die;
    my $s2 = do { local $/; <$f2> };
    close $f2;
    like($s2, qr/Sec2/, 'section234 contains expected content');
}
done_testing;
