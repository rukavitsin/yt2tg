use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw(tempdir);
use JSON::PP;

my $bin = "$Bin/../../bin/tgph-nav";
my $lib = "$Bin/../../bin/lib";
my $dir = tempdir(CLEANUP => 1);

sub run_nav {
    my ($pages, $results, $extra) = @_;
    $extra //= [];
    my $pf = "$dir/pages.json";
    my $rf = "$dir/results.json";
    open my $ph, '>:raw', $pf or die $!;
    print $ph JSON::PP->new->utf8->encode($pages);
    close $ph;
    open my $rh, '>:raw', $rf or die $!;
    print $rh JSON::PP->new->utf8->encode($results);
    close $rh;
    my $args = join ' ', @$extra;
    my $out = `perl -I$lib $bin --results $rf --title T $args $pf 2>&1`;
    return ($?, $out);
}

# ─── single page: no navigation, title preserved ──────────────────────────

{
    my ($status, $out) = run_nav(
        [['a']],
        [{ path => 'P-1', url => 'https://telegra.ph/P-1' }],
    );
    is($status >> 8, 0, 'single page exits OK');
    my $edits = JSON::PP->new->utf8->decode($out);
    is(scalar @$edits, 1, 'one edit');
    is($edits->[0]{path}, 'P-1', 'path preserved');
    is($edits->[0]{title}, 'T', 'first page title plain');
    is_deeply($edits->[0]{content}, ['a'], 'content unchanged for single page');
}

# ─── two pages: next on first, prev on second, indexed titles ─────────────

{
    my ($status, $out) = run_nav(
        [['a'], ['b']],
        [
            { path => 'P-1', url => 'https://telegra.ph/P-1' },
            { path => 'P-2', url => 'https://telegra.ph/P-2' },
        ],
    );
    is($status >> 8, 0, 'two pages exit OK');
    my $edits = JSON::PP->new->utf8->decode($out);

    is($edits->[0]{title}, 'T', 'page 1 title');
    is($edits->[1]{title}, 'T (2)', 'page 2 title indexed');

    is(scalar @{$edits->[0]{content}}, 2, 'first page: original + next');
    my $next = $edits->[0]{content}[1];
    is($next->{children}[0]{attrs}{href}, 'https://telegra.ph/P-2', 'next href correct');
    is($next->{children}[0]{children}[0], 'Частина 2 →', 'next text correct');

    is(scalar @{$edits->[1]{content}}, 2, 'second page: prev + original');
    my $prev = $edits->[1]{content}[0];
    is($prev->{children}[0]{attrs}{href}, 'https://telegra.ph/P-1', 'prev href correct');
    is($prev->{children}[0]{children}[0], '← Частина 1', 'prev text correct');
}

# ─── three pages: middle has both ─────────────────────────────────────────

{
    my ($status, $out) = run_nav(
        [['a'], ['b'], ['c']],
        [
            { path => 'P-1', url => 'https://telegra.ph/P-1' },
            { path => 'P-2', url => 'https://telegra.ph/P-2' },
            { path => 'P-3', url => 'https://telegra.ph/P-3' },
        ],
    );
    is($status >> 8, 0, 'three pages exit OK');
    my $edits = JSON::PP->new->utf8->decode($out);

    is(scalar @{$edits->[1]{content}}, 3, 'middle page: prev + original + next');
    is($edits->[1]{content}[0]{children}[0]{children}[0], '← Частина 1', 'middle prev text');
    is($edits->[1]{content}[2]{children}[0]{children}[0], 'Частина 3 →', 'middle next text');
}

# ─── missing title: USAGE ─────────────────────────────────────────────────

{
    my $pf = "$dir/p2.json";
    my $rf = "$dir/r2.json";
    open my $ph, '>:raw', $pf or die $!;
    print $ph '[[\"a\"]]';
    close $ph;
    open my $rh, '>:raw', $rf or die $!;
    print $rh '[{"path":"P-1","url":"u"}]';
    close $rh;
    my $out = `perl -I$lib $bin --results $rf $pf 2>&1`;
    is($? >> 8, 1, 'missing title exits USAGE');
    like($out, qr/--title/, 'title requirement reported');
}

# ─── count mismatch: error ────────────────────────────────────────────────

{
    my ($status, $out) = run_nav(
        [['a'], ['b']],
        [{ path => 'P-1', url => 'https://telegra.ph/P-1' }],
    );
    isnt($status >> 8, 0, 'count mismatch exits non-zero');
    like($out, qr/!=/, 'mismatch reported');
}

done_testing;
