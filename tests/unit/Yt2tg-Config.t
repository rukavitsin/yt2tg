use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use Encode qw(encode_utf8);
use lib "$Bin/../../bin/lib";
use Yt2tg::Config;

my $tmpdir = tempdir(CLEANUP => 1);

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} encode_utf8($text);
    close $fh;
}

{
    write_file("$tmpdir/.tgrc", "TG_TOKEN=\"tg_123\"
TP_TOKEN=\"tp_456\"
");
    write_file("$tmpdir/.geminirc", "GEMINI_API_KEY=\"gem_789\"
URL_GEMINI=\"https://api.gemini.com\"
");
    my $config = Yt2tg::Config::load(home => $tmpdir);
    is($config->{tg_token}, 'tg_123', 'tg_token loaded');
    is($config->{tp_token}, 'tp_456', 'tp_token loaded');
    is($config->{gemini_api_key}, 'gem_789', 'gemini_api_key loaded');
    is($config->{url_gemini}, 'https://api.gemini.com', 'url_gemini loaded');
}

{
    my $config = Yt2tg::Config::load(home => "$tmpdir/nonexistent");
    ok(!exists $config->{tg_token}, 'missing config returns empty hash');
}

done_testing;
