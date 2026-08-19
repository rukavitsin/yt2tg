use v5.36;
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../bin/lib";
use Tgph::Publish;

# ─── extract_pages ─────────────────────────────────────────────────────────

{
    my $pages = Tgph::Publish::extract_pages([['a'], ['b']]);
    is_deeply($pages, [['a'], ['b']], 'array of arrays preserved');
}

{
    my $pages = Tgph::Publish::extract_pages(['a']);
    is_deeply($pages, [['a']], 'single page wrapped in array');
}

{
    my $pages = Tgph::Publish::extract_pages([]);
    is_deeply($pages, [], 'empty array returns empty');
}

# ─── page_title ────────────────────────────────────────────────────────────

{
    my $title = Tgph::Publish::page_title('Title', 0);
    is($title, 'Title', 'first page has plain title');
}

{
    my $title = Tgph::Publish::page_title('Title', 1);
    is($title, 'Title (2)', 'second page has index');
}

# ─── prepare_requests ─────────────────────────────────────────────────────

{
    my $requests = Tgph::Publish::prepare_requests(
        [['a']],
        title => 'T',
    );
    is(scalar @$requests, 1, 'one request created');
    is($requests->[0]{method}, 'createPage', 'method is createPage');
    is($requests->[0]{fields}{title}, 'T', 'title set correctly');
}

# ─── prepare_edit_requests ────────────────────────────────────────────────

{
    my $requests = Tgph::Publish::prepare_edit_requests(
        [{ path => 'Test-Page-08-18', content => ['a'] }],
    );
    is(scalar @$requests, 1, 'one edit request created');
    is($requests->[0]{method}, 'editPage', 'method is editPage');
    is($requests->[0]{fields}{path}, 'Test-Page-08-18', 'path set correctly');
}

{
    my $requests = Tgph::Publish::prepare_edit_requests(
        [
            { path => 'Page-1', content => ['a'] },
            { path => 'Page-2', content => ['b'] },
        ],
        access_token => 'secret',
    );
    is(scalar @$requests, 2, 'two edit requests created');
    is($requests->[0]{fields}{access_token}, 'secret', 'access_token passed');
    is($requests->[1]{fields}{access_token}, 'secret', 'access_token passed to second');
}

# ─── sanitize_requests ────────────────────────────────────────────────────

{
    my $requests = Tgph::Publish::sanitize_requests([
        { method => 'createPage', fields => { access_token => 'secret', title => 'T' } },
    ]);
    is($requests->[0]{fields}{access_token}, '***', 'access_token masked');
    is($requests->[0]{fields}{title}, 'T', 'other fields preserved');
}

done_testing;
