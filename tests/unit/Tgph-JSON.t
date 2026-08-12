use v5.36;
use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use Test::More;
use Encode qw(decode_utf8);

use lib "$Bin/../../bin/lib";

use Tgph::JSON;

{
    my $json = Tgph::JSON::encode([]);

    is(
        $json,
        '[]',
        'empty nodes encode as empty JSON array',
    );

    is(
        Tgph::JSON::bytes([]),
        2,
        'empty JSON byte count',
    );
}

{
    my $nodes = ['hello'];

    is(
        Tgph::JSON::encode($nodes),
        '["hello"]',
        'ASCII text node encoding',
    );

    is(
        Tgph::JSON::bytes($nodes),
        9,
        'ASCII JSON byte count',
    );
}

{
    my $nodes = ['Привет'];

    is(
        decode_utf8(Tgph::JSON::encode($nodes)),
        '["Привет"]',
        'UTF-8 text node is not ASCII escaped',
    );

    is(
        Tgph::JSON::bytes($nodes),
        16,
        'UTF-8 JSON byte count',
    );
}

{
    my $nodes = [
        {
            tag => 'p',
            children => ['Привет'],
        },
    ];

    is(
        decode_utf8(Tgph::JSON::encode($nodes)),
        '[{"children":["Привет"],"tag":"p"}]',
        'element node encoding is canonical',
    );

    is(
        Tgph::JSON::bytes($nodes),
        41,
        'element JSON byte count is measured in bytes',
    );
}

{
    my $error;

    {
        local $@;

        eval {
            Tgph::JSON::encode('not an array');
            1;
        } or $error = $@;
    }

    ok(
        defined($error) && length($error),
        'non-array nodes are rejected',
    );
}

done_testing;
