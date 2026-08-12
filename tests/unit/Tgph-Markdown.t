use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::Markdown;

{
    my $content = [
        { tag => 'h1', children => ['Title'] },
        { tag => 'p',  children => ['Text'] },
    ];

    my $stripped = Tgph::Markdown::strip_leading_h1($content);

    is_deeply(
        $stripped,
        [
            { tag => 'p', children => ['Text'] },
        ],
        'leading h1 is stripped',
    );

    is_deeply(
        $content,
        [
            { tag => 'h1', children => ['Title'] },
            { tag => 'p',  children => ['Text'] },
        ],
        'original content is not mutated',
    );
}

{
    my $content = [
        { tag => 'p', children => ['Text'] },
        { tag => 'h1', children => ['Late'] },
    ];

    is_deeply(
        Tgph::Markdown::strip_leading_h1($content),
        $content,
        'non-leading h1 is not stripped',
    );
}

{
    my $content = [
        'bare text',
        { tag => 'h1', children => ['X'] },
    ];

    is_deeply(
        Tgph::Markdown::strip_leading_h1($content),
        $content,
        'leading text node is not stripped',
    );
}

{
    is_deeply(
        Tgph::Markdown::strip_leading_h1([]),
        [],
        'empty content stays empty',
    );
}

done_testing;
