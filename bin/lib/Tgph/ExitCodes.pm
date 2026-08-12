package Tgph::ExitCodes;

use v5.36;
use strict;
use warnings;

use constant {
    OK          => 0,
    USAGE       => 1,
    INPUT       => 2,
    OUTPUT      => 3,
    VALIDATION  => 4,
    API         => 5,
    INTERNAL    => 70,
};

1;
