use v5.36;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../bin/lib";
use Tgph::Diag qw(diag);

# Test with no env var
{
    local $ENV{PUBTG_INDENT};
    open my $fh, '>', \my $out;
    local *STDERR = $fh;
    diag("test message", prefix => 'foo: ');
    is($out, "foo: test message\n", 'no indent when env not set');
}

# Test with env var = 6
{
    local $ENV{PUBTG_INDENT} = '6';
    open my $fh, '>', \my $out;
    local *STDERR = $fh;
    diag("test message", prefix => 'foo: ');
    is($out, "      foo: test message\n", '6 spaces indent');
}

# Test with env var = 0
{
    local $ENV{PUBTG_INDENT} = '0';
    open my $fh, '>', \my $out;
    local *STDERR = $fh;
    diag("test", prefix => 'p: ');
    is($out, "p: test\n", 'zero indent');
}

# Test with invalid env var
{
    local $ENV{PUBTG_INDENT} = 'abc';
    open my $fh, '>', \my $out;
    local *STDERR = $fh;
    diag("test", prefix => 'p: ');
    is($out, "p: test\n", 'invalid env falls back to 0');
}

# Test without prefix
{
    local $ENV{PUBTG_INDENT} = '2';
    open my $fh, '>', \my $out;
    local *STDERR = $fh;
    diag("bare message");
    is($out, "  bare message\n", 'no prefix');
}

done_testing;
