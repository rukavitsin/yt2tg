use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use Test::More;
use lib "$Bin/../../bin/lib";
use Tgph::Publish;

is_deeply(
    Tgph::Publish::extract_pages([]),
    [],
    'empty input gives no pages',
);

is_deeply(
    Tgph::Publish::extract_pages(['a']),
    [['a']],
    'single text content is wrapped as one page',
);

is_deeply(
    Tgph::Publish::extract_pages([
        { tag => 'p', children => ['x'] },
    ]),
    [
        [
            { tag => 'p', children => ['x'] },
        ],
    ],
    'single element content is wrapped as one page',
);

is_deeply(
    Tgph::Publish::extract_pages([['a'], ['b']]),
    [['a'], ['b']],
    'pages envelope is preserved',
);

is(Tgph::Publish::page_title('T', 0), 'T', 'first page title is unchanged');
is(Tgph::Publish::page_title('T', 1), 'T (2)', 'second page title gets suffix');

{
    my $requests = Tgph::Publish::prepare_requests(
        [['a'], ['b']],
        title => 'T',
    );

    is(scalar @$requests, 2, 'two requests are prepared');

    is($requests->[0]{method}, 'createPage', 'request method is createPage');
    is($requests->[0]{fields}{title}, 'T', 'first request title is correct');
    is($requests->[1]{fields}{title}, 'T (2)', 'second request title is correct');

    is($requests->[0]{fields}{content}, '["a"]', 'first content is canonical JSON');
    is($requests->[1]{fields}{content}, '["b"]', 'second content is canonical JSON');

    ok(!exists $requests->[0]{fields}{access_token},
        'access token is omitted when absent');
}

{
    my $requests = Tgph::Publish::prepare_requests(
        [['Привет']],
        title        => 'Заголовок',
        author_name  => 'Автор',
        author_url   => 'https://example.com',
        access_token => 'secret',
    );

    is(
        $requests->[0]{fields}{content},
        '["Привет"]',
        'UTF-8 content is canonical JSON characters',
    );

    is(
        $requests->[0]{fields}{title},
        'Заголовок',
        'UTF-8 title is preserved',
    );

    is(
        $requests->[0]{fields}{author_name},
        'Автор',
        'author name is preserved',
    );

    is(
        $requests->[0]{fields}{access_token},
        'secret',
        'access token is included',
    );

    my $sanitized = Tgph::Publish::sanitize_requests($requests);

    is(
        $sanitized->[0]{fields}{access_token},
        '***',
        'access token is masked in sanitized requests',
    );

    is(
        $sanitized->[0]{fields}{title},
        'Заголовок',
        'title is preserved in sanitized requests',
    );
}

{
    eval { Tgph::Publish::prepare_requests([['a']], title => '') };
    like($@, qr/title is required/, 'empty title is rejected');

    eval { Tgph::Publish::prepare_requests('not-array', title => 'T') };
    like($@, qr/pages must be an array reference/, 'non-array pages are rejected');
}

done_testing;
