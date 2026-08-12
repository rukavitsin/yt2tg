use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::HTML2Content;

{
    my $nodes = Tgph::HTML2Content::convert("<h1>Title</h1>\n<p>Text</p>\n");

    is_deeply(
        $nodes,
        [
            { tag => 'h1', children => ['Title'] },
            { tag => 'p',  children => ['Text'] },
        ],
        'headings and paragraphs converted',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert(
        '<p>before <strong>bold</strong> after &amp; more</p>'
    );

    is_deeply(
        $nodes,
        [
            {
                tag      => 'p',
                children => [
                    'before ',
                    { tag => 'strong', children => ['bold'] },
                    ' after & more',
                ],
            },
        ],
        'inline elements and entities converted',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert(
        "<pre><code>line1\nline2\n</code></pre>"
    );

    is_deeply(
        $nodes,
        [
            { tag => 'pre', children => ["line1\nline2\n"] },
        ],
        'pre/code unwrapped and newlines preserved',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert(
        "<ul>\n<li>one</li>\n<li>two <a href=\"https://x.y/?a=1&amp;b=2\">link</a></li>\n</ul>"
    );

    is_deeply(
        $nodes,
        [
            {
                tag      => 'ul',
                children => [
                    { tag => 'li', children => ['one'] },
                    {
                        tag      => 'li',
                        children => [
                            'two ',
                            {
                                tag      => 'a',
                                attrs    => { href => 'https://x.y/?a=1&b=2' },
                                children => ['link'],
                            },
                        ],
                    },
                ],
            },
        ],
        'lists and link attrs converted',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert(
        "<p>a</p>\n<hr />\n<p>b <img src=\"i.png\" alt=\"x\" /></p>"
    );

    is_deeply(
        $nodes,
        [
            { tag => 'p', children => ['a'] },
            { tag => 'hr' },
            {
                tag      => 'p',
                children => [
                    'b ',
                    { tag => 'img', attrs => { src => 'i.png' } },
                ],
            },
        ],
        'void tags converted, non-whitelist attrs dropped',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert(
        "<blockquote>\n<p>quoted</p>\n</blockquote>"
    );

    is_deeply(
        $nodes,
        [
            {
                tag      => 'blockquote',
                children => [
                    { tag => 'p', children => ['quoted'] },
                ],
            },
        ],
        'blockquote converted',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert("<ul>\n<li>outer\n<ul>\n<li>inner</li>\n</ul></li>\n</ul>");

    is_deeply(
        $nodes,
        [
            {
                tag      => 'ul',
                children => [
                    {
                        tag      => 'li',
                        children => [
                            'outer ',
                            {
                                tag      => 'ul',
                                children => [
                                    { tag => 'li', children => ['inner'] },
                                ],
                            },
                        ],
                    },
                ],
            },
        ],
        'nested lists converted',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert('<p>x</p></div>');

    is_deeply(
        $nodes,
        [
            { tag => 'p', children => ['x'] },
        ],
        'stray close tag ignored',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert('<h2>Section</h2>');

    is_deeply(
        $nodes,
        [
            { tag => 'h2', children => ['Section'] },
        ],
        'h2 passes through for normalize stage',
    );
}

{
    my $nodes = Tgph::HTML2Content::convert('');

    is_deeply($nodes, [], 'empty HTML produces empty content');
}

done_testing;
