use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
my $script = "$Bin/../../bin/yt2tg-meta";
sub run_command {
    my (@command) = @_;
    my $output = qx{@command 2>&1};
    my $status = $? >> 8;
    return ($status, $output);
}
{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/Usage: yt2tg-meta/, '--help reports usage');
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
done_testing;

# Integration test: verify yt2tg-meta does NOT include non-language keys
# (This is tested via the structure check in the metadata JSON)
# The actual extraction is tested via real yt-dlp output in integration tests.
