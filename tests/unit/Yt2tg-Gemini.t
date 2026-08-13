use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin qw($Bin);
use Test::More;
use JSON::PP ();
use lib "$Bin/../../bin/lib";
use Yt2tg::Gemini;

{
    my $request = Yt2tg::Gemini::build_request(
        prompt     => 'PROMPT',
        transcript => 'TRANSCRIPT',
    );
    is(ref($request), 'HASH', 'build_request returns hashref');
    is($request->{systemInstruction}{parts}[0]{text}, 'PROMPT',
        'prompt placed in systemInstruction');
    is($request->{contents}[0]{parts}[0]{text}, 'TRANSCRIPT',
        'transcript placed in contents');
    ok(exists $request->{generationConfig}, 'generationConfig present');
}

{
    eval { Yt2tg::Gemini::build_request(prompt => '', transcript => 'x') };
    like($@, qr/prompt is required/, 'empty prompt rejected');
    eval { Yt2tg::Gemini::build_request(prompt => 'x', transcript => '') };
    like($@, qr/transcript is required/, 'empty transcript rejected');
    eval { Yt2tg::Gemini::build_request(transcript => 'x') };
    like($@, qr/prompt is required/, 'missing prompt rejected');
}

{
    my $request = Yt2tg::Gemini::build_request(
        prompt     => 'p',
        transcript => 't',
    );
    my $json = Yt2tg::Gemini::encode_request($request);
    my $decoded = JSON::PP->new->utf8->decode($json);
    is(ref($decoded), 'HASH', 'encode_request produces valid JSON');
    is($decoded->{systemInstruction}{parts}[0]{text}, 'p',
        'encoded prompt survives round-trip');
}

{
    my $response = {
        candidates => [
            {
                content => {
                    parts => [{ text => '### 1. Зміст' }],
                },
            },
        ],
    };
    is(Yt2tg::Gemini::extract_text($response), '### 1. Зміст',
        'extract_text returns single part text');
}

{
    my $response = {
        candidates => [
            {
                content => {
                    parts => [
                        { text => 'part1 ' },
                        { text => 'part2' },
                    ],
                },
            },
        ],
    };
    is(Yt2tg::Gemini::extract_text($response), 'part1 part2',
        'extract_text concatenates multiple parts');
}

{
    eval { Yt2tg::Gemini::extract_text({}) };
    like($@, qr/no candidates/, 'missing candidates rejected');
    eval { Yt2tg::Gemini::extract_text({ candidates => [] }) };
    like($@, qr/no candidates/, 'empty candidates rejected');
    eval {
        Yt2tg::Gemini::extract_text({
            candidates => [{ content => { parts => [] } }],
        });
    };
    like($@, qr/no parts/, 'empty parts rejected');
    eval {
        Yt2tg::Gemini::extract_text({
            candidates => [{ content => { parts => [{ text => '' }] } }],
        });
    };
    like($@, qr/empty text/, 'empty text rejected');
}

{
    my $body = JSON::PP->new->utf8->encode({
        candidates => [
            { content => { parts => [{ text => 'MARKDOWN' }] } },
        ],
    });
    is(Yt2tg::Gemini::parse_response($body), 'MARKDOWN',
        'parse_response decodes and extracts text');
}

{
    eval { Yt2tg::Gemini::parse_response('') };
    like($@, qr/empty response body/, 'empty body rejected');
    eval { Yt2tg::Gemini::parse_response('not-json') };
    like($@, qr/invalid JSON/, 'invalid JSON rejected');
}

done_testing;
