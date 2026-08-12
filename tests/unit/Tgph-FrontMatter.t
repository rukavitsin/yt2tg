use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::FrontMatter;

{
    my $md = "---\ntitle: Test\nauthor: Alice\n---\n\n# Hello\n\nWorld";
    my $result = Tgph::FrontMatter::extract($md);

    is_deeply(
        $result->{metadata},
        { title => 'Test', author => 'Alice' },
        'front matter metadata extracted',
    );
    is($result->{markdown}, "# Hello\n\nWorld",
        'front matter removed from markdown');
}

{
    my $md = "# No front matter\n\nJust content";
    my $result = Tgph::FrontMatter::extract($md);

    is_deeply($result->{metadata}, {},
        'no front matter returns empty metadata');
    is($result->{markdown}, $md,
        'markdown without front matter unchanged');
}

{
    my $md = "---\ntitle: UTF-8 тест\nauthor: Андрей\n---\n\nКонтент";
    my $result = Tgph::FrontMatter::extract($md);

    is($result->{metadata}{title}, 'UTF-8 тест', 'UTF-8 metadata preserved');
    is($result->{metadata}{author}, 'Андрей', 'UTF-8 author preserved');
    is($result->{markdown}, "Контент", 'UTF-8 body preserved');
}

{
    my $md = "---\ntitle: 'Quoted'\nauthor: \"Double\"\n---\n\nBody";
    my $result = Tgph::FrontMatter::extract($md);

    is($result->{metadata}{title}, 'Quoted', 'single quotes stripped');
    is($result->{metadata}{author}, 'Double', 'double quotes stripped');
}

{
    my $md = "---\ntitle: Test\n# comment line\ndate: 2026-04-04\n---\n\nBody";
    my $result = Tgph::FrontMatter::extract($md);

    is($result->{metadata}{title}, 'Test', 'title extracted');
    is($result->{metadata}{date}, '2026-04-04', 'date extracted');
    ok(!exists $result->{metadata}{'# comment line'}, 'comment ignored');
}

{
    my $md = "---\n\n---\n\nBody";
    my $result = Tgph::FrontMatter::extract($md);

    is_deeply($result->{metadata}, {}, 'empty front matter returns empty metadata');
    is($result->{markdown}, "Body", 'body preserved');
}

done_testing;
