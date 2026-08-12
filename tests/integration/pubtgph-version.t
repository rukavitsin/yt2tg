use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;

my $script = "$Bin/../../bin/pubtgph";

my $output = qx{'$script' --version 2>&1};
my $status = $? >> 8;

is($status, 0, '--version exits OK');
is($output, "0.0.1\n", '--version reports current version');

done_testing;
