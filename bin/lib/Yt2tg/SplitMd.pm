package Yt2tg::SplitMd;
use v5.36;
use strict;
use warnings;
use utf8;

sub find_section_start {
    my ($markdown, $num) = @_;
    die "markdown is required\n"
        unless defined $markdown && length $markdown;
    die "section number must be a positive integer\n"
        unless defined $num && $num =~ /\A[1-9]\d*\z/;
    if ($markdown =~ /^###\s*$num\./m) {
        return $-[0];
    }
    return undef;
}

sub split_sections {
    my ($markdown) = @_;
    die "markdown is required\n"
        unless defined $markdown && length $markdown;

    my $sec1_start = find_section_start($markdown, 1);
    my $sec2_start = find_section_start($markdown, 2);

    die "section 1 heading not found\n" unless defined $sec1_start;
    die "section 2 heading not found\n" unless defined $sec2_start;
    die "section 2 must come after section 1\n"
        unless $sec2_start > $sec1_start;

    my $section1 = substr($markdown, $sec1_start, $sec2_start - $sec1_start);
    my $section234 = substr($markdown, $sec2_start);

    $section1 =~ s/\s+\z//;
    $section234 =~ s/\s+\z//;

    return {
        section1   => $section1,
        section234 => $section234,
    };
}

1;
