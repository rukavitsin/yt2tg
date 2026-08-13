package Yt2tg::Gemini;
use v5.36;
use strict;
use warnings;
use utf8;
use JSON::PP ();
use HTTP::Tiny ();

sub build_request {
    my (%args) = @_;
    my $prompt = $args{prompt};
    my $transcript = $args{transcript};
    die "prompt is required\n"
        unless defined $prompt && length $prompt;
    die "transcript is required\n"
        unless defined $transcript && length $transcript;
    return {
        systemInstruction => {
            parts => [{ text => $prompt }],
        },
        contents => [
            { parts => [{ text => $transcript }] },
        ],
        generationConfig => {
            temperature     => 0.2,
            maxOutputTokens => 65536,
        },
    };
}

sub encode_request {
    my ($request) = @_;
    die "request must be a hash reference\n"
        unless ref($request) eq 'HASH';
    return JSON::PP->new->canonical->utf8->encode($request);
}

sub extract_text {
    my ($response) = @_;
    die "response must be a hash reference\n"
        unless ref($response) eq 'HASH';
    my $candidates = $response->{candidates};
    die "no candidates in response\n"
        unless ref($candidates) eq 'ARRAY' && @$candidates;
    my $content = $candidates->[0]{content};
    die "no content in candidate\n"
        unless ref($content) eq 'HASH';
    my $parts = $content->{parts};
    die "no parts in content\n"
        unless ref($parts) eq 'ARRAY' && @$parts;
    my $text = '';
    for my $part (@$parts) {
        if (ref($part) eq 'HASH' && defined $part->{text}) {
            $text .= $part->{text};
        }
    }
    die "empty text in response\n" unless length $text;
    return $text;
}

sub parse_response {
    my ($json_bytes) = @_;
    die "empty response body\n"
        unless defined $json_bytes && length $json_bytes;
    my $data = eval { JSON::PP->new->utf8->decode($json_bytes) };
    die "invalid JSON in Gemini response\n" if $@ || ref($data) ne 'HASH';
    return extract_text($data);
}

sub send_request {
    my (%args) = @_;
    my $url = $args{url};
    my $api_key = $args{api_key};
    my $request = $args{request};
    die "url is required\n" unless defined $url && length $url;
    die "request is required\n" unless ref($request) eq 'HASH';
    my $body = encode_request($request);
    my %headers = ('Content-Type' => 'application/json');
    if (defined $api_key && length $api_key) {
        $headers{'x-goog-api-key'} = $api_key;
    }
    my $http = HTTP::Tiny->new(timeout => $args{timeout} // 120);
    my $response = $http->request('POST', $url, {
        headers => \%headers,
        content => $body,
    });
    unless ($response->{success}) {
        my $status = $response->{status} // 'UNKNOWN';
        my $reason = $response->{reason} // 'request failed';
        die "Gemini API request failed: $status $reason\n";
    }
    return parse_response($response->{content});
}

1;
