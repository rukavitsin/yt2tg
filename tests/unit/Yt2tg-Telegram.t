use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Yt2tg::Telegram;

{
    is(Yt2tg::Telegram::escape_html('a & b'), 'a &amp; b',
        'ampersand escaped');
    is(Yt2tg::Telegram::escape_html('<tag>'), '&lt;tag&gt;',
        'angle brackets escaped');
    is(Yt2tg::Telegram::escape_html('plain'), 'plain',
        'plain text unchanged');
    is(Yt2tg::Telegram::escape_html(undef), '',
        'undef returns empty');
}

{
    my $text = "### 1. Зміст\nЦе зміст.";
    is(Yt2tg::Telegram::strip_heading($text), 'Це зміст.',
        'heading stripped');
}

{
    my $text = "### 1. Зміст\n\nТекст.";
    is(Yt2tg::Telegram::strip_heading($text), 'Текст.',
        'heading and blank line stripped');
}

{
    my $text = 'Без заголовка.';
    is(Yt2tg::Telegram::strip_heading($text), 'Без заголовка.',
        'text without heading unchanged');
}

{
    my $msg = Yt2tg::Telegram::format_message(
        title         => 'My Title',
        channel       => 'My Channel',
        date          => '2026-08-08, 17:00',
        section1      => "### 1. Зміст\nSummary text.",
        telegraph_url => 'https://telegra.ph/xyz',
    );
    like($msg, qr/<b>My Title<\/b>/, 'title is bold');
    like($msg, qr/My Channel/, 'channel is present');
    unlike($msg, qr/<b>My Channel<\/b>/, 'channel is not bold');
    like($msg, qr/<i>2026-08-08, 17:00<\/i>/, 'date is italic');
    like($msg, qr/Summary text\./, 'section1 body present');
    unlike($msg, qr/### 1\./, 'section1 heading removed');
    like($msg, qr{<a href="https://telegra\.ph/xyz">}, 'telegraph url linked');
    like($msg, qr/Детальніше:/, 'details label present');
}

{
    my $msg = Yt2tg::Telegram::format_message(
        title    => 'A & B',
        channel  => 'C < D',
        section1 => "### 1. T\nx < y",
    );
    like($msg, qr/<b>A &amp; B<\/b>/, 'title html escaped');
    like($msg, qr/C &lt; D/, 'channel html escaped');
    like($msg, qr/x &lt; y/, 'body html escaped');
}

done_testing;
