package Tgph::Optimize;
use v5.36;
use strict;
use warnings;

sub optimize {
    my ($nodes) = @_;

    die "nodes must be an array reference\n"
        unless ref($nodes) eq 'ARRAY';

    return _optimize_nodes($nodes);
}

sub _optimize_nodes {
    my ($nodes) = @_;

    my @result;

    for my $node (@$nodes) {
        my $optimized = _optimize_node($node);
        push @result, $optimized if defined $optimized;
    }

    @result = _merge_adjacent_text(@result);

    return \@result;
}

sub _optimize_node {
    my ($node) = @_;

    # Text node (scalar)
    if (!ref($node)) {
        return undef unless defined $node;
        return undef if $node eq '';
        return $node;
    }

    # Element node (hash)
    if (ref($node) eq 'HASH') {
        my $children = $node->{children};

        if (ref($children) eq 'ARRAY') {
            my $optimized_children = _optimize_nodes($children);

            # Remove empty non-void elements
            if (!@$optimized_children && !_is_void($node->{tag})) {
                return undef;
            }

            return {
                %$node,
                children => $optimized_children,
            };
        }

        # No children key — keep as is (void elements)
        return { %$node };
    }

    return $node;
}

sub _is_void {
    my ($tag) = @_;
    return 0 unless defined $tag;
    return $tag =~ /\A(br|hr|img|iframe)\z/;
}

sub _merge_adjacent_text {
    my @nodes = @_;
    my @result;

    for my $node (@nodes) {
        if (!ref($node) && @result && !ref($result[-1])) {
            $result[-1] .= $node;
        }
        else {
            push @result, $node;
        }
    }

    return @result;
}

1;
