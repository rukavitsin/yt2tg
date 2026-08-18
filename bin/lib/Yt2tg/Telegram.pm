package Yt2tg::Telegram;
use v5.36;
use strict;
use warnings;
use utf8;
use JSON::PP ();
use HTTP::Tiny ();
use Encode qw(encode decode FB_CROAK);

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
    my $url           = $args{url}           // '';
    my $section1      = $args{section1}      // '';
    my $telegraph_url = $args{telegraph_url} // '';

    my $body = escape_html(strip_heading($section1));
    my $src_link = '<a href="' . escape_html($url) . '">'
        . escape_html($url) . '</a>';
    my $tg_link = '<a href="' . escape_html($telegraph_url) . '">'
        . escape_html($telegraph_url) . '</a>';

    return join "\n",
        "\x{2705} <b>" . escape_html($title) . '</b>',
        '',
        escape_html($channel),
        '',
        '<i>' . escape_html($date) . '</i>',
        '',
        'Джерело: ' . $src_link,
        '',
        $body,
        '',
        'Детальніше: ' . $tg_link;
}

# Format caption for photo message (simpler, fits in 1024 chars)
sub format_caption {
    my (%args) = @_;
    my $title         = $args{title}         // '';
    my $channel       = $args{channel}       // '';
    my $date          = $args{date}          // '';
    my $url           = $args{url}           // '';
    my $section1      = $args{section1}      // '';
    my $telegraph_url = $args{telegraph_url} // '';

    my $body = escape_html(strip_heading($section1));
    my $src_link = '<a href="' . escape_html($url) . '">'
        . escape_html($url) . '</a>';
    my $tg_link = '<a href="' . escape_html($telegraph_url) . '">'
        . escape_html($telegraph_url) . '</a>';

    return join "\n",
        "\x{2705} <b>" . escape_html($title) . '</b>',
        '',
        escape_html($channel),
        '',
        '<i>' . escape_html($date) . '</i>',
        '',
        'Джерело: ' . $src_link,
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
        chat_id                   => $chat_id,
        text                      => $text,
        parse_mode                => 'HTML',
        disable_web_page_preview  => 'true',
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

# Send photo with caption via multipart/form-data
sub send_photo {
    my (%args) = @_;
    my $token        = $args{token};
    my $chat_id      = $args{chat_id};
    my $photo_path   = $args{photo_path};
    my $caption      = $args{caption} // '';
    my $api_url      = $args{api_url} // 'https://api.telegram.org';
    my $timeout      = $args{timeout} // 60;

    die "token is required\n"
        unless defined $token && length $token;
    die "chat_id is required\n"
        unless defined $chat_id && length $chat_id;
    die "photo_path is required\n"
        unless defined $photo_path && length $photo_path;
    die "photo file not found: $photo_path\n"
        unless -f $photo_path;

    open my $fh, '<:raw', $photo_path or die "cannot open photo: $!\n";
    my $photo_data = do { local $/; <$fh> };
    close $fh;

    my $boundary = "----Yt2tgBoundary" . sprintf("%08x%08x", rand(0xFFFFFFFF), rand(0xFFFFFFFF));

    my $body = '';
    # chat_id
    $body .= "--$boundary\r\n";
    $body .= "Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n";
    $body .= "$chat_id\r\n";
    # parse_mode
    $body .= "--$boundary\r\n";
    $body .= "Content-Disposition: form-data; name=\"parse_mode\"\r\n\r\n";
    $body .= "HTML\r\n";
    # caption (UTF-8 encoded)
    if (length $caption) {
        my $cap_bytes = encode('UTF-8', $caption, FB_CROAK);
        $body .= "--$boundary\r\n";
        $body .= "Content-Disposition: form-data; name=\"caption\"\r\n\r\n";
        $body .= $cap_bytes . "\r\n";
    }
    # photo (file)
    $body .= "--$boundary\r\n";
    $body .= "Content-Disposition: form-data; name=\"photo\"; filename=\"thumb.jpg\"\r\n";
    $body .= "Content-Type: image/jpeg\r\n\r\n";
    $body .= $photo_data . "\r\n";
    # close boundary
    $body .= "--$boundary--\r\n";

    my $http = HTTP::Tiny->new(timeout => $timeout);
    my $endpoint = $api_url . '/bot' . $token . '/sendPhoto';
    my $response = $http->request('POST', $endpoint, {
        content => $body,
        headers => {
            'Content-Type'   => "multipart/form-data; boundary=$boundary",
            'Content-Length' => length($body),
        },
    });

    unless ($response->{success}) {
        my $status = $response->{status} // 'UNKNOWN';
        my $reason = $response->{reason} // 'request failed';
        my $detail = '';
        if (defined $response->{content} && length $response->{content}) {
            my $rbody = eval { JSON::PP::decode_json($response->{content}) };
            if (!$@ && ref($rbody) eq 'HASH' && defined $rbody->{description}) {
                $detail = ': ' . $rbody->{description};
            }
        }
        die "Telegram sendPhoto failed: $status $reason$detail\n";
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
