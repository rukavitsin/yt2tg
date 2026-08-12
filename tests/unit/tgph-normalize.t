use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use Test::More;

my $script = "$Bin/../../bin/tgph-normalize";

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

sub read_raw {
    my ($file) = @_;

    open my $fh, '<:raw', $file
        or return undef;

    local $/;
    my $data = <$fh>;
    close $fh;

    return $data;
}

{
    my ($status, $output) = run_stdin('[]');

    is($status, 0, 'empty content exits OK');
    is($output, '[]', 'empty content is unchanged');
}

{
    my ($status, $output) =
        run_stdin('[{"tag":"h2","children":["A"]}]');

    is($status, 0, 'h2 normalization exits OK');
    is($output, '[{"children":["A"],"tag":"h3"}]', 'h2 maps to h3');
}

{
    my ($status, $output) =
        run_stdin('[{"tag":"h3","children":["A"]}]');

    is($status, 0, 'h3 normalization exits OK');
    is($output, '[{"children":["A"],"tag":"h4"}]', 'h3 maps to h4');
}

{
    my ($status, $output) =
        run_stdin('[{"tag":"h1","children":["T"]}]');

    is($status, 0, 'h1 without title-out exits OK');
    is($output, '[{"children":["T"],"tag":"h4"}]',
        'h1 maps to h4 without title extraction');
}

{
    my ($title_fh, $title_file) = tempfile();
    close $title_fh;

    my ($status, $output) = run_stdin(
        '[{"tag":"h1","children":["T"]},{"tag":"p","children":["B"]}]',
        '--title-out',
        $title_file,
    );

    is($status, 0, 'title extraction exits OK');
    is($output, '[{"children":["B"],"tag":"p"}]',
        'first h1 is removed when title is extracted');
    is(read_raw($title_file), 'T', 'title file is written');

    unlink $title_file;
}

{
    my ($title_fh, $title_file) = tempfile();
    close $title_fh;

    my ($status, $output) = run_stdin(
        '[{"tag":"p","children":["B"]}]',
        '--title-out',
        $title_file,
    );

    is($status, 0, 'missing h1 with title-out exits OK');
    is($output, '[{"children":["B"],"tag":"p"}]',
        'content is unchanged when there is no h1');
    is(read_raw($title_file), '', 'title file is empty');

    unlink $title_file;
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
    my ($fh, $file) = tempfile();
    binmode $fh, ':raw';
    print {$fh} '[{"tag":"h2","children":["A"]}]';
    close $fh;

    my ($status, $output) = run_command("'$script' '$file'");
    is($status, 0, 'file input exits OK');
    is($output, '[{"children":["A"],"tag":"h3"}]',
        'file content is normalized');

    ($status, $output) =
        run_command("'$script' '/definitely/nonexistent/file'");
    is($status, 2, 'missing file exits INPUT');
    like($output, qr/cannot open/, 'missing file reports open error');

    ($status, $output) = run_command("'$script' '$file' '$file'");
    is($status, 1, 'multiple files exit USAGE');

    unlink $file;
}

{
    my ($status, $output) = run_command("'$script' --help");

    is($status, 0, '--help exits OK');
    like($output, qr/^Usage: tgph-normalize/m, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");

    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

done_testing;
