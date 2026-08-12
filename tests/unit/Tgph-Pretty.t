use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use Encode qw(decode);
use lib "$Bin/../../bin/lib";
use Tgph::Pretty;
use JSON::PP ();

{
    my $data = [{ tag => 'p', children => ['hello'] }];

    my $pretty = Tgph::Pretty::pretty($data);
    like($pretty, qr/\n/, 'pretty output contains newlines');
    like($pretty, qr/   /, 'pretty output contains indentation');

    my $compact = Tgph::Pretty::compact($data);
    unlike($compact, qr/\n/, 'compact output has no newlines');
    is($compact, '[{"children":["hello"],"tag":"p"}]',
        'compact output is canonical JSON');
}

{
    my $data = [];
    my $pretty = Tgph::Pretty::pretty($data);
    my $compact = Tgph::Pretty::compact($data);

    my $decoded_pretty = JSON::PP::decode_json($pretty);
    my $decoded_compact = JSON::PP::decode_json($compact);
    is_deeply($decoded_pretty, $data, 'pretty round-trips correctly');
    is_deeply($decoded_compact, $data, 'compact round-trips correctly');
}

{
    # Idempotency: pretty(pretty(x)) == pretty(x)
    my $data = [{ tag => 'p', children => ['text'] }];
    my $once = Tgph::Pretty::pretty($data);

    my $decoded = JSON::PP::decode_json($once);
    my $twice = Tgph::Pretty::pretty($decoded);

    is($twice, $once, 'pretty is idempotent');
}

{
    # UTF-8 content: module returns UTF-8 bytes, decode before comparing
    my $data = ['Привет'];

    my $pretty = Tgph::Pretty::pretty($data);
    my $pretty_chars = decode('UTF-8', $pretty);
    like($pretty_chars, qr/Привет/, 'UTF-8 is preserved in pretty output');

    my $compact = Tgph::Pretty::compact($data);
    my $compact_chars = decode('UTF-8', $compact);
    like($compact_chars, qr/Привет/, 'UTF-8 is preserved in compact output');
}

done_testing;
