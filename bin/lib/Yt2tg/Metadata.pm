package Yt2tg::Metadata;
use v5.36;
use strict;
use warnings;
use POSIX qw(strftime);

sub clean_text {
    my ($text) = @_;
    return '' unless defined $text;
    # Remove common markdown and social formatting
    $text =~ s/[*_#~`]//g;
    # Keep only letters, numbers, punctuation, separators
    $text =~ s/[^\p{L}\p{N}\p{P}\p{Z}\s]//g;
    # Normalize whitespace
    $text =~ s/\s+/ /g;
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

sub format_time {
    my ($epoch) = @_;
    return undef unless defined $epoch && $epoch =~ /\A\d+\z/;
    return strftime("%Y-%m-%d, %H:%M", localtime($epoch));
}

1;
