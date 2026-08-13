use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use Encode qw(encode_utf8 decode is_utf8);
my $script = "$Bin/../../bin/yt2tg-tg";
sub run_command {
    my (@command) = @_;
    my $output = qx{@command 2>&1};
    my $status = $? >> 8;
    return ($status, $output);
}
{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/Usage: yt2tg-tg/, '--help reports usage');
}
{
    my ($status, $output) = run_command("'$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}
{
    my ($status, $output) = run_command("'$script'");
    is($status, 1, 'missing required options exits USAGE');
    like($output, qr/--meta, --section1 and --telegraph-url are required/,
        'missing options report an error');
}
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $meta = "$tmpdir/meta.json";
    open my $mfh, '>:raw', $meta or die;
    print {$mfh} encode_utf8(
        '{"title":"T","channel":"C","date":"2026-08-08, 17:00","url":"https://youtu.be/x"}');
    close $mfh;
    my $sec1 = "$tmpdir/section1.md";
    open my $sfh, '>:raw', $sec1 or die;
    print {$sfh} encode_utf8("### 1. Зміст\nПідсумок.");
    close $sfh;
    my ($status, $output) = run_command(
        "'$script' --dry-run --meta '$meta' --section1 '$sec1' --telegraph-url 'https://telegra.ph/p'");
    is($status, 0, 'dry-run exits OK');
    my $text = is_utf8($output) ? $output : decode('UTF-8', $output);
    like($text, qr/<b>T<\/b>/, 'dry-run contains bold title');
    like($text, qr/Джерело:/, 'dry-run contains source label');
    like($text, qr{https://youtu\.be/x}, 'dry-run contains source url');
    like($text, qr/Підсумок/, 'dry-run contains section1 body');
    unlike($text, qr/### 1\./, 'dry-run strips heading');
    like($text, qr{https://telegra\.ph/p}, 'dry-run contains telegraph url');
}
done_testing;
