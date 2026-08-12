package Tgph::Validate;
use v5.36;
use strict;
use warnings;
use Scalar::Util qw(blessed);

my %ALLOWED_TAGS = map { $_ => 1 } qw(
    a aside b blockquote br code em figcaption figure
    h3 h4 hr i iframe img li ol p pre s strong u ul
);

my %NO_CHILDREN_REQUIRED = map { $_ => 1 } qw(
    br hr img iframe
);

sub valid {
    my ($nodes) = @_;
    my $message = error($nodes);
    return defined($message) ? 0 : 1;
}

sub error {
    my ($nodes) = @_;

    return 'content must be an array reference'
        unless ref($nodes) eq 'ARRAY';

    for my $i (0 .. $#$nodes) {
        my $message = _node_error($nodes->[$i], "content[$i]");
        return $message if defined $message;
    }

    return undef;
}

sub _node_error {
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
    return "$path tag '$tag' is not allowed"
        unless $ALLOWED_TAGS{$tag};

    if (exists $node->{children}) {
        my $children = $node->{children};
        return "$path children must be an array reference"
            unless ref($children) eq 'ARRAY' && !blessed($children);

        for my $j (0 .. $#$children) {
            my $message = _node_error(
                $children->[$j],
                "$path.children[$j]",
            );
            return $message if defined $message;
        }
    }
    elsif (!$NO_CHILDREN_REQUIRED{$tag}) {
        return "$path requires children";
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
