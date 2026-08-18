use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Yt2tg::Metadata;

# ─── strip_emoji (Rule set 2: text messages) ───────────────────────────────

{
    my $raw = '✅ **Hitchens OBLITERATES Blind Fanatic "Is GOD really this CRUEL?!"**';
    my $clean = Yt2tg::Metadata::strip_emoji($raw);
    is($clean, '**Hitchens OBLITERATES Blind Fanatic "Is GOD really this CRUEL?!"**',
        'emoji removed, markdown preserved');
}

{
    my $raw = '🔥 Мой новый стрим! 🚀 #тест 🎉';
    my $clean = Yt2tg::Metadata::strip_emoji($raw);
    is($clean, 'Мой новый стрим! #тест',
        'emoji removed, # hashtag and cyrillic preserved');
}

{
    my $raw = 'Kenya : un mal mystérieux décime les éléphants • FRANCE 24';
    my $clean = Yt2tg::Metadata::strip_emoji($raw);
    is($clean, 'Kenya : un mal mystérieux décime les éléphants • FRANCE 24',
        'French accents and bullet • preserved');
}

{
    my $raw = 'Hello *world* ~strike~ `code`';
    my $clean = Yt2tg::Metadata::strip_emoji($raw);
    is($clean, 'Hello *world* ~strike~ `code`',
        'all markdown preserved when no emoji');
}

{
    my $raw = 'Title: Test & Demo (v2.0) [live]';
    my $clean = Yt2tg::Metadata::strip_emoji($raw);
    is($clean, 'Title: Test & Demo (v2.0) [live]',
        'punctuation and digits preserved');
}

{
    my $raw = undef;
    my $clean = Yt2tg::Metadata::strip_emoji($raw);
    is($clean, '', 'undef returns empty string');
}

{
    my $raw = '🎬';
    my $clean = Yt2tg::Metadata::strip_emoji($raw);
    is($clean, '', 'standalone emoji becomes empty');
}

# ─── clean_filename_part (Rule set 1: filenames, unchanged) ────────────────

{
    my $raw = 'Hitchens OBLITERATES Blind Fanatic "Is GOD really this CRUEL?!"';
    my $clean = Yt2tg::Metadata::clean_filename_part($raw);
    is($clean, 'Hitchens_OBLITERATES_Blind_Fanatic_Is_GOD_really_this_CRUEL',
        'filename cleaned from punctuation');
}

{
    my $raw = 'The Debate Archive';
    my $clean = Yt2tg::Metadata::clean_filename_part($raw);
    is($clean, 'The_Debate_Archive', 'channel cleaned for filename');
}

{
    my $raw = 'Название канала — тест!';
    my $clean = Yt2tg::Metadata::clean_filename_part($raw);
    is($clean, 'Название_канала_тест', 'cyrillic with dash and punctuation cleaned');
}

{
    my $raw = '  Multiple   Spaces  Test  ';
    my $clean = Yt2tg::Metadata::clean_filename_part($raw);
    is($clean, 'Multiple_Spaces_Test', 'multiple spaces collapsed and trimmed');
}

{
    my $raw = 'Test-with-dashes-and@at';
    my $clean = Yt2tg::Metadata::clean_filename_part($raw);
    is($clean, 'Test-with-dashes-and@at', 'dashes and at preserved');
}

# ─── format_time / format_date_short ──────────────────────────────────────

{
    my $epoch = 1786197606;
    my $formatted = Yt2tg::Metadata::format_time($epoch);
    like($formatted, qr/\A\d{4}-\d{2}-\d{2}, \d{2}:\d{2}\z/, 'timestamp formatted correctly');
}

{
    my $formatted = Yt2tg::Metadata::format_time('not-a-number');
    is($formatted, undef, 'invalid epoch returns undef');
}

{
    my $formatted = Yt2tg::Metadata::format_time(undef);
    is($formatted, undef, 'undef epoch returns undef');
}

{
    my $epoch = 1786197606;
    my $short = Yt2tg::Metadata::format_date_short($epoch);
    like($short, qr/\A\d{6}\z/, 'short date formatted correctly');
}

done_testing;
