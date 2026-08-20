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

sub _http {
    my ($self) = @_;
    return HTTP::Tiny->new(
        timeout => $self->{timeout},
        agent   => $self->{agent},
    );
}

sub _with_retry {
    my ($self, $code) = @_;
    my $attempt = 0;
    my $max_attempts = $self->{retry_count} + 1;
    while (1) {
        $attempt++;
        my $response = $code->();
        my $status = $response->{status} // 0;
        return $response if $status >= 200 && $status < 300;
        return $response if $status >= 400 && $status < 500 && $status != 429;
        return $response if $attempt >= $max_attempts;
        my $delay = $self->{retry_delay} * (2 ** ($attempt - 1));
        $delay += $delay * 0.25 * rand();
        warn "Tgph::HTTP: retrying (attempt $attempt/$max_attempts) after status $status\n";
        sleep($delay);
    }
}

sub request {
    my ($self, $method, $url, $opts) = @_;
    $opts //= {};
    return $self->_with_retry(sub { $self->_http->request($method, $url, $opts) });
}

sub post_form {
    my ($self, $url, $fields) = @_;
    return $self->_with_retry(sub { $self->_http->post_form($url, $fields) });
}

1;
