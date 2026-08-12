use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;

my $script = "$Bin/../../bin/tgph-link";

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
    my ($status, $output) = run_stdin('[["a"]]');

    is($status, 0, 'single page exits OK');
    is($output, '[["a"]]', 'single page is unchanged');
}

{
    my ($status, $output) = run_stdin('[["a"],["b"]]');

    is($status, 0, 'two pages exit OK');
    like($output, qr/Part 1 of 2/, 'page 1 navigation is present');
    like($output, qr/Part 2 of 2/, 'page 2 navigation is present');
    like($output, qr/"tag":"hr"/, 'hr separator is present');
}

{
    my ($status, $output) = run_stdin('[]');

    is($status, 0, 'empty pages array exits OK');
    is($output, '[]', 'empty pages array is unchanged');
}

{
    my ($status, $output) = run_stdin('not-json');

    is($status, 2, 'invalid JSON exits INPUT');
    like($output, qr/invalid JSON/, 'invalid JSON reports an error');
}

{
    my ($status, $output) = run_stdin('{"not":"array"}');

    is($status, 4, 'non-array root exits VALIDATION');
    like($output, qr/must be a JSON array/, 'non-array root reports an error');
}

{
    my ($status, $output) = run_stdin('[["a"],"not-array"]');

    is($status, 4, 'non-array page exits VALIDATION');
    like($output, qr/page 1 must be a JSON array/, 'non-array page reports an error');
}

{
    my ($status, $output) = run_command("'$script' --help");

    is($status, 0, '--help exits OK');
    like($output, qr/^Usage: tgph-link/m, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");

    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

done_testing;
