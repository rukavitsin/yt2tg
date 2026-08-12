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

{
    my $pages = Tgph::Split::split_pages([], max_bytes => 100);
    is_deeply($pages, [], 'empty input produces no pages');
}

{
    my $pages = Tgph::Split::split_pages(['a'], max_bytes => 100);
    is_deeply($pages, [['a']], 'single small node produces one page');
}

{
    my $pages = Tgph::Split::split_pages(['a', 'b'], max_bytes => 100);
    is_deeply($pages, [['a', 'b']], 'two small nodes fit in one page');
}

{
    my $pages = Tgph::Split::split_pages(
        ['aaaa', 'bbbb', 'cccc'],
        max_bytes => 12,
    );
    is(scalar @$pages, 3, 'three nodes split into three pages when limit is tight');
}

{
    my $pages = Tgph::Split::split_pages(
        ['aa', 'bb', 'cc'],
        max_bytes => 12,
    );
    is(scalar @$pages, 2, 'nodes are packed greedily');
    is_deeply($pages->[0], ['aa', 'bb'], 'first page has two nodes');
    is_deeply($pages->[1], ['cc'], 'second page has one node');
}

{
    # v2: oversized bare text is split, data preserved
    my $big = 'x' x 200;
    my $pages = Tgph::Split::split_pages([$big], max_bytes => 100);

    cmp_ok(scalar @$pages, '>', 1, 'oversized text is split into pages (v2)');

    for my $page (@$pages) {
        cmp_ok(Tgph::JSON::bytes($page), '<=', 100, 'page within limit');
    }

    is(join_pages($pages), $big, 'oversized text data preserved');
}

{
    my $big = 'x' x 200;
    my $pages = Tgph::Split::split_pages(['a', $big, 'b'], max_bytes => 100);

    cmp_ok(scalar @$pages, '>', 3, 'oversized text among nodes forces multiple pages');
    is(join_pages($pages), 'a' . $big . 'b',
        'order and data preserved around oversized text');
}

{
    my $oversized = Tgph::Split::oversized_pages(
        [['small']],
        max_bytes => 100,
    );
    is_deeply($oversized, [], 'no oversized pages detected');
}

{
    my $big = 'x' x 200;
    my $oversized = Tgph::Split::oversized_pages(
        [['small'], [$big]],
        max_bytes => 100,
    );
    is_deeply($oversized, [1], 'oversized page at index 1 is detected');
}

{
    my $page = ['hello'];
    my $bytes = Tgph::Split::page_bytes($page);
    is($bytes, Tgph::JSON::bytes(['hello']), 'page_bytes matches Tgph::JSON::bytes');
}

{
    eval { Tgph::Split::split_pages(['a'], max_bytes => 0) };
    like($@, qr/max_bytes must be a positive integer/, 'zero max_bytes is rejected');

    eval { Tgph::Split::split_pages(['a'], max_bytes => -1) };
    like($@, qr/max_bytes must be a positive integer/, 'negative max_bytes is rejected');

    eval { Tgph::Split::split_pages(['a'], max_bytes => undef) };
    like($@, qr/max_bytes must be a positive integer/, 'undef max_bytes is rejected');
}

done_testing;
