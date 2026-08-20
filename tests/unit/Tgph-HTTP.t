use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../bin/lib";
use Tgph::HTTP;

# ─── new() defaults ─────────────────────────────────────────────────────────

{
    my $http = Tgph::HTTP->new();
    is($http->{timeout}, 30, 'default timeout 30');
    is($http->{retry_count}, 3, 'default retry_count 3');
    is($http->{retry_delay}, 1, 'default retry_delay 1');
}

{
    my $http = Tgph::HTTP->new(timeout => 60, retry_count => 5);
    is($http->{timeout}, 60, 'custom timeout');
    is($http->{retry_count}, 5, 'custom retry_count');
}

# ─── request() signature ─────────────────────────────────────────────────────

{
    my $http = Tgph::HTTP->new();
    can_ok($http, 'request');
}

# ─── integration test: real HTTP request (should succeed) ───────────────────

{
    my $http = Tgph::HTTP->new(timeout => 10, retry_count => 2);
    my $response = $http->request('GET', 'https://api.telegra.ph/getPage/Test-Page-01-01', {});

    is(ref($response), 'HASH', 'response is hashref');
    ok(exists $response->{status}, 'response has status');
    ok($response->{status} >= 200 || $response->{status} == 404, 'status is valid HTTP code');
}

done_testing;
