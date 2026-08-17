# pubtgph Roadmap

## Status: COMPLETE

All core requirements implemented and tested.

## Completed Features

### Pipeline (all working)

    article.md
      → tgph-md2content (cmark + YAML front matter + html2content)
      → content.json
      → tgph-normalize (h2→h3, cap h4, title from h1)
      → tgph-optimize (remove empty nodes, merge text)
      → tgph-validate (check Telegraph structure)
      → tgph-split (v2: recursive text/pre/list splitting)
      → tgph-link (add "Part X of Y" navigation)
      → tgph-publish (createPage via API)

### Utilities

- tgph-measure: count bytes of raw input
- tgph-limit: check if input fits byte limit
- tgph-validate: validate Telegraph content structure
- tgph-normalize: map headings, extract title from h1
- tgph-optimize: remove empty nodes, merge adjacent text
- tgph-split: split content into pages by byte limit (v2 recursive)
- tgph-link: add page navigation indicator
- tgph-pretty: JSON pretty-print/compact utility
- tgph-publish: publish pages to Telegraph API
- pubtgph: full pipeline orchestrator (POSIX sh)

### Encoding

- UTF-8 handled correctly throughout pipeline
- HTTP::Tiny post_form receives characters (not bytes)
- Telegra.ph API auto-transliterates Cyrillic in URL slugs
- No double-encoding issues

### Testing

- 29 test files, 496 tests, all PASS
- Unit tests for all modules
- Integration tests: pipeline, orchestrator, md2content
- Smoke tests: real publication to api.telegra.ph verified

## Architecture Decisions

1. Modular pipeline: each utility does one thing, pipes to next
2. Byte-based limits: Telegraph API limit is 64KB per page, we use 24KB default
3. Recursive splitting: oversized text nodes, lists, and elements are split recursively
4. POSIX sh orchestrator: minimal dependencies, dash-compatible
5. Core Perl modules: JSON::PP, Encode, HTTP::Tiny, Getopt::Long (no XS dependencies)

## Known Limitations

- No API for editing existing pages (editPage not implemented)
- No API for listing/deleting pages
- No rate limiting logic (user must implement if needed)
- cmark must be installed externally for markdown conversion

## yt2tg Extension

The yt2tg extension adds YouTube video processing capabilities to the pubtgph foundation.
See [YT2TG_ROADMAP.md](YT2TG_ROADMAP.md) for the complete yt2tg roadmap.
