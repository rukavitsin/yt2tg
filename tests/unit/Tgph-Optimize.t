use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::Optimize;

{
    my $result = Tgph::Optimize::optimize([]);
    is_deeply($result, [], 'empty input produces empty output');
}

{
    my $result = Tgph::Optimize::optimize(['hello']);
    is_deeply($result, ['hello'], 'non-empty text node is preserved');
}

{
    my $result = Tgph::Optimize::optimize(['']);
    is_deeply($result, [], 'empty text node is removed');
}

{
    my $result = Tgph::Optimize::optimize(['a', 'b', 'c']);
    is_deeply($result, ['abc'], 'adjacent text nodes are merged');
}

{
    my $result = Tgph::Optimize::optimize(['a', '', 'b']);
    is_deeply($result, ['ab'], 'empty text between texts is removed and texts merged');
}

{
    my $result = Tgph::Optimize::optimize([
        { tag => 'p', children => ['hello'] },
    ]);
    is_deeply(
        $result,
        [{ tag => 'p', children => ['hello'] }],
        'paragraph with text is preserved',
    );
}

{
    my $result = Tgph::Optimize::optimize([
        { tag => 'p', children => [''] },
    ]);
    is_deeply($result, [], 'paragraph with only empty text is removed');
}

{
    my $result = Tgph::Optimize::optimize([
        { tag => 'p', children => [] },
    ]);
    is_deeply($result, [], 'empty paragraph is removed');
}

{
    my $result = Tgph::Optimize::optimize([
        { tag => 'strong', children => [] },
    ]);
    is_deeply($result, [], 'empty strong is removed');
}

{
    my $result = Tgph::Optimize::optimize([
        { tag => 'br' },
    ]);
    is_deeply($result, [{ tag => 'br' }], 'void element br is preserved');
}

{
    my $result = Tgph::Optimize::optimize([
        { tag => 'hr' },
    ]);
    is_deeply($result, [{ tag => 'hr' }], 'void element hr is preserved');
}

{
    my $result = Tgph::Optimize::optimize([
        { tag => 'img', attrs => { src => 'x.png' } },
    ]);
    is_deeply(
        $result,
        [{ tag => 'img', attrs => { src => 'x.png' } }],
        'void element img is preserved',
    );
}

{
    my $result = Tgph::Optimize::optimize([
        {
            tag      => 'p',
            children => [
                { tag => 'strong', children => [''] },
                'text',
            ],
        },
    ]);
    is_deeply(
        $result,
        [{ tag => 'p', children => ['text'] }],
        'empty inline element is removed from paragraph',
    );
}

{
    my $result = Tgph::Optimize::optimize([
        {
            tag      => 'p',
            children => ['a', { tag => 'em', children => ['b'] }, 'c'],
        },
    ]);
    is_deeply(
        $result,
        [{ tag => 'p', children => ['a', { tag => 'em', children => ['b'] }, 'c'] }],
        'text around inline element is not merged across element boundary',
    );
}

{
    # Idempotency check
    my $input = [
        { tag => 'p', children => ['', 'a', '', 'b'] },
        { tag => 'p', children => [] },
        'c',
        '',
        'd',
    ];
    my $once = Tgph::Optimize::optimize($input);
    my $twice = Tgph::Optimize::optimize($once);
    is_deeply($twice, $once, 'optimize is idempotent');
}

{
    eval { Tgph::Optimize::optimize('not-array') };
    like($@, qr/nodes must be an array reference/, 'non-array input is rejected');
}

done_testing;
