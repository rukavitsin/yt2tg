package Tgph::Link;
use v5.36;
use strict;
use warnings;

sub add_navigation {
    my ($pages, %opts) = @_;

    die "pages must be an array reference\n"
        unless ref($pages) eq 'ARRAY';

    my $total = scalar @$pages;

    return [] unless $total;
    return $pages if $total == 1;

    my @result;

    for my $i (0 .. $#$pages) {
        my $page = $pages->[$i];
        my @new_page = @$page;

        my $part = $i + 1;
        my $nav_text = "Part $part of $total";

        push @new_page, { tag => 'hr' };
        push @new_page, {
            tag      => 'p',
            children => [
                { tag => 'em', children => [$nav_text] },
            ],
        };

        push @result, \@new_page;
    }

    return \@result;
}

1;
