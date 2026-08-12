use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;

my $script = "$Bin/../../bin/tgph-optimize";

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
    is($status, 0, 'empty input exits OK');
    is($output, '[]', 'empty input produces empty output');
}

{
    my ($status, $output) = run_stdin('["a","b"]');
    is($status, 0, 'text merging exits OK');
    is($output, '["ab"]', 'adjacent text nodes are merged');
}

{
    my ($status, $output) =
        run_stdin('[{"tag":"p","children":[""]}]');
    is($status, 0, 'empty paragraph removal exits OK');
    is($output, '[]', 'empty paragraph is removed');
}

{
    my ($status, $output) = run_stdin('[{"tag":"br"}]');
    is($status, 0, 'void element exits OK');
    is($output, '[{"tag":"br"}]', 'void element is preserved');
}

{
    my ($status, $output) = run_stdin('not-json');
    is($status, 2, 'invalid JSON exits INPUT');
    like($output, qr/invalid JSON/, 'invalid JSON reports an error');
}

{
    my ($status, $output) = run_stdin('{}');
    is($status, 4, 'non-array root exits VALIDATION');
    like($output, qr/content must be an array reference/,
        'non-array root reports an error');
}

{
    my ($status, $output) = run_command("'$script' --help");
    is($status, 0, '--help exits OK');
    like($output, qr/^Usage: tgph-optimize/m, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");
    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

done_testing;
