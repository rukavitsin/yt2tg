package Tgph::Normalize;
use v5.36;
use strict;
use warnings;
use Scalar::Util qw(blessed);

sub structural_error {
    my ($nodes) = @_;

    return 'content must be an array reference'
        unless ref($nodes) eq 'ARRAY';

    for my $i (0 .. $#$nodes) {
        my $message = _node_structural_error(
            $nodes->[$i],
            "content[$i]",
        );
        return $message if defined $message;
    }

    return undef;
}

sub normalize {
    my ($nodes, %opts) = @_;

    my $extract_title   = $opts{extract_title} ? 1 : 0;
    my $title;
    my $title_extracted = 0;
    my @result;

    for my $node (@$nodes) {
        if ($extract_title && !$title_extracted && _is_h1($node)) {
            $title = _text_content($node);
            $title_extracted = 1;
            next;
        }

        push @result, _normalize_node($node);
    }

    $title = '' if $extract_title && !defined $title;

    return (\@result, $title);
}

sub _is_h1 {
    my ($node) = @_;

    return ref($node) eq 'HASH'
        && defined $node->{tag}
        && !ref($node->{tag})
        && $node->{tag} eq 'h1';
}

sub _normalize_node {
    my ($node) = @_;

    return $node unless ref($node);

    my %copy = %$node;

    if (exists $copy{children} && ref($copy{children}) eq 'ARRAY') {
        $copy{children} = [
            map { _normalize_node($_) } @{ $copy{children} }
        ];
    }

    if (exists $copy{attrs} && ref($copy{attrs}) eq 'HASH') {
        $copy{attrs} = { %{ $copy{attrs} } };
    }

    if (defined $copy{tag} && !ref($copy{tag})) {
        $copy{tag} = _map_tag($copy{tag});
    }

    return \%copy;
}

sub _map_tag {
    my ($tag) = @_;

    return 'h3' if $tag eq 'h2';
    return 'h4' if $tag =~ /\Ah[13456]\z/;

    return $tag;
}

sub _text_content {
    my ($node) = @_;

    return '' unless defined $node;

    if (!ref($node)) {
        return $node;
    }

    if (ref($node) eq 'HASH') {
        my $children = $node->{children};
        return '' unless ref($children) eq 'ARRAY';

        return join '', map { _text_content($_) } @$children;
    }

    return '';
}

sub _node_structural_error {
    my ($node, $path) = @_;

    return "$path is undefined"
        unless defined $node;

    if (!ref($node)) {
        return undef;
    }

    return "$path must be an object or a string"
        unless ref($node) eq 'HASH' && !blessed($node);

    my $tag = $node->{tag};

    return "$path tag is missing"
        unless defined $tag;

    return "$path tag must be a string"
        if ref($tag);

    return "$path tag must not be empty"
        unless length $tag;

    if (exists $node->{children}) {
        my $children = $node->{children};

        return "$path children must be an array reference"
            unless ref($children) eq 'ARRAY' && !blessed($children);

        for my $j (0 .. $#$children) {
            my $message = _node_structural_error(
                $children->[$j],
                "$path.children[$j]",
            );
            return $message if defined $message;
        }
    }

    if (exists $node->{attrs}) {
        my $attrs = $node->{attrs};

        return "$path attrs must be an object"
            unless ref($attrs) eq 'HASH' && !blessed($attrs);

        for my $name (sort keys %$attrs) {
            my $value = $attrs->{$name};

            return "$path attr '$name' is undefined"
                unless defined $value;

            return "$path attr '$name' must be a string"
                if ref($value);
        }
    }

    return undef;
}

1;
