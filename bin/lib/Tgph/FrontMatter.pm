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

sub extract_url {
    my ($markdown) = @_;
    my $result = extract($markdown);
    my $url = $result->{metadata}{telegra_ph_url};
    return undef unless defined $url && length $url;
    return $url;
}

sub extract_path {
    my ($markdown) = @_;
    my $url = extract_url($markdown);
    return undef unless defined $url;
    if ($url =~ m{^https?://telegra\.ph/(.+)$}) {
        return $1;
    }
    return undef;
}

sub rewrite_with_url {
    my ($markdown, $url) = @_;
    my $result = extract($markdown);
    my $meta = $result->{metadata};
    my $body = $result->{markdown};

    $meta->{telegra_ph_url} = $url;

    my $yaml = "---\n";
    for my $key (sort keys %$meta) {
        my $val = $meta->{$key};
        if ($val =~ /[ \t\n"']/) {
            $val =~ s/"/\\"/g;
            $val = "\"$val\"";
        }
        $yaml .= "$key: $val\n";
    }
    $yaml .= "---\n\n$body";

    return $yaml;
}
