use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";

my $script_path = "$Bin/../../bin/yt2tg-subs";

sub load_clean_functions {
    open my $fh, '<:raw', $script_path or die "cannot open script: $!";
    my $code = do { local $/; <$fh> };
    close $fh;
    my ($decode_sub) = $code =~ /(sub decode_entities \{.*?\n\})/s;
    my ($clean_sub) = $code =~ /(sub clean_srt \{.*?\n\})/s;
    die "cannot extract decode_entities" unless $decode_sub;
    die "cannot extract clean_srt" unless $clean_sub;
    my $pkg = 'Yt2tgSubsTest';
    eval "package $pkg; $decode_sub $clean_sub 1;" or die "eval failed: $@";
    return $pkg;
}

my $pkg = load_clean_functions();

{
    no strict 'refs';
    my $srt = <<'SRT';
1
00:00:00,000 --> 00:00:03,000
I'm back with Adam Brown.

2
00:00:03,000 --> 00:00:06,000
You currently lead BlueShift at Google&nbsp;&nbsp;

3
00:00:06,000 --> 00:00:09,000
DeepMind, which is cracking science
and reasoning.

4
00:00:09,000 --> 00:00:12,000
[music]

5
00:00:12,000 --> 00:00:15,000
I'm back with Adam Brown.
SRT
    my $cleaned = &{"${pkg}::clean_srt"}($srt);

    unlike($cleaned, qr/\n/, 'output is a single line');
    unlike($cleaned, qr/&nbsp;/, 'no &nbsp; entities');
    unlike($cleaned, qr/&amp;/, 'no &amp; entities');
    unlike($cleaned, qr/-->/, 'no timestamps');
    unlike($cleaned, qr/\[music\]/, 'no [music] tags');
    my $count = () = $cleaned =~ /Adam Brown/g;
    is($count, 1, 'duplicate lines removed');
    like($cleaned, qr/I'm back with Adam Brown/, 'apostrophes decoded');
    like($cleaned, qr/Google DeepMind/, 'nbsp decoded and merged');
}

{
    no strict 'refs';
    my $decoded = &{"${pkg}::decode_entities"}('a &lt; b &gt; c &quot;d&quot; &amp; e &#65; &#x42;');
    is($decoded, 'a < b > c "d" & e A B', 'all entity types decoded');
}

{
    no strict 'refs';
    my $decoded = &{"${pkg}::decode_entities"}('no entities here');
    is($decoded, 'no entities here', 'plain text unchanged');
}

{
    no strict 'refs';
    my $srt_with_bom = "\x{FEFF}1\n00:00:00,000 --> 00:00:01,000\nHello\n";
    my $cleaned = &{"${pkg}::clean_srt"}($srt_with_bom);
    is($cleaned, 'Hello', 'BOM removed');
}

done_testing;
