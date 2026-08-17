use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use Encode qw(encode_utf8);
my $script = "$Bin/../../bin/yt2tg-subs";
sub run_command {
    my (@command) = @_;
    my $output = qx{@command 2>&1};
    my $status = $? >> 8;
    return ($status, $output);
}
{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/Usage: yt2tg-subs/, '--help reports usage');
    like($output, qr/--lang/, '--help mentions --lang option');
}
{
    my ($status, $output) = run_command("'$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}
{
    my ($status, $output) = run_command("'$script'");
    is($status, 1, 'missing URL exits USAGE');
}
{
    my ($status, $output) = run_command("'$script' --lang en https://youtu.be/invalid");
    ok($status != 0, 'invalid URL with --lang does not succeed');
    like($output, qr/yt2tg-subs:/, 'diagnostic output present');
}
done_testing;
