use v5.36;
use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use Test::More;

use lib "$Bin/../../bin/lib";

use Tgph::Node;

{
    my $node = Tgph::Node::text('hello');

    ok(!ref($node), 'text node is a scalar');
    is($node, 'hello', 'text node preserves text');
}

{
    my $node = Tgph::Node::text('Привет');

    ok(!ref($node), 'UTF-8 text node is a scalar');
    is($node, 'Привет', 'UTF-8 text node preserves text');
}

{
    my $node = Tgph::Node::raw({
        tag => 'p',
        children => [
            'hello',
        ],
    });

    is(ref($node), 'HASH', 'raw node is a hash');
    is($node->{tag}, 'p', 'raw node preserves tag');
    is(ref($node->{children}), 'ARRAY', 'raw node preserves children');
    is($node->{children}[0], 'hello', 'raw node preserves text child');
}

{
    my $error;

    {
        local $@;

        eval {
            Tgph::Node::text(undef);
            1;
        } or $error = $@;
    }

    ok(
        defined($error) && length($error),
        'undefined text is rejected',
    );
}

{
    my $error;

    {
        local $@;

        eval {
            Tgph::Node::raw('not a node');
            1;
        } or $error = $@;
    }

    ok(
        defined($error) && length($error),
        'non-hash node is rejected',
    );
}

done_testing;
