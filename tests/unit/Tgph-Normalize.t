use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::Normalize;

{
    my ($nodes, $title) = Tgph::Normalize::normalize([]);

    is_deeply($nodes, [], 'empty content is unchanged');
    is($title, undef, 'no title without extraction');
}

{
    my ($nodes, $title) = Tgph::Normalize::normalize(['text']);

    is_deeply($nodes, ['text'], 'text node is unchanged');
}

{
    my ($nodes, $title) = Tgph::Normalize::normalize([
        { tag => 'p', children => ['x'] },
    ]);

    is_deeply(
        $nodes,
        [
            { tag => 'p', children => ['x'] },
        ],
        'paragraph is unchanged',
    );
}

for my $case (
    ['h1', 'h4'],
    ['h2', 'h3'],
    ['h3', 'h4'],
    ['h4', 'h4'],
    ['h5', 'h4'],
    ['h6', 'h4'],
) {
    my ($from, $to) = @$case;

    my ($nodes, $title) = Tgph::Normalize::normalize([
        { tag => $from, children => ['x'] },
    ]);

    is_deeply(
        $nodes,
        [
            { tag => $to, children => ['x'] },
        ],
        "$from maps to $to without title extraction",
    );
}

{
    my ($nodes, $title) = Tgph::Normalize::normalize(
        [
            { tag => 'h1', children => ['Заголовок'] },
            { tag => 'h2', children => ['Секция'] },
        ],
        extract_title => 1,
    );

    is($title, 'Заголовок', 'first h1 title is extracted');

    is_deeply(
        $nodes,
        [
            { tag => 'h3', children => ['Секция'] },
        ],
        'h2 is mapped to h3 after title extraction',
    );
}

{
    my ($nodes, $title) = Tgph::Normalize::normalize(
        [
            { tag => 'p', children => ['x'] },
            { tag => 'h1', children => ['T'] },
            { tag => 'h1', children => ['S'] },
        ],
        extract_title => 1,
    );

    is($title, 'T', 'only first h1 is extracted');

    is_deeply(
        $nodes,
        [
            { tag => 'p', children => ['x'] },
            { tag => 'h4', children => ['S'] },
        ],
        'second h1 is mapped to h4',
    );
}

{
    my ($nodes, $title) = Tgph::Normalize::normalize(
        [
            {
                tag      => 'h1',
                children => [
                    { tag => 'b', children => ['Bold'] },
                    ' tail',
                ],
            },
            { tag => 'p', children => ['x'] },
        ],
        extract_title => 1,
    );

    is($title, 'Bold tail', 'title text flattens inline markup');

    is_deeply(
        $nodes,
        [
            { tag => 'p', children => ['x'] },
        ],
        'title node is removed',
    );
}

{
    my ($nodes, $title) = Tgph::Normalize::normalize([
        {
            tag      => 'blockquote',
            children => [
                { tag => 'h2', children => ['x'] },
            ],
        },
    ]);

    is_deeply(
        $nodes,
        [
            {
                tag      => 'blockquote',
                children => [
                    { tag => 'h3', children => ['x'] },
                ],
            },
        ],
        'nested headings are normalized',
    );
}

{
    my ($nodes, $title) = Tgph::Normalize::normalize([
        { tag => 'a', attrs => { href => '#' }, children => ['x'] },
    ]);

    is_deeply(
        $nodes,
        [
            { tag => 'a', attrs => { href => '#' }, children => ['x'] },
        ],
        'attrs are preserved',
    );
}

{
    is(
        Tgph::Normalize::structural_error(undef),
        'content must be an array reference',
        'undef content is rejected',
    );

    is(
        Tgph::Normalize::structural_error({}),
        'content must be an array reference',
        'hash content is rejected',
    );

    like(
        Tgph::Normalize::structural_error([
            { tag => {} },
        ]),
        qr/tag must be a string/,
        'non-string tag is rejected',
    );

    like(
        Tgph::Normalize::structural_error([
            { tag => 'p', children => {} },
        ]),
        qr/children must be an array reference/,
        'non-array children are rejected',
    );

    is(
        Tgph::Normalize::structural_error([
            { tag => 'h2', children => ['x'] },
        ]),
        undef,
        'structural check allows h2 before normalization',
    );
}

done_testing;
