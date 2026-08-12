# pubtgph

UNIX toolkit for publishing articles to Telegra.ph.

Bash orchestrates. Perl processes data.

## Requirements

- Perl >= 5.36
- Core modules only (JSON::PP, Encode, HTTP::Tiny, Getopt::Long)
- cmark (for markdown conversion)
- For HTTPS publishing: IO::Socket::SSL

## Quick Start

    # Publish markdown article (reads ~/.tgrc for TP_TOKEN)
    bin/pubtgph examples/article.md

    # Dry run (see what would be published)
    bin/pubtgph --dry-run examples/article.md

## Pipeline

    article.md
      |  tgph-md2content   (YAML front matter + cmark + html2content)
      |  tgph-normalize    (h1->title, h2->h3, h3+->h4)
      |  tgph-optimize     (remove empty nodes, merge text)
      |  tgph-validate     (check Telegraph tag structure)
      |  tgph-split        (split into pages <= max-bytes)
      |  tgph-link         (add "Part X of Y" navigation)
      |  tgph-publish      (createPage via Telegraph API)

## Utilities

    tgph-measure            count bytes of raw input
    tgph-limit              check if input fits byte limit
    tgph-validate           validate Telegraph content structure
    tgph-normalize          map headings, extract title from h1
    tgph-optimize           remove empty nodes, merge adjacent text
    tgph-split              split content into pages by byte limit
    tgph-link               add page navigation (Part X of Y)
    tgph-pretty             pretty-print or compact JSON
    tgph-publish            publish pages to Telegraph API
    pubtgph    full pipeline orchestrator
    tgph-md2content         convert markdown to Telegraph content.json

## Markdown Format

    ---
    title: My Article
    author: John Doe
    date: 2026-01-15
    url: https://example.com/source
    ---

    # My Article

    Introduction paragraph.

    ## Section One

    Content with **bold** and *italic* text.

    - List item 1
    - List item 2

YAML front matter is optional. If present, title is used as page title and leading h1 is removed. If absent, first h1 becomes title.

## Configuration

Create ~/.tgrc:

    TP_TOKEN="your_telegraph_access_token"
    TP_URL="https://api.telegra.ph"

## UTF-8 Handling

- All utilities handle UTF-8 correctly
- HTTP::Tiny receives characters (not pre-encoded bytes)
- Telegra.ph API auto-transliterates Cyrillic to Latin in URL slugs
- No double-encoding issues

## Oversized Content

Long articles are automatically split:

- Default page limit: 24000 bytes (Telegraph API limit is 65536)
- Recursive splitting for oversized text nodes, lists, and elements
- Navigation indicators added to multi-page articles

## Exit Codes

    0   OK
    1   USAGE       invalid CLI invocation
    2   INPUT       malformed/unreadable input
    3   OUTPUT      write failure
    4   VALIDATION  invalid structure or over limit
    5   API         Telegraph API error
    70  INTERNAL    unexpected error

## Examples

See examples/ directory for sample content.json files.

## Testing

    make test

All 496 tests pass (29 test files).

## License

MIT
