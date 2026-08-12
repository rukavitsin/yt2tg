use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::Validate;

ok(Tgph::Validate::valid([]), 'empty content is valid');
is(Tgph::Validate::error([]), undef, 'empty content has no error');

is(
    Tgph::Validate::error(undef),
    'content must be an array reference',
    'undef content is rejected',
);

is(
    Tgph::Validate::error({}),
    'content must be an array reference',
    'hash content is rejected',
);

is(
    Tgph::Validate::error('text'),
    'content must be an array reference',
    'string content is rejected',
);

ok(Tgph::Validate::valid(['text']), 'text node is valid');

ok(
    Tgph::Validate::valid([
        { tag => 'p', children => ['text'] },
    ]),
    'paragraph is valid',
);

ok(
    Tgph::Validate::valid([
        { tag => 'br' },
    ]),
    'br without children is valid',
);

ok(
    Tgph::Validate::valid([
        { tag => 'img', attrs => { src => 'x.png' } },
    ]),
    'img without children is valid',
);

ok(
    Tgph::Validate::valid([
        { tag => 'a', attrs => { href => '#' }, children => ['x'] },
    ]),
    'link is valid',
);

ok(
    Tgph::Validate::valid([
        {
            tag      => 'ul',
            children => [
                { tag => 'li', children => ['item'] },
            ],
        },
    ]),
    'list is valid',
);

ok(!Tgph::Validate::valid(undef), 'undef is invalid');

ok(
    !Tgph::Validate::valid([
        { tag => 'div', children => [] },
    ]),
    'unknown tag is invalid',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'h1', children => [] },
    ]),
    'h1 tag is invalid',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'h2', children => [] },
    ]),
    'h2 tag is invalid',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'h5', children => [] },
    ]),
    'h5 tag is invalid',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'h6', children => [] },
    ]),
    'h6 tag is invalid',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'p' },
    ]),
    'paragraph without children is invalid',
);

ok(
    !Tgph::Validate::valid([
        { children => [] },
    ]),
    'missing tag is invalid',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'p', children => {} },
    ]),
    'children must be an array reference',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'p', children => [undef] },
    ]),
    'undefined child is invalid',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'p', children => ['x'], attrs => [] },
    ]),
    'attrs must be an object',
);

ok(
    !Tgph::Validate::valid([
        { tag => 'p', children => ['x'], attrs => { href => [] } },
    ]),
    'attr value must be a string',
);

ok(
    !Tgph::Validate::valid([
        { tag => {}, children => [] },
    ]),
    'tag must be a string',
);

ok(
    !Tgph::Validate::valid([
        { tag => '', children => [] },
    ]),
    'empty tag is invalid',
);

my $error = Tgph::Validate::error([
    {
        tag      => 'p',
        children => [
            { tag => 'div' },
        ],
    },
]);

like(
    $error,
    qr/content\[0\]\.children\[0\]/,
    'error path includes child location',
);

done_testing;
