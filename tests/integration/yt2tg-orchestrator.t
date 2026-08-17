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
    like($output, qr/--force/, '--help mentions --force');
    like($output, qr/YOUTUBE_URL_OR_ID/, '--help mentions ID input');
}

{
    my ($status, $output) = run_command("sh '$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

{
    my ($status, $output) = run_command("sh '$script'");
    is($status, 1, 'missing input exits USAGE');
    like($output, qr/is required/, 'reports missing input');
}

{
    my ($status, $output) = run_command("sh '$script' --unknown");
    is($status, 1, 'unknown option exits USAGE');
    like($output, qr/unknown option/, 'reports unknown option');
}

{
    my ($status, $output) = run_command("sh '$script' https://example.com/video");
    is($status, 1, 'invalid URL exits USAGE');
    like($output, qr/invalid YouTube/, 'reports invalid URL');
}

{
    # Valid 11-char ID should pass input validation (fail on prompt missing)
    # Use --force to bypass journal check
    my $tmpdir = tempdir(CLEANUP => 1);
    my ($status, $output) = run_command(
        "cd '$tmpdir' && sh '$script' --force dQw4w9WgXcQ");
    ok($status != 0, 'valid ID does not exit USAGE');
    unlike($output, qr/invalid YouTube/, 'valid ID not rejected');
}

{
    # Too-short ID should be rejected
    my ($status, $output) = run_command("sh '$script' short");
    is($status, 1, 'short input exits USAGE');
    like($output, qr/invalid YouTube/, 'short input rejected');
}

{
    # Valid 11-char ID in URL, missing prompt.md
    my $tmpdir = tempdir(CLEANUP => 1);
    my ($status, $output) = run_command(
        "cd '$tmpdir' && sh '$script' https://youtu.be/dQw4w9WgXcQ");
    is($status, 2, 'missing prompt.md exits INPUT');
    like($output, qr/prompt file .* is empty or missing/, 'reports missing prompt');
}

done_testing;
