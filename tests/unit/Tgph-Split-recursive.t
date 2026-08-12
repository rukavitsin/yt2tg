use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::Split;
use Tgph::JSON;

sub long_text {
    my ($len) = @_;
    return 'x' x $len;
}

# Test 1: oversized paragraph with multiple children gets split
{
    my @children = map { "word$_" } (1 .. 50);
    my $para = { tag => 'p', children => \@children };

    my $full_bytes = Tgph::JSON::bytes([$para]);
    my $max = int($full_bytes / 3);

    my $pages = Tgph::Split::split_pages([$para], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'oversized paragraph produces multiple pages');

    for my $i (0 .. $#$pages) {
        my $bytes = Tgph::JSON::bytes($pages->[$i]);
        cmp_ok($bytes, '<=', $max, "page $i is within limit");
    }
}

# Test 2: oversized list gets split
{
    my @items = map { { tag => 'li', children => ["item$_"] } } (1 .. 30);
    my $list = { tag => 'ul', children => \@items };

    my $full_bytes = Tgph::JSON::bytes([$list]);
    my $max = int($full_bytes / 2);

    my $pages = Tgph::Split::split_pages([$list], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'oversized list produces multiple pages');

    for my $i (0 .. $#$pages) {
        my $bytes = Tgph::JSON::bytes($pages->[$i]);
        cmp_ok($bytes, '<=', $max, "list page $i is within limit");
    }
}

# Test 3: oversized text node is split (v2), data preserved
{
    my $big_text = long_text(200);
    my $max = 100;

    my $pages = Tgph::Split::split_pages([$big_text], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'oversized text node is split into pages');

    my $joined = '';
    for my $i (0 .. $#$pages) {
        my $bytes = Tgph::JSON::bytes($pages->[$i]);
        cmp_ok($bytes, '<=', $max, "text page $i is within limit");
        $joined .= join '', @{ $pages->[$i] };
    }

    is($joined, $big_text, 'text data is preserved after split');
}

# Test 4: split_node returns multiple nodes for oversized element
{
    my @children = map { "c$_" } (1 .. 20);
    my $node = { tag => 'p', children => \@children };

    my $full_bytes = Tgph::JSON::bytes([$node]);
    my $max = int($full_bytes / 3);

    my $split = Tgph::Split::split_node($node, max_bytes => $max);

    cmp_ok(scalar @$split, '>', 1, 'split_node produces multiple nodes');

    for my $n (@$split) {
        is($n->{tag}, 'p', 'split node preserves tag');
    }

    my $total_children = 0;
    $total_children += scalar @{$_->{children}} for @$split;
    is($total_children, scalar @children, 'all children preserved after split');
}

# Test 5: split_node with single oversized child recurses
{
    my @items = map { { tag => 'li', children => ["item$_"] } } (1 .. 30);
    my $list = { tag => 'ul', children => \@items };
    my $para = { tag => 'blockquote', children => [$list] };

    my $full_bytes = Tgph::JSON::bytes([$para]);
    my $max = int($full_bytes / 2);

    my $pages = Tgph::Split::split_pages([$para], max_bytes => $max);

    cmp_ok(scalar @$pages, '>', 1, 'nested oversized content produces multiple pages');
}

# Test 6: content that fits is not split
{
    my $small = { tag => 'p', children => ['hello'] };
    my $pages = Tgph::Split::split_pages([$small], max_bytes => 1000);

    is(scalar @$pages, 1, 'small content stays as one page');
    is_deeply($pages->[0], [$small], 'small content unchanged');
}

# Test 7: order preservation after recursive split
{
    my @children = map { "item$_" } (1 .. 20);
    my $node = { tag => 'p', children => \@children };

    my $full_bytes = Tgph::JSON::bytes([$node]);
    my $max = int($full_bytes / 3);

    my $split = Tgph::Split::split_node($node, max_bytes => $max);

    my @all_children;
    push @all_children, @{$_->{children}} for @$split;

    is_deeply(\@all_children, \@children, 'children order preserved after split');
}

done_testing;
