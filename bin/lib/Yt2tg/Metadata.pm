package Yt2tg::Metadata;
use v5.36;
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);

# Rule set 2: for text messages/publications
# Removes ONLY emoji (Extended_Pictographic + variation selectors + ZWJ).
# Preserves markdown (*, _, #, ~, `), punctuation, letters, digits.
sub strip_emoji {
    my ($text) = @_;
    return '' unless defined $text;
    # Remove emoji and pictographic symbols
    $text =~ s/\p{Extended_Pictographic}//g;
    # Remove variation selectors (U+FE00-FE0F) and zero-width joiner (U+200D)
    # which may be left behind after emoji removal
    $text =~ s/[\x{FE00}-\x{FE0F}\x{200D}]//g;
    # Collapse whitespace left by removed emoji
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
