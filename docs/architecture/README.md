# Architecture

Principle: sh orchestrates; Perl processes data.
Each utility does one thing, reads STDIN or FILE, writes STDOUT.

## Pipeline

    article.md
      |  tgph-md2content    front matter + cmark + html2content
      |  tgph-normalize     h1->title, h2->h3, h3+->h4
      |  tgph-optimize      drop empty nodes, merge text
      |  tgph-validate      Telegraph tag whitelist
      |  tgph-split         greedy pages + recursive splitting
      |  tgph-link          Part X of Y navigation
      |  tgph-publish       createPage via HTTP::Tiny

    pubtgph   POSIX sh orchestrator over the chain

## Data format

content.json is an array of nodes.
node = text scalar, or object with tag, optional children, optional
attrs. attrs whitelist: a->href, img->src.
Interchange is canonical JSON: sorted keys, UTF-8 bytes on the wire.

## Layout

    bin/tgph-*          executables, thin CLI wrappers
    bin/lib/Tgph/*.pm   all logic (19 modules)
    tests/unit          per-module and per-CLI tests
    tests/integration   pipeline, orchestrator, md2content

Modules ride inside bin/lib so installation is a single-directory
copy and executables stay version-locked with their logic.

## Exit codes

    0 OK  1 USAGE  2 INPUT  3 OUTPUT  4 VALIDATION  5 API  70 INTERNAL

## Encoding contract

Decode UTF-8 on input, encode on output, never double-encode.
HTTP::Tiny post_form receives characters, not pre-encoded bytes.

Full reference: docs/blueprint/03-architecture.md and
docs/blueprint/08-reference-manifest.md.

## yt2tg Extension Pipeline

yt2tg is a wrapper over pubtgph for YouTube video processing.

    YOUTUBE_URL
      |  yt2tg-meta       yt-dlp metadata extraction (JSON)
      |  yt2tg-subs       yt-dlp subtitle download + VTT cleaning
      |  yt2tg-gemini     Gemini API: transcript + prompt -> markdown
      |  yt2tg-split-md   split markdown into section1 / section234
      |  yt2tg-telegraph  build Telegraph markdown (front matter + h2/h3)
      |  pubtgph          publish sections 2-4 to Telegraph
      |  yt2tg-tg         publish section 1 + Telegraph URL to Telegram
    yt2tg   POSIX sh orchestrator over the chain

### Data flow

- srt/ directory: cleaned transcripts
- md/ directory: Gemini markdown responses
- File naming: date--ID--channel_fn--title_fn.ext

### Config files

- ~/.tgrc: TG_TOKEN, TG_CHAT_ID, TP_TOKEN, TG_URL, TP_URL
- ~/.geminirc: GEMINI_API_KEY, URL_GEMINI

### Modules (bin/lib/Yt2tg)

Config     read ~/.tgrc and ~/.geminirc
Metadata   emoji cleaning, timestamp formatting, filename processing
Gemini     Gemini API client (build_request, parse_response, send_request)
SplitMd    split markdown by section headings
Telegram   Telegram message formatting and sending (HTML parse_mode)
Telegraph  Telegraph markdown builder (front matter + heading levels)
