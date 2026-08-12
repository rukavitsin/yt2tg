use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::Link;

{
    my $result = Tgph::Link::add_navigation([]);
    is_deeply($result, [], 'empty pages produce empty result');
}

{
    my $pages = [['hello']];
    my $result = Tgph::Link::add_navigation($pages);
    is_deeply($result, $pages, 'single page is returned unchanged');
}

{
    my $pages = [['a'], ['b']];
    my $result = Tgph::Link::add_navigation($pages);

    is(scalar @$result, 2, 'two pages remain two pages');

    # Page 1: original node + hr + navigation paragraph
    is(scalar @{$result->[0]}, 3, 'page 1 has 3 nodes (original + hr + nav)');
    is($result->[0][0], 'a', 'page 1 original node preserved');
    is_deeply($result->[0][1], { tag => 'hr' }, 'page 1 has hr separator');
    is_deeply(
        $result->[0][2],
        {
            tag      => 'p',
            children => [
                { tag => 'em', children => ['Part 1 of 2'] },
            ],
        },
        'page 1 has correct navigation text',
    );

    # Page 2: original node + hr + navigation paragraph
    is(scalar @{$result->[1]}, 3, 'page 2 has 3 nodes (original + hr + nav)');
    is($result->[1][0], 'b', 'page 2 original node preserved');
    is_deeply(
        $result->[1][2],
        {
            tag      => 'p',
            children => [
                { tag => 'em', children => ['Part 2 of 2'] },
            ],
        },
        'page 2 has correct navigation text',
    );
}

{
    my $pages = [['a'], ['b'], ['c']];
    my $result = Tgph::Link::add_navigation($pages);

    is(scalar @$result, 3, 'three pages remain three pages');

    is_deeply(
        $result->[0][2]{children}[0]{children},
        ['Part 1 of 3'],
        'page 1 of 3 has correct text',
    );

    is_deeply(
        $result->[1][2]{children}[0]{children},
        ['Part 2 of 3'],
        'page 2 of 3 has correct text',
    );

    is_deeply(
        $result->[2][2]{children}[0]{children},
        ['Part 3 of 3'],
        'page 3 of 3 has correct text',
    );
}

{
    # Verify original pages are not mutated
    my $pages = [['a'], ['b']];
    my $original_page_0_size = scalar @{$pages->[0]};
    Tgph::Link::add_navigation($pages);
    is(scalar @{$pages->[0]}, $original_page_0_size,
        'original pages are not mutated');
}

{
    eval { Tgph::Link::add_navigation('not-array') };
    like($@, qr/pages must be an array reference/,
        'non-array input is rejected');
}

done_testing;
