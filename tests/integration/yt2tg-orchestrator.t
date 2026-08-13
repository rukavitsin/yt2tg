use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use Encode qw(encode_utf8);

my $script = "$Bin/../../bin/yt2tg";

sub run_command {
    my (@command) = @_;
    my $output = qx{@command 2>&1};
    my $status = $? >> 8;
    return ($status, $output);
}

{
    my ($status, $output) = run_command("sh '$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/Usage: yt2tg/, '--help shows usage');
    like($output, qr/YOUTUBE_URL/, 'usage mentions YOUTUBE_URL');
}

{
    my ($status, $output) = run_command("sh '$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

{
    my ($status, $output) = run_command("sh '$script'");
    is($status, 1, 'missing URL exits USAGE');
    like($output, qr/YOUTUBE_URL is required/, 'reports missing URL');
}

{
    my ($status, $output) = run_command("sh '$script' --unknown");
    is($status, 1, 'unknown option exits USAGE');
    like($output, qr/unknown option/, 'reports unknown option');
}

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my ($status, $output) = run_command(
        "cd '$tmpdir' && sh '$script' https://youtu.be/test");
    is($status, 2, 'missing prompt.md exits INPUT');
    like($output, qr/cannot open prompt file/, 'reports missing prompt');
}

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $prompt = "$tmpdir/prompt.md";
    open my $fh, '>:raw', $prompt or die;
    print {$fh} encode_utf8("Test prompt\n");
    close $fh;
    my ($status, $output) = run_command(
        "cd '$tmpdir' && sh '$script' --prompt '$prompt' " .
        "https://youtu.be/test");
    ok($status != 0, 'nonexistent URL does not succeed');
}

done_testing;
