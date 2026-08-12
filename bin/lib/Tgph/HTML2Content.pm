package Tgph::HTML2Content;
use v5.36;
use strict;
use warnings;

my %VOID_TAGS = map { $_ => 1 } qw(br hr img);

my %ATTR_WHITELIST = (
    a   => { href => 1 },
    img => { src  => 1 },
);

my %ENTITIES = (
    amp  => '&',
    lt   => '<',
    gt   => '>',
    quot => '"',
    apos => "'",
    nbsp => "\x{A0}",
);

sub convert {
    my ($html) = @_;

    my @root;
    my @stack;

    for my $token (_tokenize($html)) {
        my $type = $token->{type};

        if ($type eq 'text') {
            my $text = _text_node($token->{value}, \@stack);
            next unless defined $text;
            _append(\@stack, \@root, $text);
        }
        elsif ($type eq 'open') {
            my $node = { tag => $token->{tag}, children => [] };
            my $attrs = _filter_attrs($token->{tag}, $token->{attrs});
            $node->{attrs} = $attrs if %$attrs;
            push @stack, $node;
        }
        elsif ($type eq 'void') {
            my $node = { tag => $token->{tag} };
            my $attrs = _filter_attrs($token->{tag}, $token->{attrs});
            $node->{attrs} = $attrs if %$attrs;
            _append(\@stack, \@root, $node);
        }
        else {
            _close_tag(\@stack, \@root, $token->{tag});
        }
    }

    while (@stack) {
        _finalize_top(\@stack, \@root);
    }

    _unwrap_pre_code(\@root);

    return \@root;
}

sub _append {
    my ($stack, $root, $node) = @_;

    if (@$stack) {
        push @{ $stack->[-1]{children} }, $node;
    }
    else {
        push @$root, $node;
    }
}

sub _finalize_top {
    my ($stack, $root) = @_;

    my $node = pop @$stack;
    _append($stack, $root, $node);
}

sub _close_tag {
    my ($stack, $root, $tag) = @_;

    for (my $i = $#$stack; $i >= 0; $i--) {
        if ($stack->[$i]{tag} eq $tag) {
            while ($#$stack >= $i) {
                _finalize_top($stack, $root);
            }
            return;
        }
    }

    return;
}

sub _text_node {
    my ($raw, $stack) = @_;

    my $in_pre = grep { $_->{tag} eq 'pre' } @$stack;

    if ($in_pre) {
        my $text = _decode_entities($raw);
        return undef if $text eq '';
        return $text;
    }

    my $text = $raw;
    $text =~ s/\s+/ /g;
    return undef if $text eq '' || $text eq ' ';

    return _decode_entities($text);
}

sub _tokenize {
    my ($html) = @_;
    my @tokens;

    pos($html) = 0;

    while (pos($html) < length($html)) {
        if ($html =~ /\G<!--.*?-->/sgc) {
            next;
        }

        if ($html =~ /\G<\s*([a-zA-Z][a-zA-Z0-9]*)((?:[^>"']|"[^"]*"|'[^']*')*?)(\/?)\s*>/sgc) {
            my ($tag, $attrstr, $slash) = (lc $1, $2, $3);
            my $attrs = _parse_attrs($attrstr);

            if ($slash || $VOID_TAGS{$tag}) {
                push @tokens, { type => 'void', tag => $tag, attrs => $attrs };
            }
            else {
                push @tokens, { type => 'open', tag => $tag, attrs => $attrs };
            }
            next;
        }

        if ($html =~ /\G<\/\s*([a-zA-Z][a-zA-Z0-9]*)\s*>/sgc) {
            push @tokens, { type => 'close', tag => lc $1 };
            next;
        }

        if ($html =~ /\G([^<]+)/sgc) {
            push @tokens, { type => 'text', value => $1 };
            next;
        }

        push @tokens, { type => 'text', value => '<' };
        pos($html)++;
    }

    return @tokens;
}

sub _parse_attrs {
    my ($s) = @_;
    my %attrs;

    while ($s =~ /([a-zA-Z][a-zA-Z0-9-]*)\s*(?:=\s*("[^"]*"|'[^']*'|[^\s>]+))?/g) {
        my ($name, $value) = (lc $1, $2);
        next unless defined $value;

        $value =~ s/\A["']//;
        $value =~ s/["']\z//;

        $attrs{$name} = _decode_entities($value);
    }

    return \%attrs;
}

sub _filter_attrs {
    my ($tag, $attrs) = @_;

    my $allowed = $ATTR_WHITELIST{$tag} or return {};
    my %out;

    for my $name (keys %$allowed) {
        $out{$name} = $attrs->{$name}
            if defined $attrs->{$name} && length $attrs->{$name};
    }

    return \%out;
}

sub _decode_entities {
    my ($s) = @_;

    $s =~ s/&#x([0-9a-fA-F]+);/chr(hex($1))/ge;
    $s =~ s/&#([0-9]+);/chr($1)/ge;
    $s =~ s/&([a-zA-Z][a-zA-Z0-9]*);/
        exists $ENTITIES{$1} ? $ENTITIES{$1} : "&$1;"
    /ge;

    return $s;
}

sub _unwrap_pre_code {
    my ($nodes) = @_;

    for my $node (@$nodes) {
        next unless ref($node) eq 'HASH';
        next unless exists $node->{children};

        _unwrap_pre_code($node->{children});

        if ($node->{tag} eq 'pre'
            && @{ $node->{children} } == 1
            && ref($node->{children}[0]) eq 'HASH'
            && $node->{children}[0]{tag} eq 'code') {
            $node->{children} = $node->{children}[0]{children};
        }
    }
}

1;
