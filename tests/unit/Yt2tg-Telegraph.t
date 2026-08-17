use v5.36;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Yt2tg::Telegraph;

{
    my $md = Yt2tg::Telegraph::build_markdown(
        title      => 'My Title',
        channel    => 'My Channel',
        date       => '2026-08-08, 17:00',
        url        => 'http://youtu.be/abc',
        section234 => "### 2. Виклад\nContent.",
    );
    like($md, qr/\A---\ntitle: My Title\n---\n/, 'front matter present');
    like($md, qr/^## My Title$/m, 'title as h2');
    like($md, qr/^\*\*My Channel\*\*$/m, 'channel bold');
    like($md, qr/^\*2026-08-08, 17:00\*$/m, 'date italic');
    like($md, qr/Джерело: http:\/\/youtu\.be\/abc/, 'source URL present');
    like($md, qr/### 2\. Виклад/, 'section234 heading included');
    like($md, qr/Content\./, 'section234 content included');
}

{
    my $md = Yt2tg::Telegraph::build_markdown(
        title      => "Title\nWith\nNewlines",
        channel    => 'C',
        date       => 'D',
        url        => 'http://youtu.be/x',
        section234 => 'S',
    );
    like($md, qr/title: Title With Newlines/, 'newlines in title replaced');
    like($md, qr/## Title With Newlines/, 'h2 title has no newlines');
}

{
    my $md = Yt2tg::Telegraph::build_markdown(
        title      => 'T',
        channel    => 'C',
        date       => 'D',
        url        => '',
        section234 => "S\n\n\n",
    );
    unlike($md, qr/\n\n\n\z/, 'trailing newlines trimmed from section234');
    unlike($md, qr/Джерело:/, 'no source URL when url is empty');
}

{
    my $md = Yt2tg::Telegraph::build_markdown();
    like($md, qr/\A---\ntitle: \n---\n/, 'empty args produce valid front matter');
}

done_testing;
