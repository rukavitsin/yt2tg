package Yt2tg::Metadata;
use v5.36;
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);

sub clean_text {
    my ($text) = @_;
    return '' unless defined $text;
    $text =~ s/[*_#~`]//g;
    $text =~ s/[^\p{L}\p{N}\p{P}\p{Z}\s]//gu;
    $text =~ s/\s+/ /gu;
    $text =~ s/^\s+|\s+$//gu;
    return $text;
}

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
