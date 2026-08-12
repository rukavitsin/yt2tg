use v5.36;
use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use Test::More;

use lib "$Bin/../../bin/lib";

my $script = "$Bin/../../bin/tgph-limit";

sub run_command {
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

{
    my ($status, $output) =
        run_command('["Привет"]', '--json', '--max', '16');

    is($status, 0, 'JSON exactly at limit succeeds');
    is($output, "16\n", 'JSON reports UTF-8 byte count');
}

{
    my ($status, $output) =
        run_command('["Привет"]', '--json', '--max', '15');

    is($status, 4, 'JSON over limit returns VALIDATION');
    is($output, "16\n", 'over-limit JSON reports byte count');
}

{
    my ($status, $output) =
        run_command('[{"tag":"p","children":["Привет"]}]',
            '--json', '--max', '41');

    is($status, 0, 'canonical element JSON exactly at limit succeeds');
    is($output, "41\n", 'element JSON reports byte count');
}

{
    my ($status, $output) =
        run_command('[{"tag":42,"children":"bad"}]',
            '--json', '--max', '100');

    is($status, 2, 'invalid Telegraph nodes return INPUT');
    like($output, qr/invalid Telegraph nodes/,
        'invalid Telegraph nodes report an error');
}

{
    my ($status, $output) =
        run_command('not-json', '--json', '--max', '100');

    is($status, 2, 'invalid JSON returns INPUT');
    like($output, qr/invalid JSON input/,
        'invalid JSON reports an error');
}

done_testing;
