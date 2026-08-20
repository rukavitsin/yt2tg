use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use lib "$Bin/../../bin/lib";
use Tgph::Journal;

my ($fh, $tmpfile) = tempfile(UNLINK => 1);
close $fh;

{
    my $rec = Tgph::Journal::append_record($tmpfile, {
        action => 'create',
        path   => 'Test-Page-01',
        url    => 'https://telegra.ph/Test-Page-01',
        title  => 'Test Page 1',
    });
    ok($rec->{timestamp}, 'timestamp auto-added');
    is($rec->{action}, 'create', 'action preserved');
}

{
    Tgph::Journal::append_record($tmpfile, {
        action => 'edit',
        path   => 'Test-Page-01',
        url    => 'https://telegra.ph/Test-Page-01',
        title  => 'Test Page 1 Updated',
    });
}

{
    my $found = Tgph::Journal::find_record($tmpfile, 'Test-Page-01');
    ok($found, 'find_record returns record');
    is($found->{action}, 'edit', 'returns last record for path');
    is($found->{title}, 'Test Page 1 Updated', 'latest title');
}

{
    my $not_found = Tgph::Journal::find_record($tmpfile, 'Nonexistent');
    is($not_found, undef, 'find_record returns undef for missing path');
}

{
    my $entries = Tgph::Journal::list_entries($tmpfile);
    is(scalar @$entries, 2, 'list_entries returns all records');
    is($entries->[0]{action}, 'edit', 'newest first');
    is($entries->[1]{action}, 'create', 'oldest last');
}

done_testing;
