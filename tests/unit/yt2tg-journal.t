use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);

my $script = "$Bin/../../bin/yt2tg-journal";

sub run_command {
    my (@command) = @_;
    my $output = qx{@command 2>&1};
    my $status = $? >> 8;
    return ($status, $output);
}

{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/Usage: yt2tg-journal/, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

{
    my ($status, $output) = run_command("'$script'");
    is($status, 1, 'missing action exits USAGE');
    like($output, qr/unknown or missing action/, 'reports missing action');
}

{
    my ($status, $output) = run_command("'$script' check");
    is($status, 1, 'check without video-id exits USAGE');
    like($output, qr/requires --video-id/, 'reports missing video-id');
}

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $journal = "$tmpdir/log.jsonl";

    my ($status, $output) = run_command("'$script' check --journal '$journal' --video-id test123");
    is($status, 1, 'check exits 1 when journal missing');

    my $rec = '{"video_id":"abc","status":"success","telegraph_url":"http://tg/1"}';
    ($status, $output) = run_command("'$script' append --journal '$journal' --record '$rec'");
    is($status, 0, 'append exits OK');

    ($status, $output) = run_command("'$script' check --journal '$journal' --video-id abc");
    is($status, 0, 'check exits 0 when found');
    is($output, "http://tg/1\n", 'check prints URL');

    ($status, $output) = run_command("'$script' check --journal '$journal' --video-id xyz");
    is($status, 1, 'check exits 1 when not found');
}

{
    my ($status, $output) = run_command("'$script' append --record 'not-json'");
    is($status, 2, 'append with invalid JSON exits INPUT');
    like($output, qr/invalid JSON record/, 'reports invalid JSON');
}

done_testing;
