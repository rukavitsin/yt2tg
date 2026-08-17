# 03 Architecture

## Principle

Bash orchestrates. Perl processes data. Each utility does one thing,
reads STDIN or a file, writes STDOUT, and returns a documented exit code.

## Pipeline

    article.md
      |  tgph-md2content   front matter + cmark + html2content
      |  tgph-normalize    h1->title, h2->h3, h3+->h4
      |  tgph-optimize     drop empty nodes, merge adjacent text
      |  tgph-validate     check Telegraph tag structure
      |  tgph-split        greedy pages + recursive oversized splitting
      |  tgph-link         add Part X of Y navigation
      |  tgph-publish      createPage via HTTP::Tiny

    pubtgph   POSIX sh orchestrator over the whole chain

## Data format

content.json = array of nodes.
node = scalar (text) or object { tag, children?, attrs? }.
attrs whitelisted: a->href, img->src.
Interchange is canonical JSON: sorted keys, UTF-8 bytes on the wire.

## Module decomposition (bin/lib/Tgph)

    ExitCodes  constants for the exit-code contract
    CLI        Getopt::Long wrapper, help/version/dry-run
    IO         raw byte read/write
    JSON       canonical encode/decode/bytes
    Content    node tree helpers
    Node       single-node predicates
    Validate   structural + tag whitelist validation
    Limit      byte-limit predicate
    Normalize  heading mapping + title extraction
    Split      page packing + recursive splitting (v2)
    Link       navigation indicator
    Optimize   empty-node removal + text merging
    Pretty     pretty/compact JSON
    Publish    request build + HTTP send
    FrontMatter  dependency-free YAML front matter parse
    HTML2Content cmark HTML -> content nodes
    Markdown   front matter + cmark + html2content assembly

## Exit codes

    0 OK   1 USAGE   2 INPUT   3 OUTPUT   4 VALIDATION   5 API   70 INTERNAL

## Encoding contract

Decode UTF-8 on input, encode on output, never double-encode.
HTTP::Tiny post_form receives characters, not pre-encoded bytes.
Telegra.ph auto-transliterates Cyrillic in URL slugs.

## yt2tg Extension Architecture

The yt2tg extension is built as a wrapper over the pubtgph foundation, adding YouTube video processing capabilities.

### Component Diagram

    bin/yt2tg          POSIX sh orchestrator
    bin/yt2tg-meta     Metadata extraction (yt-dlp)
    bin/yt2tg-subs     Subtitle download + SRT->TXT conversion
    bin/yt2tg-gemini   Gemini API client
    bin/yt2tg-split-md Markdown section splitter
    bin/yt2tg-telegraph Telegraph markdown builder
    bin/yt2tg-tg       Telegram publisher
    bin/yt2tg-journal  Publish journal manager

    bin/lib/Yt2tg/Config.pm     Config reader (~/.tgrc, ~/.geminirc)
    bin/lib/Yt2tg/Metadata.pm   Metadata cleaning and formatting
    bin/lib/Yt2tg/Gemini.pm     Gemini API client module
    bin/lib/Yt2tg/SplitMd.pm    Markdown splitter module
    bin/lib/Yt2tg/Telegraph.pm  Telegraph markdown builder module
    bin/lib/Yt2tg/Telegram.pm   Telegram message formatter module
    bin/lib/Yt2tg/Journal.pm    Publish journal module

### Data Flow

1. yt2tg-meta: URL/ID -> metadata JSON
2. yt2tg-subs: ID -> SRT -> single-line TXT
3. yt2tg-gemini: TXT + prompt -> markdown response
4. yt2tg-split-md: markdown -> section1.md + section234.md
5. yt2tg-telegraph: metadata + section234 -> Telegraph markdown
6. pubtgph: Telegraph markdown -> Telegraph URL
7. yt2tg-tg: metadata + section1 + Telegraph URL -> Telegram message
