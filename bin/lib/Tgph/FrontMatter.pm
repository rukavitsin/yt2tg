package Tgph::FrontMatter;
use v5.36;
use strict;
use warnings;

sub extract {
    my ($markdown) = @_;

    if ($markdown =~ /\A---\n(.*?)\n---[ \t]*(?:\n|\z)(.*)\z/s) {
        my $yaml_text = $1;
        my $body = $2;

        $body =~ s/\A\n+//;

        return {
            metadata => _parse_simple_yaml($yaml_text),
            markdown => $body,
        };
    }

    return {
        metadata => {},
        markdown => $markdown,
    };
}

sub _parse_simple_yaml {
    my ($text) = @_;
    my %metadata;

    for my $line (split /\n/, $text) {
        next if $line =~ /\A\s*\z/;
        next if $line =~ /\A\s*#/;

        if ($line =~ /\A([A-Za-z0-9_-]+)\s*:\s*(.*?)\s*\z/) {
            my $key = $1;
            my $value = $2;

            $value =~ s/\A['"]//;
            $value =~ s/['"]\z//;

            $metadata{$key} = $value;
        }
    }

    return \%metadata;
}

1;
