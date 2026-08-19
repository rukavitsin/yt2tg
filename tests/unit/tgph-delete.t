use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($Bin);

my $bin = "$Bin/../../bin/tgph-delete";
my $lib = "$Bin/../../bin/lib";

# ─── dry-run with bare paths ──────────────────────────────────────────────

{
    my $out = `perl -I$lib $bin --dry-run --access-token secret Page-1 Page-2 2>&1`;
    is($? >> 8, 0, 'dry-run exits OK');
    my $reqs = do {
        require JSON::PP;
        JSON::PP->new->utf8->decode($out);
    };
    is(scalar @$reqs, 2, 'two edit requests prepared');
    is($reqs->[0]{method}, 'editPage', 'method is editPage');
    is($reqs->[0]{fields}{path}, 'Page-1', 'path from bare input');
    is($reqs->[0]{fields}{title}, '(deleted)', 'title set to (deleted)');
    is_deeply($reqs->[0]{fields}{content}, '[]', 'content is empty JSON array');
    is($reqs->[1]{fields}{path}, 'Page-2', 'second path');
    is($reqs->[0]{fields}{access_token}, '***', 'token masked');
}

# ─── URL extraction ───────────────────────────────────────────────────────

{
    my $out = `perl -I$lib $bin --dry-run --access-token secret https://telegra.ph/My-Page-08-19 2>&1`;
    is($? >> 8, 0, 'URL input exits OK');
    my $reqs = do {
        require JSON::PP;
        JSON::PP->new->utf8->decode($out);
    };
    is($reqs->[0]{fields}{path}, 'My-Page-08-19', 'path extracted from URL');
}

# ─── missing input: USAGE ─────────────────────────────────────────────────

{
    my $out = `perl -I$lib $bin --dry-run 2>&1`;
    is($? >> 8, 1, 'no input exits USAGE');
    like($out, qr/at least one/, 'error reported');
}

# ─── missing token without dry-run: USAGE ─────────────────────────────────

{
    my $out = `perl -I$lib $bin Page-1 2>&1`;
    is($? >> 8, 1, 'missing token exits USAGE');
    like($out, qr/access token is required/, 'token error reported');
}

done_testing;
