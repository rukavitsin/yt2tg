use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use Test::More;
use Encode qw(encode_utf8);

my $script = "$Bin/../../bin/tgph-validate";

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
        run_stdin('[{"tag":"p","children":["Привет"]}]');

    is($status, 0, 'valid UTF-8 JSON exits OK');
    is($output, '', 'valid input has no output');
}

{
    my ($status, $output) = run_stdin('not-json');

    is($status, 2, 'invalid JSON exits INPUT');
    like($output, qr/invalid JSON/, 'invalid JSON reports an error');
}

{
    my ($status, $output) =
        run_stdin('[{"tag":"div","children":[]}]');

    is($status, 4, 'invalid tag exits VALIDATION');
    like($output, qr/tag 'div' is not allowed/, 'invalid tag reports an error');
}

{
    my ($status, $output) = run_stdin('[{"tag":"p"}]');

    is($status, 4, 'missing children exits VALIDATION');
    like($output, qr/requires children/, 'missing children reports an error');
}

{
    my ($status, $output) = run_stdin('[{"tag":"br"}]');

    is($status, 0, 'void tag without children exits OK');
}

{
    my ($fh, $file) = tempfile();
    binmode $fh, ':raw';
    print {$fh} encode_utf8('[{"tag":"p","children":["Привет"]}]');
    close $fh;

    my ($status, $output) = run_command("'$script' '$file'");
    is($status, 0, 'valid file exits OK');

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
    like($output, qr/^Usage: tgph-validate/m, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");

    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

done_testing;
