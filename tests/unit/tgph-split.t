use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use File::Temp qw(tempdir);
use Test::More;

my $script = "$Bin/../../bin/tgph-split";

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
    my ($status, $output) =
        run_stdin('["a","b"]', '--max-bytes', '100');

    is($status, 0, 'small content exits OK');
    is($output, '[["a","b"]]', 'single page output to stdout');
}

{
    my ($status, $output) =
        run_stdin('["aaaa","bbbb"]', '--max-bytes', '12');

    is($status, 0, 'split content exits OK');
    is($output, '[["aaaa"],["bbbb"]]', 'two pages in stdout JSON');
}

{
    my ($status, $output) =
        run_stdin('[]', '--max-bytes', '100');

    is($status, 0, 'empty input exits OK');
    is($output, '[]', 'empty input produces empty pages array');
}

{
    # v2: oversized text node is split, no VALIDATION
    my $big = 'x' x 200;
    my $input = '["' . $big . '"]';
    my ($status, $output) =
        run_stdin($input, '--max-bytes', '100');

    is($status, 0, 'oversized text node is split in v2');
    unlike($output, qr/exceed --max-bytes/, 'no oversized warning after split');
}

{
    my $dir = tempdir(CLEANUP => 1);

    my ($status, $output) =
        run_stdin('["aaaa","bbbb"]', '--max-bytes', '12', '--output-dir', $dir);

    is($status, 0, 'output-dir mode exits OK');
    is($output, "2\n", 'reports page count');

    ok(-f "$dir/page001.json", 'page001.json is created');
    ok(-f "$dir/page002.json", 'page002.json is created');
    ok(!-f "$dir/page003.json", 'page003.json is not created');

    open my $fh1, '<:raw', "$dir/page001.json";
    local $/;
    my $page1 = <$fh1>;
    close $fh1;
    is($page1, '["aaaa"]', 'page001.json content is correct');

    open my $fh2, '<:raw', "$dir/page002.json";
    my $page2 = <$fh2>;
    close $fh2;
    is($page2, '["bbbb"]', 'page002.json content is correct');
}

{
    my ($status, $output) = run_stdin('not-json', '--max-bytes', '100');

    is($status, 2, 'invalid JSON exits INPUT');
    like($output, qr/invalid JSON/, 'invalid JSON reports an error');
}

{
    my ($status, $output) = run_stdin('{}', '--max-bytes', '100');

    is($status, 4, 'non-array root exits VALIDATION');
    like($output, qr/content must be an array reference/,
        'non-array root reports an error');
}

{
    my ($status, $output) = run_stdin('["a"]');

    is($status, 1, 'missing --max-bytes exits USAGE');
    like($output, qr/--max-bytes/, 'missing --max-bytes reports an error');
}

{
    my ($status, $output) = run_stdin('["a"]', '--max-bytes', '0');

    is($status, 1, 'zero --max-bytes exits USAGE');
    like($output, qr/--max-bytes/, 'zero --max-bytes reports an error');
}

{
    my ($status, $output) = run_command("'$script' --help");

    is($status, 0, '--help exits OK');
    like($output, qr/^Usage: tgph-split/m, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");

    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

done_testing;
