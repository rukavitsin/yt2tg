package Yt2tg::Telegraph;
use v5.36;
use strict;
use warnings;
use utf8;

sub build_markdown {
    my (%args) = @_;
    my $title      = $args{title}      // '';
    my $channel    = $args{channel}    // '';
    my $date       = $args{date}       // '';
    my $section234 = $args{section234} // '';

    $title =~ s/[\r\n]+/ /g;
    $title =~ s/\s+\z//;
    $channel =~ s/[\r\n]+/ /g;
    $channel =~ s/\s+\z//;
    $section234 =~ s/\s+\z//;

    return join "\n",
        '---',
        "title: $title",
        '---',
        '',
        "## $title",
        '',
        "**$channel**",
        '',
        "*$date*",
        '',
        $section234,
        '';
}

1;
