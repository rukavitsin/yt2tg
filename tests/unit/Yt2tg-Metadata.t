use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Yt2tg::Metadata;

{
    my $raw = '✅ **Hitchens OBLITERATES Blind Fanatic "Is GOD really this CRUEL?!"**';
    my $clean = Yt2tg::Metadata::clean_text($raw);
    is($clean, 'Hitchens OBLITERATES Blind Fanatic "Is GOD really this CRUEL?!"', 'emojis and markdown stripped');
}

{
    my $raw = '🔥 Мой новый стрим! 🚀 #тест 🎉';
    my $clean = Yt2tg::Metadata::clean_text($raw);
    is($clean, 'Мой новый стрим! тест', 'cyrillic and punctuation preserved, emojis and hashtags removed');
}

{
    my $raw = undef;
    my $clean = Yt2tg::Metadata::clean_text($raw);
    is($clean, '', 'undef returns empty string');
}

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

{
    my $raw = 'Hitchens OBLITERATES Blind Fanatic "Is GOD really this CRUEL?!"';
    my $clean = Yt2tg::Metadata::clean_filename_part($raw);
    is($clean, 'Hitchens_OBLITERATES_Blind_Fanatic_Is_GOD_really_this_CRUEL', 'filename cleaned from punctuation');
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

done_testing;
