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
    my $url        = $args{url}        // '';
    my $section234 = $args{section234} // '';

    $title =~ s/[\r\n]+/ /g;
    $title =~ s/\s+\z//;
    $channel =~ s/[\r\n]+/ /g;
    $channel =~ s/\s+\z//;
    $section234 =~ s/\s+\z//;

    my @lines = (
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
    );
    if (defined $url && length $url) {
        push @lines, "Джерело: $url", '';
    }
    push @lines, $section234, '';

    return join "\n", @lines;
}

1;
