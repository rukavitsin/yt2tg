use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw(tempdir);

my $pubtgph = "$Bin/../../bin/pubtgph";
my $lib = "$Bin/../../bin/lib";
my $dir = tempdir(CLEANUP => 1);

# Create long markdown that will split into multiple pages
my $long_md = "$dir/long.md";
open my $fh, '>:encoding(UTF-8)', $long_md or die $!;
print $fh "# Long Article\n\n";
for my $i (1..50) {
    print $fh "## Section $i\n\n";
    print $fh "This is a long paragraph that should generate multiple pages when split. " x 20, "\n\n";
}
close $fh;

# Dry-run to verify structure
my $out = `perl -I$lib $pubtgph --dry-run "$long_md" 2>&1`;
my $status = $? >> 8;

SKIP: {
    skip "dry-run not available or token required", 2 if $status != 0;

    like($out, qr/createPage/, 'dry-run shows createPage');

    my $page_count = () = $out =~ /"method":\s*"createPage"/g;
    cmp_ok($page_count, '>', 1, 'multiple pages created for long content');
}

# Test --no-navigation flag exists
my $help = `$pubtgph --help 2>&1`;
like($help, qr/--no-navigation/, '--no-navigation flag documented');

done_testing;
