use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use lib "$Bin/../../bin/lib";

my ($fh, $tmpfile) = tempfile(UNLINK => 1);
close $fh;

my $script = "$Bin/../../bin/tgph-journal";

{
    my $record = '{"action":"create","path":"Test-Page","url":"https://telegra.ph/Test-Page","title":"Test"}';
    my $out = `perl -I$Bin/../../bin/lib $script append --journal $tmpfile --record '$record' 2>&1`;
    is($?, 0, 'append succeeds');
}

{
    my $out = `perl -I$Bin/../../bin/lib $script check --journal $tmpfile --path Test-Page 2>&1`;
    is($?, 0, 'check finds existing path');
    like($out, qr{https://telegra\.ph/Test-Page}, 'check returns URL');
}

{
    my $out = `perl -I$Bin/../../bin/lib $script check --journal $tmpfile --path Nonexistent 2>&1`;
    is($?, 256, 'check returns exit 1 for missing path');
}

{
    my $out = `perl -I$Bin/../../bin/lib $script list --journal $tmpfile 2>&1`;
    is($?, 0, 'list succeeds');
    like($out, qr/create/, 'list shows action');
    like($out, qr{https://telegra\.ph/Test-Page}, 'list shows URL');
}

done_testing;
