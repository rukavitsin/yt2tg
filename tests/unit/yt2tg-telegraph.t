use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use Encode qw(encode_utf8 decode is_utf8);
my $script = "$Bin/../../bin/yt2tg-telegraph";
sub run_command {
    my (@command) = @_;
    my $output = qx{@command 2>&1};
    my $status = $? >> 8;
    return ($status, $output);
}
{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/Usage: yt2tg-telegraph/, '--help reports usage');
}
{
    my ($status, $output) = run_command("'$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}
{
    my ($status, $output) = run_command("'$script'");
    is($status, 1, 'missing required options exits USAGE');
    like($output, qr/--meta and --section234 are required/,
        'missing options report an error');
}
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $meta = "$tmpdir/meta.json";
    open my $mfh, '>:raw', $meta or die;
    print {$mfh} encode_utf8(
        '{"title":"T","channel":"C","date":"2026-08-08, 17:00","url":"https://youtu.be/x"}');
    close $mfh;
    my $sec = "$tmpdir/section234.md";
    open my $sfh, '>:raw', $sec or die;
    print {$sfh} encode_utf8("### 2. Виклад\nТекст.");
    close $sfh;
    my ($status, $output) = run_command(
        "'$script' --meta '$meta' --section234 '$sec'");
    is($status, 0, 'build exits OK');
    my $text = is_utf8($output) ? $output : decode('UTF-8', $output);
    like($text, qr/title: T/, 'output contains front matter title');
    like($text, qr/## T/, 'output contains h2 title');
    like($text, qr/\*\*C\*\*/, 'output contains bold channel');
    like($text, qr/Виклад/, 'output contains section234 heading');
}
done_testing;
