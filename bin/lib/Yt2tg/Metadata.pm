package Yt2tg::Metadata;
use v5.36;
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);

# Rule set 2: for text messages/publications
# Removes ONLY emoji using \p{Emoji_Presentation} (color emoji).
# Preserves markdown, punctuation, letters with accents, digits.
sub strip_emoji {
    my ($text) = @_;
    return '' unless defined $text;

    # Remove emoji with presentation (color emoji)
    $text =~ s/\p{Emoji_Presentation}//g;

    # Remove remaining emoji without presentation (some dingbats, symbols)
    $text =~ s/[\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{1F000}-\x{1FFFF}]//g;

    # Remove variation selectors and ZWJ left behind
    $text =~ s/[\x{FE00}-\x{FE0F}\x{200D}]//g;

    # Collapse whitespace
    $text =~ s/\s+/ /g;
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

# Rule set 1: for filenames (unchanged)
sub clean_filename_part {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/[^a-zA-Z0-9а-яА-ЯёЁіІїЇєЄґҐ\s\-\@]//gu;
    $text =~ s/\s+/ /gu;
    $text =~ s/^\s+|\s+$//gu;
    $text =~ s/ /_/g;
    return $text;
}

sub format_time {
    my ($epoch) = @_;
    return undef unless defined $epoch && $epoch =~ /\A\d+\z/;
    return strftime("%Y-%m-%d, %H:%M", localtime($epoch));
}

sub format_date_short {
    my ($epoch) = @_;
    return undef unless defined $epoch && $epoch =~ /\A\d+\z/;
    return strftime("%y%m%d", localtime($epoch));
}

1;
