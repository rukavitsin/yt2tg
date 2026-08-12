use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP ();

my $bin_dir = "$Bin/../../bin";

sub run {
    my ($cmd) = @_;
    my $output = `$cmd 2>&1`;
    my $status = $? >> 8;
    return ($status, $output);
}

my $tmpdir = tempdir(CLEANUP => 1);

# Input: h1 title + h2 sections + paragraphs + empty paragraph for optimize
my $content = '[{"tag":"h1","children":["Test Article"]},{"tag":"h2","children":["Section 1"]},{"tag":"p","children":["First paragraph."]},{"tag":"p","children":[""]},{"tag":"h2","children":["Section 2"]},{"tag":"p","children":["Second paragraph."]}]';

my $content_file = "$tmpdir/content.json";
open my $fh, '>:raw', $content_file or die "Cannot write $content_file: $!";
print {$fh} $content;
close $fh;

# Step 1: normalize — extract title, map h2→h3
my $title_file = "$tmpdir/title.txt";
my ($status, $normalized) =
    run("'$bin_dir/tgph-normalize' --title-out '$title_file' '$content_file'");
is($status, 0, 'normalize exits OK');

# Verify title extracted
open my $tfh, '<:raw', $title_file or die "Cannot read $title_file: $!";
my $title = do { local $/; <$tfh> };
close $tfh;
is($title, 'Test Article', 'title extracted from h1');

# Step 2: optimize — remove empty paragraphs
my $normalized_file = "$tmpdir/normalized.json";
open my $nfh, '>:raw', $normalized_file or die "Cannot write $normalized_file: $!";
print {$nfh} $normalized;
close $nfh;

($status, my $optimized) = run("'$bin_dir/tgph-optimize' '$normalized_file'");
is($status, 0, 'optimize exits OK');

# Verify empty paragraph was removed
my $optimized_data = JSON::PP::decode_json($optimized);
my $original_data = JSON::PP::decode_json($normalized);
is(scalar @$optimized_data, scalar(@$original_data) - 1,
    'optimize removed one empty paragraph');

# Step 3: validate optimized content
my $optimized_file = "$tmpdir/optimized.json";
open my $ofh, '>:raw', $optimized_file or die "Cannot write $optimized_file: $!";
print {$ofh} $optimized;
close $ofh;

($status, my $validate_out) = run("'$bin_dir/tgph-validate' '$optimized_file'");
is($status, 0, 'validate passes on optimized content');

# Step 4: split with small max-bytes to force multi-page output
($status, my $pages_json) =
    run("'$bin_dir/tgph-split' --max-bytes 150 '$optimized_file'");
is($status, 0, 'split exits OK');

my $pages = JSON::PP::decode_json($pages_json);
is(scalar @$pages, 2, 'split produces 2 pages with max-bytes 150');

# Step 5: link — add navigation to multi-page output
my $pages_file = "$tmpdir/pages.json";
open my $pfh, '>:raw', $pages_file or die "Cannot write $pages_file: $!";
print {$pfh} $pages_json;
close $pfh;

($status, my $linked_json) = run("'$bin_dir/tgph-link' '$pages_file'");
is($status, 0, 'link exits OK');

my $linked = JSON::PP::decode_json($linked_json);
is(scalar @$linked, 2, 'link preserves 2 pages');
like($linked_json, qr/Part 1 of 2/, 'navigation added to page 1');
like($linked_json, qr/Part 2 of 2/, 'navigation added to page 2');

# Step 6: publish --dry-run with title from file
my $linked_file = "$tmpdir/linked.json";
open my $lfh, '>:raw', $linked_file or die "Cannot write $linked_file: $!";
print {$lfh} $linked_json;
close $lfh;

($status, my $publish_out) =
    run("'$bin_dir/tgph-publish' --dry-run --title-file '$title_file' '$linked_file'");
is($status, 0, 'publish --dry-run exits OK');

my $requests = JSON::PP::decode_json($publish_out);
is(scalar @$requests, 2, 'publish prepares 2 API requests');
is($requests->[0]{fields}{title}, 'Test Article', 'first request title correct');
is($requests->[1]{fields}{title}, 'Test Article (2)', 'second request title has suffix');
like($requests->[0]{fields}{content}, qr/Part 1 of 2/,
    'first request content includes navigation');

done_testing;
