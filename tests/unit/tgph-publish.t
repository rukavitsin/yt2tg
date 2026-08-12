use v5.36;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use Test::More;
use JSON::PP ();

my $script = "$Bin/../../bin/tgph-publish";

sub run_stdin {
    my ($input, @args) = @_;

    my $command = sprintf(
        'printf %%s %s | %s %s 2>&1',
        quotemeta($input),
        quotemeta($script),
        join(' ', map { quotemeta($_) } @args),
    );

    my $output = `$command`;
    my $status = $? >> 8;

    return ($status, $output);
}

sub run_command {
    my (@command) = @_;

    my $output = qx{@command 2>&1};
    my $status = $? >> 8;

    return ($status, $output);
}

{
    my ($status, $output) = run_stdin('[]');

    is($status, 0, 'empty input exits OK');
    is($output, '', 'empty input produces no output');
}

{
    my ($status, $output) = run_stdin('[]', '--dry-run');

    is($status, 0, 'empty dry-run exits OK');
    is($output, '[]', 'empty dry-run outputs empty JSON array');
}

{
    my ($status, $output) = run_stdin('["a"]', '--dry-run');

    is($status, 1, 'missing title exits USAGE');
    like($output, qr/--title/, 'missing title reports an error');
}

{
    my ($status, $output) =
        run_stdin('["a"]', '--dry-run', '--title', 'T');

    is($status, 0, 'dry-run with title exits OK');

    my $data = eval { JSON::PP::decode_json($output) };
    is($@, '', 'dry-run output is valid JSON');

    is_deeply(
        $data,
        [
            {
                method => 'createPage',
                fields => {
                    title   => 'T',
                    content => '["a"]',
                },
            },
        ],
        'single page request is prepared',
    );
}

{
    my ($status, $output) =
        run_stdin('[["a"],["b"]]', '--dry-run', '--title', 'T');

    is($status, 0, 'pages dry-run exits OK');

    my $data = eval { JSON::PP::decode_json($output) };
    is($@, '', 'pages dry-run output is valid JSON');

    is(scalar @$data, 2, 'two requests are prepared');

    is($data->[0]{fields}{title}, 'T', 'first page title is correct');
    is($data->[1]{fields}{title}, 'T (2)', 'second page title is correct');

    is($data->[0]{fields}{content}, '["a"]', 'first page content is correct');
    is($data->[1]{fields}{content}, '["b"]', 'second page content is correct');
}

{
    my ($fh, $file) = tempfile();
    binmode $fh, ':raw';
    print {$fh} "My Title\n";
    close $fh;

    my ($status, $output) =
        run_stdin('["a"]', '--dry-run', '--title-file', $file);

    is($status, 0, 'title-file dry-run exits OK');

    my $data = eval { JSON::PP::decode_json($output) };
    is($@, '', 'title-file dry-run output is valid JSON');

    is(
        $data->[0]{fields}{title},
        'My Title',
        'title is read from file and trailing newline is removed',
    );

    unlink $file;
}

{
    my ($status, $output) = run_stdin(
        '["a"]',
        '--dry-run',
        '--title', 'T',
        '--title-file', '/tmp/whatever',
    );

    is($status, 1, 'both title options exit USAGE');
    like($output, qr/only one/, 'both title options report an error');
}

{
    my ($status, $output) = run_stdin(
        '["a"]',
        '--dry-run',
        '--title', 'T',
        '--access-token', 'secret',
    );

    is($status, 0, 'dry-run with access token exits OK');

    my $data = eval { JSON::PP::decode_json($output) };
    is($@, '', 'token dry-run output is valid JSON');

    is(
        $data->[0]{fields}{access_token},
        '***',
        'access token is masked in dry-run output',
    );
}

{
    my ($status, $output) = run_stdin('not-json', '--dry-run', '--title', 'T');

    is($status, 2, 'invalid JSON exits INPUT');
    like($output, qr/invalid JSON/, 'invalid JSON reports an error');
}

{
    my ($status, $output) = run_stdin(
        '[{"tag":"div","children":[]}]',
        '--dry-run',
        '--title', 'T',
    );

    is($status, 4, 'invalid Telegraph content exits VALIDATION');
    like($output, qr/tag 'div' is not allowed/, 'invalid tag reports an error');
}

{
    my ($status, $output) = run_stdin('{}', '--dry-run', '--title', 'T');

    is($status, 4, 'non-array root exits VALIDATION');
    like($output, qr/JSON array/, 'non-array root reports an error');
}

{
    my ($status, $output) =
        run_command("'$script' '/definitely/nonexistent/file' --dry-run --title T");

    is($status, 2, 'missing file exits INPUT');
    like($output, qr/cannot open/, 'missing file reports open error');
}

{
    my ($fh, $file) = tempfile();
    binmode $fh, ':raw';
    print {$fh} '[]';
    close $fh;

    my ($status, $output) =
        run_command("'$script' '$file' '$file' --dry-run");

    is($status, 1, 'multiple files exit USAGE');

    unlink $file;
}

{
    my ($status, $output) = run_command("'$script' --help");

    is($status, 0, '--help exits OK');
    like($output, qr/^Usage: tgph-publish/m, '--help reports usage');
}

{
    my ($status, $output) = run_command("'$script' --version");

    is($status, 0, '--version exits OK');
    is($output, "0.0.1\n", '--version reports current version');
}

done_testing;
