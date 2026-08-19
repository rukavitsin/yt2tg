use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw(tempdir);
use JSON::PP;

my $bin = "$Bin/../../bin/tgph-edit";
my $lib = "$Bin/../../bin/lib";
my $dir = tempdir(CLEANUP => 1);

sub write_file {
    my ($name, $data) = @_;
    my $f = "$dir/$name";
    open my $fh, '>:raw', $f or die $!;
    print $fh ref $data ? JSON::PP->new->utf8->encode($data) : $data;
    close $fh;
    return $f;
}

# ─── dry-run: valid edits ─────────────────────────────────────────────────

{
    my $f = write_file('edits.json', [
        { path => 'P-1', content => ['a'] },
        { path => 'P-2', content => ['b'] },
    ]);
    my $out = `perl -I$lib $bin --dry-run --access-token secret $f 2>&1`;
    is($? >> 8, 0, 'dry-run exits OK');
    my $reqs = JSON::PP->new->utf8->decode($out);
    is(scalar @$reqs, 2, 'two edit requests prepared');
    is($reqs->[0]{method}, 'editPage', 'method is editPage');
    is($reqs->[0]{fields}{path}, 'P-1', 'path preserved');
    is($reqs->[0]{fields}{access_token}, '***', 'token masked');
}

# ─── missing token without dry-run: USAGE ─────────────────────────────────

{
    my $f = write_file('edits2.json', [{ path => 'P-1', content => ['a'] }]);
    my $out = `perl -I$lib $bin $f 2>&1`;
    is($? >> 8, 1, 'missing token exits USAGE');
    like($out, qr/access token is required/, 'token error reported');
}

# ─── invalid JSON: INPUT ──────────────────────────────────────────────────

{
    my $f = write_file('bad.json', 'not json at all');
    my $out = `perl -I$lib $bin --dry-run $f 2>&1`;
    is($? >> 8, 2, 'invalid JSON exits INPUT');
    like($out, qr/invalid JSON/, 'JSON error reported');
}

# ─── non-array input: INPUT ───────────────────────────────────────────────

{
    my $f = write_file('obj.json', { path => 'P-1' });
    my $out = `perl -I$lib $bin --dry-run $f 2>&1`;
    is($? >> 8, 2, 'non-array input exits INPUT');
    like($out, qr/must be a JSON array/, 'array error reported');
}

# ─── missing path: INPUT ──────────────────────────────────────────────────

{
    my $f = write_file('nopath.json', [{ content => ['a'] }]);
    my $out = `perl -I$lib $bin --dry-run $f 2>&1`;
    is($? >> 8, 2, 'missing path exits INPUT');
    like($out, qr/path is required/, 'path error reported');
}

# ─── stdin input works ────────────────────────────────────────────────────

{
    my $json = JSON::PP->new->utf8->encode([{ path => 'P-9', content => ['x'] }]);
    my $out = `echo '$json' | perl -I$lib $bin --dry-run 2>&1`;
    is($? >> 8, 0, 'stdin dry-run exits OK');
    my $reqs = JSON::PP->new->utf8->decode($out);
    is($reqs->[0]{fields}{path}, 'P-9', 'stdin path preserved');
}

done_testing;
