use v5.36;
use strict;
use warnings;

use FindBin qw($Bin);
use Test::More;

use lib "$Bin/../../bin/lib";

use Tgph::Limit;

ok(
    Tgph::Limit::fits(0, 1),
    'zero bytes fit',
);

ok(
    Tgph::Limit::fits(1, 1),
    'exact limit fits',
);

ok(
    !Tgph::Limit::fits(2, 1),
    'bytes over limit do not fit',
);

ok(
    Tgph::Limit::fits(65536, 65536),
    '64 KiB exactly fits',
);

ok(
    !Tgph::Limit::fits(65537, 65536),
    'one byte over 64 KiB does not fit',
);

{
    my $error;

    {
        local $@;

        eval {
            Tgph::Limit::fits(-1, 100);
            1;
        } or $error = $@;
    }

    like(
        $error // '',
        qr/non-negative integer/,
        'negative byte count is rejected',
    );
}

{
    my $error;

    {
        local $@;

        eval {
            Tgph::Limit::fits(1, 0);
            1;
        } or $error = $@;
    }

    like(
        $error // '',
        qr/positive integer/,
        'zero limit is rejected',
    );
}

done_testing;
