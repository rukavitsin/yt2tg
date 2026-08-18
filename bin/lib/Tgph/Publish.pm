package Tgph::Publish;
use v5.36;
use strict;
use warnings;
use Encode qw(decode FB_CROAK);
use HTTP::Tiny ();
use Tgph::JSON;

sub extract_pages {
    my ($data) = @_;

    die "content must be an array reference\n"
        unless ref($data) eq 'ARRAY';

    return [] unless @$data;

    my $all_arrays = 1;

    for my $item (@$data) {
        if (ref($item) ne 'ARRAY') {
            $all_arrays = 0;
            last;
        }
    }

    return $all_arrays ? $data : [$data];
}

sub page_title {
    my ($title, $index) = @_;

    return $title if $index == 0;

    return sprintf('%s (%d)', $title, $index + 1);
}

sub prepare_requests {
    my ($pages, %opts) = @_;

    die "pages must be an array reference\n"
        unless ref($pages) eq 'ARRAY';

    my $title = $opts{title};

    die "title is required\n"
        unless defined($title) && length($title);

    my @requests;

    for my $i (0 .. $#$pages) {
        my $page = $pages->[$i];

        # Inject no-AI-summary marker as first node if requested
        if ($opts{no_ai_summary} && ref($page) eq 'ARRAY') {
            my @with_marker = (
                { tag => 'p', children => ['<!--no-ai-summary-->'] },
                @$page,
            );
            $page = \@with_marker;
        }

        my $content_bytes = Tgph::JSON::encode($page);
        my $content_chars = decode('UTF-8', $content_bytes, FB_CROAK);

        my %fields = (
            title   => page_title($title, $i),
            content => $content_chars,
        );

        if (defined $opts{author_name} && length $opts{author_name}) {
            $fields{author_name} = $opts{author_name};
        }

        if (defined $opts{author_url} && length $opts{author_url}) {
            $fields{author_url} = $opts{author_url};
        }

        if (defined $opts{access_token} && length $opts{access_token}) {
            $fields{access_token} = $opts{access_token};
        }

        # Pass API-level flag to disable AI summary (if supported)
        if ($opts{no_ai_summary}) {
            $fields{disable_ai_summary} = 'true';
        }

        push @requests, {
            method => 'createPage',
            fields => \%fields,
        };
    }

    return \@requests;
}

sub sanitize_requests {
    my ($requests) = @_;

    my @sanitized;

    for my $request (@$requests) {
        my %fields = %{ $request->{fields} };

        $fields{access_token} = '***'
            if exists $fields{access_token};

        push @sanitized, {
            method => $request->{method},
            fields => \%fields,
        };
    }

    return \@sanitized;
}

sub send_requests {
    my ($requests, %opts) = @_;

    my $api_url = $opts{api_url} // 'https://api.telegra.ph';
    my $timeout = $opts{timeout} // 30;

    my $http = HTTP::Tiny->new(
        timeout => $timeout,
        agent   => 'tgph/0.0.1',
    );

    my @results;

    for my $request (@$requests) {
        my $url = $api_url . '/' . $request->{method};

        my %fields = %{ $request->{fields} };

        my $response = eval { $http->post_form($url, \%fields) };

        if ($@ || !ref($response)) {
            my $error = $@ || 'unknown HTTP error';
            $error =~ s/\s+\z//;
            die "API request failed: $error\n";
        }

        unless ($response->{success}) {
            my $status = $response->{status} // 'UNKNOWN';
            my $reason = $response->{reason} // 'request failed';
            my $detail = '';

            if (defined $response->{content} && length $response->{content}) {
                my $body = eval { Tgph::JSON::decode_bytes($response->{content}) };

                if (!$@ && ref($body) eq 'HASH' && defined $body->{error}) {
                    $detail = ": $body->{error}";
                }
            }

            die "API request failed: $status $reason$detail\n";
        }

        my $data = eval { Tgph::JSON::decode_bytes($response->{content}) };

        die "API response is not valid JSON\n"
            if $@;

        unless (ref($data) eq 'HASH' && $data->{ok}) {
            my $error = 'unknown API error';

            if (ref($data) eq 'HASH' && defined $data->{error}) {
                $error = $data->{error};
            }

            die "Telegraph API error: $error\n";
        }

        my $result = $data->{result};

        unless (ref($result) eq 'HASH') {
            die "API response has no result object\n";
        }

        if (!defined $result->{url}
            && defined $result->{path}
            && !ref($result->{path})) {
            $result = {
                %$result,
                url => "https://telegra.ph/$result->{path}",
            };
        }

        unless (defined $result->{url} && !ref($result->{url})) {
            die "API response has no page URL\n";
        }

        push @results, $result;
    }

    return \@results;
}

1;
