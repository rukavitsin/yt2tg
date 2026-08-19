use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw(tempdir);
use JSON::PP;

my $bin = "$Bin/../../bin/tgph-delete";
my $lib = "$Bin/../../bin/lib";
my $dir = tempdir(CLEANUP => 1);

# ─── dry-run with bare paths ──────────────────────────────────────────────

{
    my $out = `HOME=$dir perl -I$lib $bin --dry-run --access-token secret Page-1 Page-2 2>&1`;
    is($? >> 8, 0, 'dry-run exits OK');
    my $reqs = JSON::PP->new->utf8->decode($out);
    is(scalar @$reqs, 2, 'two edit requests prepared');
    is($reqs->[0]{method}, 'editPage', 'method is editPage');
    is($reqs->[0]{fields}{path}, 'Page-1', 'path from bare input');
    is($reqs->[0]{fields}{title}, '(deleted)', 'title set to (deleted)');
    my $content = JSON::PP->new->utf8->decode($reqs->[0]{fields}{content});
    is(scalar @$content, 1, 'content has one element');
    is($content->[0]{tag}, 'p', 'content element is paragraph');
    is_deeply($content->[0]{children}, ['(deleted)'], 'content text is (deleted)');
    is($reqs->[1]{fields}{path}, 'Page-2', 'second path');
    is($reqs->[0]{fields}{access_token}, '***', 'token masked');
}

# ─── URL extraction ───────────────────────────────────────────────────────

{
    my $out = `HOME=$dir perl -I$lib $bin --dry-run --access-token secret https://telegra.ph/My-Page-08-19 2>&1`;
    is($? >> 8, 0, 'URL input exits OK');
    my $reqs = JSON::PP->new->utf8->decode($out);
    is($reqs->[0]{fields}{path}, 'My-Page-08-19', 'path extracted from URL');
}

# ─── missing input: USAGE (isolated HOME) ─────────────────────────────────

{
    my $out = `HOME=$dir perl -I$lib $bin --dry-run 2>&1`;
    is($? >> 8, 1, 'no input exits USAGE');
    like($out, qr/at least one/, 'error reported');
}

# ─── missing token without dry-run: USAGE (isolated HOME) ─────────────────

{
    my $out = `HOME=$dir perl -I$lib $bin Page-1 2>&1`;
    is($? >> 8, 1, 'missing token exits USAGE');
    like($out, qr/access token is required/, 'token error reported');
}

# ─── read_tgrc strips quotes (write fake .tgrc with quoted values) ────────

{
    open my $fh, '>:encoding(UTF-8)', "$dir/.tgrc" or die $!;
    print $fh qq{TP_TOKEN="my-secret-token"\n};
    print $fh qq{TP_URL='https://example.com'\n};
    close $fh;

    my $out = `HOME=$dir perl -I$lib $bin --dry-run Page-1 2>&1`;
    is($? >> 8, 0, 'dry-run with tgrc token exits OK');
    my $reqs = JSON::PP->new->utf8->decode($out);
    is($reqs->[0]{fields}{access_token}, '***', 'token from tgrc (masked)');

    # Re-run without --dry-run to force API call and inspect the URL used
    # (we just check it does NOT die on "token required")
    $out = `HOME=$dir perl -I$lib $bin Page-1 2>&1`;
    unlike($out, qr/access token is required/, 'token from tgrc is accepted');
}

done_testing;
