package Tgph::Split;
use v5.36;
use strict;
use warnings;
use Tgph::JSON;

sub split_pages {
    my ($nodes, %opts) = @_;
    my $max_bytes = $opts{max_bytes};

    die "max_bytes must be a positive integer\n"
        unless defined($max_bytes) && $max_bytes =~ /\A[1-9]\d*\z/;

    return [] unless @$nodes;

    # Phase 1: expand oversized nodes via recursive splitting
    my @expanded;
    for my $node (@$nodes) {
        my $node_bytes = Tgph::JSON::bytes([$node]);
        if ($node_bytes > $max_bytes) {
            push @expanded, @{ split_node($node, %opts) };
        }
        else {
            push @expanded, $node;
        }
    }

    # Phase 2: greedy packing into pages
    my @pages;
    my @current_page;

    for my $node (@expanded) {
        my $candidate = [@current_page, $node];
        my $candidate_bytes = Tgph::JSON::bytes($candidate);

        if ($candidate_bytes <= $max_bytes || !@current_page) {
            push @current_page, $node;
        }
        else {
            push @pages, [@current_page];
            @current_page = ($node);
        }
    }

    push @pages, [@current_page] if @current_page;

    return \@pages;
}

sub split_node {
    my ($node, %opts) = @_;
    my $max_bytes = $opts{max_bytes};

    # Bare text node: split the text itself
    if (!ref($node)) {
        return _split_text($node, $max_bytes - 2);
    }

    # Element node with children
    if (ref($node) eq 'HASH' && ref($node->{children}) eq 'ARRAY') {
        my $children = $node->{children};

        # Single text child: split text with parent-aware budget
        if (@$children == 1 && !ref($children->[0])) {
            my $overhead =
                Tgph::JSON::bytes([{ %$node, children => [''] }]) - 2;
            my $budget = $max_bytes - $overhead;

            return [$node] if $budget < 4;

            my $chunks = _split_text($children->[0], $budget);

            return [$node] if @$chunks <= 1;

            return [
                map { { %$node, children => [$_] } } @$chunks
            ];
        }

        # Single element child: recurse and re-wrap
        if (@$children == 1) {
            my $split_children = split_node($children->[0], %opts);
            if (@$split_children > 1) {
                return [
                    map { { %$node, children => [$_] } } @$split_children
                ];
            }
            return [$node];
        }

        # Multiple children: greedy packing
        my @groups;
        my @current;

        for my $child (@$children) {
            my $candidate = [@current, $child];
            my $candidate_node = { %$node, children => $candidate };
            my $candidate_bytes = Tgph::JSON::bytes([$candidate_node]);

            if ($candidate_bytes <= $max_bytes || !@current) {
                push @current, $child;
            }
            else {
                push @groups, [@current];
                @current = ($child);
            }
        }
        push @groups, [@current] if @current;

        return [$node] if @groups <= 1;

        return [
            map { { %$node, children => $_ } } @groups
        ];
    }

    return [$node];
}

# JSON-encoded byte size of a bare string (quotes included, brackets excluded)
sub _str_bytes {
    my ($text) = @_;
    return Tgph::JSON::bytes([$text]) - 2;
}

sub _split_text {
    my ($text, $budget) = @_;

    return [$text] if $budget < 4;
    return [$text] if _str_bytes($text) <= $budget;

    my @parts = split /(\s+)/, $text;
    my @chunks;
    my $current = '';

    for my $part (@parts) {
        if ($part =~ /\A\s+\z/) {
            if (_str_bytes($part) > $budget) {
                push @chunks, $current if length $current;
                push @chunks, _hard_split($part, $budget);
                $current = '';
                next;
            }

            if (length($current) && _str_bytes($current . $part) <= $budget) {
                $current .= $part;
            }
            else {
                push @chunks, $current if length $current;
                $current = $part;
            }
            next;
        }

        my @units = _str_bytes($part) <= $budget
            ? ($part)
            : _hard_split($part, $budget);

        for my $unit (@units) {
            if (!length $current) {
                $current = $unit;
            }
            elsif (_str_bytes($current . $unit) <= $budget) {
                $current .= $unit;
            }
            else {
                push @chunks, $current;
                $current = $unit;
            }
        }
    }

    push @chunks, $current if length $current;

    return \@chunks;
}

sub _hard_split {
    my ($text, $budget) = @_;

    my @pieces;
    my $current = '';

    for my $char (split //, $text) {
        if (length($current) && _str_bytes($current . $char) > $budget) {
            push @pieces, $current;
            $current = $char;
        }
        else {
            $current .= $char;
        }
    }

    push @pieces, $current if length $current;

    return @pieces;
}

sub page_bytes {
    my ($page) = @_;
    return Tgph::JSON::bytes($page);
}

sub oversized_pages {
    my ($pages, %opts) = @_;
    my $max_bytes = $opts{max_bytes};

    die "max_bytes must be a positive integer\n"
        unless defined($max_bytes) && $max_bytes =~ /\A[1-9]\d*\z/;

    my @oversized;
    for my $i (0 .. $#$pages) {
        my $bytes = Tgph::JSON::bytes($pages->[$i]);
        push @oversized, $i if $bytes > $max_bytes;
    }

    return \@oversized;
}

1;
