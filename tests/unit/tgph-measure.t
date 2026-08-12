use v5.36;
use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use File::Temp qw(tempfile);
use Test::More;
use Encode qw(encode_utf8);

my $project_root = "$Bin/../..";
my $program = "$project_root/bin/tgph-measure";

sub run_command {
    my (@command) = @_;

    my $output = qx{@command 2>&1};
    my $status = $? >> 8;

    return ($status, $output);
}

{
    my ($status, $output) =
        run_command("printf '' | '$program'");

    is($status, 0, 'empty stdin exits successfully');
    is($output, "0\n", 'empty stdin is 0 bytes');
}

{
    my ($status, $output) =
        run_command("printf 'abc' | '$program'");

    is($status, 0, 'ASCII stdin exits successfully');
    is($output, "3\n", 'ASCII size is measured in bytes');
}

{
    my ($status, $output) =
        run_command("printf 'Привет' | '$program'");

    is($status, 0, 'UTF-8 stdin exits successfully');
    is($output, "12\n", 'UTF-8 size is measured in bytes');
}

{
    my ($status, $output) =
        run_command("printf 'abc\\n' | '$program'");

    is($status, 0, 'newline input exits successfully');
    is($output, "4\n", 'newline is included in byte count');
}

{
    my ($fh, $file) = tempfile();
    binmode $fh, ":raw";
    print {$fh} encode_utf8("abcПривет\n");
    close $fh;

    my ($status, $output) =
        run_command("'$program' '$file'");

    is($status, 0, 'file input exits successfully');
    is($output, "16\n", 'file size is measured in bytes');

    unlink $file;
}

{
    my ($status, $output) =
        run_command("'$program' '/definitely/nonexistent/file'");

    is($status, 2, 'missing file returns INPUT exit code');
    like($output, qr/cannot open/, 'missing file reports open error');
}

{
    my ($fh, $file) = tempfile();
    print {$fh} "abc";
    close $fh;

    my ($status, $output) =
        run_command("'$program' '$file' extra");

    is($status, 1, 'multiple files return USAGE exit code');

    unlink $file;
}

{
    my ($status, $output) =
        run_command("'$program' --version");

    is($status, 0, '--version exits successfully');
    is($output, "0.0.1\n", '--version reports current version');
}

{
    my ($status, $output) =
        run_command("'$program' --help");

    is($status, 0, '--help exits successfully');
    like($output, qr/^Usage: tgph-measure \[OPTIONS\]/, '--help reports usage');
}

done_testing;
