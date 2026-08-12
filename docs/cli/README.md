# CLI Reference

Common conventions:

- read STDIN or a single FILE argument
- data on STDOUT, diagnostics on STDERR
- -h/--help, -V/--version, -n/--dry-run where applicable
- exit codes: 0 OK, 1 USAGE, 2 INPUT, 3 OUTPUT,
  4 VALIDATION, 5 API, 70 INTERNAL

## tgph-measure

    tgph-measure [FILE]

Print the byte count of raw input.

## tgph-limit

    tgph-limit --max-bytes N [--json] [FILE]

Predicate: exit 0 if input fits N bytes, else 4.
--json prints a machine-readable verdict.

## tgph-validate

    tgph-validate [FILE]

Validate Telegraph content structure; exit 0 or 4.

## tgph-normalize

    tgph-normalize [--title-out FILE] [FILE]

Map h1 to title (extracted to FILE when given), h2 to h3, h3+ to h4.

## tgph-optimize

    tgph-optimize [FILE]

Drop empty nodes, merge adjacent text nodes. Idempotent.

## tgph-split

    tgph-split --max-bytes N [--output-dir DIR] [FILE]

Greedy page packing under N bytes; recursive splitting of oversized
text, lists and elements. Prints the pages array, or the page count
when --output-dir is used (pages written as pageNNN.json).

## tgph-link

    tgph-link [FILE]

Add Part X of Y navigation to multi-page output; single page passes
through unchanged.

## tgph-pretty

    tgph-pretty [-c|--compact] [FILE]

Pretty-print JSON by default; --compact emits canonical JSON.

## tgph-publish

    tgph-publish (--title T | --title-file F) [OPTIONS] [FILE]

Options: -t/--title, -T/--title-file, -a/--author-name,
-u/--author-url, --access-token (or TGPH_ACCESS_TOKEN), --api-url,
--timeout, -n/--dry-run, -j/--json, -V/--version.
Default output: one page URL per line. Dry-run prints prepared
requests with the token masked as ***.

## tgph-md2content

    tgph-md2content [--title-out FILE] [FILE]

Markdown to content.json via cmark. YAML front matter title is
written to FILE and the leading h1 removed; without front matter the
h1 stays for tgph-normalize.

## pubtgph

    pubtgph [OPTIONS] ARTICLE_MD

Full pipeline orchestrator (POSIX sh).
Options: -t/--title, -m/--max-bytes, -a/--author-name,
-u/--author-url, --access-token, --api-url, -n/--dry-run, -j/--json, -V/--version.
Title fallback: front matter -> h1 -> --title -> file name.
Config: ~/.tgrc (TP_TOKEN, TP_URL); CLI overrides config.
