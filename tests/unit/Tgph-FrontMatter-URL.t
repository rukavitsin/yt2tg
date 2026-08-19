use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../bin/lib";
use Tgph::FrontMatter;

my $md_with_url = "---\ntitle: Test\ntelegra_ph_url: https://telegra.ph/Test-Page-08-20\n---\n\n# Test\n\nBody\n";
my $md_no_url = "---\ntitle: Test\n---\n\n# Test\n\nBody\n";
my $md_no_fm = "# Test\n\nBody\n";

# ─── extract_url ───────────────────────────────────────────────────────────

{
    my $url = Tgph::FrontMatter::extract_url($md_with_url);
    is($url, 'https://telegra.ph/Test-Page-08-20', 'extract_url returns URL');
}

{
    my $url = Tgph::FrontMatter::extract_url($md_no_url);
    is($url, undef, 'extract_url returns undef when no URL');
}

{
    my $url = Tgph::FrontMatter::extract_url($md_no_fm);
    is($url, undef, 'extract_url returns undef when no front matter');
}

# ─── extract_path ──────────────────────────────────────────────────────────

{
    my $path = Tgph::FrontMatter::extract_path($md_with_url);
    is($path, 'Test-Page-08-20', 'extract_path extracts path from URL');
}

{
    my $path = Tgph::FrontMatter::extract_path($md_no_url);
    is($path, undef, 'extract_path returns undef when no URL');
}

# ─── rewrite_with_url ──────────────────────────────────────────────────────

{
    my $new_md = Tgph::FrontMatter::rewrite_with_url($md_no_url, 'https://telegra.ph/New-Page');
    like($new_md, qr/telegra_ph_url: https:\/\/telegra\.ph\/New-Page/, 'URL added to front matter');
    like($new_md, qr/^# Test/m, 'body preserved');
}

{
    my $new_md = Tgph::FrontMatter::rewrite_with_url($md_with_url, 'https://telegra.ph/Updated-Page');
    like($new_md, qr/telegra_ph_url: https:\/\/telegra\.ph\/Updated-Page/, 'URL updated in front matter');
    unlike($new_md, qr/Test-Page-08-20/, 'old URL removed');
}

{
    my $new_md = Tgph::FrontMatter::rewrite_with_url($md_no_fm, 'https://telegra.ph/New-Page');
    like($new_md, qr/^---\ntelegra_ph_url: https:\/\/telegra\.ph\/New-Page\n---/m, 'front matter created');
    like($new_md, qr/^# Test/m, 'body preserved');
}

done_testing;
