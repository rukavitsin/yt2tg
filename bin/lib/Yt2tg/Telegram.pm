package Yt2tg::Telegram;
use v5.36;
use strict;
use warnings;
use utf8;
use JSON::PP ();
use HTTP::Tiny ();

sub escape_html {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    return $text;
}

sub strip_heading {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/\A\s*###\s+[^\n]*\n?//;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text;
}

sub format_message {
    my (%args) = @_;
    my $title         = $args{title}         // '';
    my $channel       = $args{channel}       // '';
    my $date          = $args{date}          // '';
    my $section1      = $args{section1}      // '';
    my $telegraph_url = $args{telegraph_url} // '';

    my $body = escape_html(strip_heading($section1));
    my $tg_link = '<a href="' . escape_html($telegraph_url) . '">'
        . escape_html($telegraph_url) . '</a>';

    return join "\n",
        "\x{2705} <b>" . escape_html($title) . '</b>',
        '',
        escape_html($channel),
        '',
        '<i>' . escape_html($date) . '</i>',
        '',
        $body,
        '',
        'Детальніше: ' . $tg_link;
}

sub send_message {
    my (%args) = @_;
    my $token   = $args{token};
    my $chat_id = $args{chat_id};
    my $text    = $args{text};
    my $api_url = $args{api_url} // 'https://api.telegram.org';
    my $timeout = $args{timeout} // 30;

    die "token is required\n"
        unless defined $token && length $token;
    die "chat_id is required\n"
        unless defined $chat_id && length $chat_id;
    die "text is required\n"
        unless defined $text && length $text;

    my $endpoint = $api_url . '/bot' . $token . '/sendMessage';
    my $http = HTTP::Tiny->new(timeout => $timeout);
    my $response = $http->post_form($endpoint, {
        chat_id    => $chat_id,
        text       => $text,
        parse_mode => 'HTML',
    });

    unless ($response->{success}) {
        my $status = $response->{status} // 'UNKNOWN';
        my $reason = $response->{reason} // 'request failed';
        my $detail = '';
        if (defined $response->{content} && length $response->{content}) {
            my $body = eval { JSON::PP::decode_json($response->{content}) };
            if (!$@ && ref($body) eq 'HASH' && defined $body->{description}) {
                $detail = ': ' . $body->{description};
            }
        }
        die "Telegram API request failed: $status $reason$detail\n";
    }

    my $data = eval { JSON::PP::decode_json($response->{content}) };
    die "Telegram API response is not valid JSON\n" if $@;
    unless (ref($data) eq 'HASH' && $data->{ok}) {
        my $desc = 'unknown error';
        if (ref($data) eq 'HASH' && defined $data->{description}) {
            $desc = $data->{description};
        }
        die "Telegram API error: $desc\n";
    }
    return $data->{result};
}

1;
