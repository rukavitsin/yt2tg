use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Yt2tg::SplitMd;

my $sample = <<'MD';
### 1. Зміст
Це зміст відео.

### 2. Виклад
Це виклад.

### 3. Ключові факти
- Факт 1
- Факт 2

### 4. Літературно відредагований текст (ПОВНА ВЕРСІЯ)
Повний текст.
MD

{
    my $pos1 = Yt2tg::SplitMd::find_section_start($sample, 1);
    ok(defined $pos1, 'section 1 found');
    is(substr($sample, $pos1, 11), '### 1. Зміс', 'section 1 position correct');
}

{
    my $pos2 = Yt2tg::SplitMd::find_section_start($sample, 2);
    ok(defined $pos2, 'section 2 found');
    is(substr($sample, $pos2, 11), '### 2. Викл', 'section 2 position correct');
}

{
    my $pos9 = Yt2tg::SplitMd::find_section_start($sample, 9);
    is($pos9, undef, 'nonexistent section returns undef');
}

{
    my $result = Yt2tg::SplitMd::split_sections($sample);
    like($result->{section1}, qr/^### 1\. Зміст/, 'section1 starts with heading');
    like($result->{section1}, qr/Це зміст відео\.$/, 'section1 contains content');
    unlike($result->{section1}, qr/### 2\./, 'section1 does not contain section 2');
    like($result->{section234}, qr/^### 2\. Виклад/, 'section234 starts with heading 2');
    like($result->{section234}, qr/### 3\. Ключові факти/, 'section234 contains section 3');
    like($result->{section234}, qr/### 4\./, 'section234 contains section 4');
}

{
    my $no_sec1 = "### 2. Виклад\nТекст";
    eval { Yt2tg::SplitMd::split_sections($no_sec1) };
    like($@, qr/section 1 heading not found/, 'missing section 1 rejected');
}

{
    my $no_sec2 = "### 1. Зміст\nТекст";
    eval { Yt2tg::SplitMd::split_sections($no_sec2) };
    like($@, qr/section 2 heading not found/, 'missing section 2 rejected');
}

{
    eval { Yt2tg::SplitMd::split_sections('') };
    like($@, qr/markdown is required/, 'empty markdown rejected');
}

{
    eval { Yt2tg::SplitMd::find_section_start('text', 0) };
    like($@, qr/positive integer/, 'zero section number rejected');
}

done_testing;
