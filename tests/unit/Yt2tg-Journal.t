use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP ();
use lib "$Bin/../../bin/lib";
use Yt2tg::Journal;

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $file = "$tmpdir/log.jsonl";

    my $rec1 = { video_id => 'abc', status => 'success', telegraph_url => 'http://tg/1' };
    my $rec2 = { video_id => 'xyz', status => 'partial', telegraph_url => 'http://tg/2' };
    my $rec3 = { video_id => 'abc', status => 'success', telegraph_url => 'http://tg/3' };

    Yt2tg::Journal::append_record($file, $rec1);
    Yt2tg::Journal::append_record($file, $rec2);
    Yt2tg::Journal::append_record($file, $rec3);

    my $found_abc = Yt2tg::Journal::find_record($file, 'abc');
    is($found_abc->{telegraph_url}, 'http://tg/3', 'returns last matching record');

    my $found_xyz = Yt2tg::Journal::find_record($file, 'xyz');
    is($found_xyz->{status}, 'partial', 'finds exact match');

    my $not_found = Yt2tg::Journal::find_record($file, 'missing');
    is($not_found, undef, 'returns undef for missing video_id');
}

{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $file = "$tmpdir/nonexistent.jsonl";
    my $not_found = Yt2tg::Journal::find_record($file, 'abc');
    is($not_found, undef, 'returns undef when file does not exist');
}

{
    eval { Yt2tg::Journal::append_record('/tmp/test.jsonl', 'not-a-hash') };
    like($@, qr/record must be a hash reference/, 'rejects non-hash record');
}

done_testing;
