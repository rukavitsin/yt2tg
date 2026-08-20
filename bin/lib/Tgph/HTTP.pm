package Tgph::HTTP;
use v5.36;
use strict;
use warnings;
use HTTP::Tiny ();
use Time::HiRes qw(sleep);

sub new {
    my ($class, %args) = @_;
    return bless {
        timeout     => $args{timeout}     // 30,
        retry_count => $args{retry_count} // 3,
        retry_delay => $args{retry_delay} // 1,
        agent       => $args{agent}       // 'tgph/0.0.1',
    }, $class;
}

sub request {
    my ($self, $method, $url, $opts) = @_;

    $opts //= {};

    my $http = HTTP::Tiny->new(
        timeout => $self->{timeout},
        agent   => $self->{agent},
    );

    my $attempt = 0;
    my $max_attempts = $self->{retry_count} + 1;

    while (1) {
        $attempt++;
        my $response = $http->request($method, $url, $opts);

        my $status = $response->{status} // 0;

        # Success: return immediately
        if ($status >= 200 && $status < 300) {
            return $response;
        }

        # Non-retryable client errors (except 429)
        if ($status >= 400 && $status < 500 && $status != 429) {
            return $response;
        }

        # Max attempts reached
        if ($attempt >= $max_attempts) {
            return $response;
        }

        # Retryable: 429, 5xx, timeouts (status 599), connection errors
        my $delay = $self->{retry_delay} * (2 ** ($attempt - 1));
        my $jitter = $delay * 0.25 * rand();
        $delay += $jitter;

        warn "Tgph::HTTP: retrying (attempt $attempt/$max_attempts) after status $status, delay ${delay}s\n";
        sleep($delay);
    }
}

1;
