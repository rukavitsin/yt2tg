use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
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
        '{"title":"T","channel":"C","date":"2026-08-08, 17:00","url":"http://youtu.be/x"}');
    close $mfh;
    my $sec = "$tmpdir/section1.md";
    open my $sfh, '>:raw', $sec or die;
    print {$sfh} encode_utf8("### 1. Зміст\nТекст.");
    close $sfh;
    my ($status, $output) = run_command(
        "'$script' --dry-run --meta '$meta' --section1 '$sec' --telegraph-url https://telegra.ph/xyz");
    is($status, 0, 'dry-run exits OK');
    my $text = is_utf8($output) ? $output : decode('UTF-8', $output);
    like($text, qr/<b>T<\/b>/, 'output contains bold title');
    like($text, qr/Текст\./, 'output contains section body');
    unlike($text, qr/### 1\./, 'section heading stripped');
    like($text, qr/telegra\.ph\/xyz/, 'output contains telegraph URL');
}
{
    # Test UTF-8 handling of telegraph URL with Ukrainian characters
    my $tmpdir = tempdir(CLEANUP => 1);
    my $meta = "$tmpdir/meta.json";
    open my $mfh, '>:raw', $meta or die;
    print {$mfh} encode_utf8(
        '{"title":"Тест","channel":"Канал","date":"2026-08-17, 12:00","url":"http://youtu.be/abcdefghijk"}');
    close $mfh;
    my $sec = "$tmpdir/section1.md";
    open my $sfh, '>:raw', $sec or die;
    print {$sfh} encode_utf8("### 1. Зміст\nТекст розділу.");
    close $sfh;

    # URL with Ukrainian І (U+0406) encoded as UTF-8 bytes
    my $url_with_ukrainian = "https://telegra.ph/KILIMOV\xD0\x86-BOMBARDUVANNYA";
    my ($status, $output) = run_command(
        "'$script' --dry-run --meta '$meta' --section1 '$sec' --telegraph-url '$url_with_ukrainian'");
    is($status, 0, 'dry-run with UTF-8 URL exits OK');

    my $text = is_utf8($output) ? $output : decode('UTF-8', $output);
    like($text, qr/KILIMOV\x{0406}/, 'Ukrainian І preserved in URL (not corrupted)');
    unlike($text, qr/KILIMOV\x{00D0}/, 'URL not double-encoded (no Ð character)');
    like($text, qr/telegra\.ph/, 'URL present in output');
}
done_testing;
