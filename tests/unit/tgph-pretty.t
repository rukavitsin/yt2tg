use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;

my $script = "$Bin/../../bin/tgph-pretty";

sub run_stdin {
    my ($input, @args) = @_;

    my $command = sprintf(
        'printf %%s %s | %s %s 2>&1',
        quotemeta($input),
        quotemeta($script),
        join(' ', map { quotemeta($_) } @args),
    );

    my $output = `$command`;
    my $status = $? >> 8;

    return ($status, $output);
}

sub run_command {
    my (@command) = @_;

    my $output = qx{@command 2>&1};
    my $status = $? >> 8;

    return ($status, $output);
}

{
    my ($status, $output) = run_stdin('[]');
    is($status, 0, 'empty array exits OK');
    like($output, qr/\[/, 'output contains array bracket');
}

{
    my ($status, $output) =
        run_stdin('[{"tag":"p","children":["hello"]}]');
    is($status, 0, 'pretty mode exits OK');
    like($output, qr/\n/, 'pretty output has newlines');
}

{
    my ($status, $output) =
        run_stdin('[{"tag":"p","children":["hello"]}]', '--compact');
    is($status, 0, 'compact mode exits OK');
    is($output, '[{"children":["hello"],"tag":"p"}]',
        'compact output is canonical JSON');
}

{
    my ($status, $output) = run_stdin('not-json');
    is($status, 2, 'invalid JSON exits INPUT');
    like($output, qr/invalid JSON/, 'invalid JSON reports an error');
}

{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/^Usage: tgph-pretty/m, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

done_testing;
