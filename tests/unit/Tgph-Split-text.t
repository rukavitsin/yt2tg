use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::Split;
use Tgph::JSON;

sub join_pages {
    my ($pages) = @_;
    my $joined = '';
    for my $page (@$pages) {
        for my $n (@$page) {
            $joined .= ref($n) ? join('', @{ $n->{children} }) : $n;
        }
    }
    return $joined;
}

# Test 1: long paragraph splits, text preserved, tag kept
{
    my $text = join ' ', map { "word$_" } (1 .. 60);
    my $node = { tag => 'p', children => [$text] };
    my $max = 120;

    my $pages = Tgph::Split::split_pages([$node], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'long paragraph splits into pages');

    for my $page (@$pages) {
        cmp_ok(Tgph::JSON::bytes($page), '<=', $max, 'paragraph page within limit');
    }

    is(join_pages($pages), $text, 'paragraph text preserved');
    is($pages->[0][0]{tag}, 'p', 'tag preserved on split nodes');
}

# Test 2: pre with lines groups by lines, data preserved
{
    my $text = join "\n", map { "line $_ " . ('y' x 20) } (1 .. 30);
    my $node = { tag => 'pre', children => [$text] };
    my $max = 150;

    my $pages = Tgph::Split::split_pages([$node], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'long pre splits into pages');

    for my $page (@$pages) {
        cmp_ok(Tgph::JSON::bytes($page), '<=', $max, 'pre page within limit');
    }

    is(join_pages($pages), $text, 'pre content preserved');
}

# Test 3: single long word is hard-split, data preserved
{
    my $word = 'z' x 500;
    my $node = { tag => 'p', children => [$word] };
    my $max = 100;

    my $pages = Tgph::Split::split_pages([$node], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'long word splits into pages');

    for my $page (@$pages) {
        cmp_ok(Tgph::JSON::bytes($page), '<=', $max, 'word page within limit');
    }

    is(join_pages($pages), $word, 'long word data preserved');
}

# Test 4: UTF-8 long word splits safely
{
    my $word = ('Привет' x 40);
    my $node = { tag => 'p', children => [$word] };
    my $max = 100;

    my $pages = Tgph::Split::split_pages([$node], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'UTF-8 word splits into pages');

    for my $page (@$pages) {
        cmp_ok(Tgph::JSON::bytes($page), '<=', $max, 'UTF-8 page within limit');
    }

    is(join_pages($pages), $word, 'UTF-8 data preserved');
}

# Test 5: irregular whitespace preserved exactly
{
    my $text = "a  b   c " . ('q' x 80);
    my $node = { tag => 'p', children => [$text] };
    my $max = 60;

    my $pages = Tgph::Split::split_pages([$node], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'whitespace text splits');
    is(join_pages($pages), $text, 'irregular whitespace preserved exactly');
}

# Test 6: fitting text is unchanged
{
    my $node = { tag => 'p', children => ['short'] };
    my $pages = Tgph::Split::split_pages([$node], max_bytes => 1000);

    is(scalar @$pages, 1, 'fitting text stays one page');
    is_deeply($pages->[0], [$node], 'fitting node unchanged');
}

done_testing;
