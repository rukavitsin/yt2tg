package Tgph::Markdown;
use v5.36;
use strict;
use warnings;
use Encode qw(decode encode FB_CROAK);
use IPC::Open2 qw(open2);
use Tgph::FrontMatter;
use Tgph::HTML2Content;

sub convert {
    my ($markdown) = @_;

    my $fm = Tgph::FrontMatter::extract($markdown);

    my $html = _run_cmark($fm->{markdown});

    my $content = Tgph::HTML2Content::convert($html);

    return {
        content  => $content,
        metadata => $fm->{metadata},
    };
}

sub strip_leading_h1 {
    my ($content) = @_;

    return $content unless @$content;

    my $first = $content->[0];

    return $content
        unless ref($first) eq 'HASH'
        && defined($first->{tag})
        && $first->{tag} eq 'h1';

    return [ @$content[1 .. $#$content] ];
}

sub _run_cmark {
    my ($text) = @_;

    my $bytes_in = encode('UTF-8', $text);

    my ($out, $in);
    my $pid = eval { open2($out, $in, 'cmark') };

    if ($@) {
        my $error = $@;
        $error =~ s/\s+\z//;
        die "cannot run cmark: $error\n";
    }

    print {$in} $bytes_in;
    close $in;

    my $html_bytes = do { local $/; <$out> };
    close $out;

    waitpid($pid, 0);
    my $status = $? >> 8;

    die "cmark failed with status $status\n"
        if $status != 0;

    my $html = eval { decode('UTF-8', $html_bytes, FB_CROAK) };

    die "cmark produced invalid UTF-8\n"
        if $@;

    return $html;
}

1;
