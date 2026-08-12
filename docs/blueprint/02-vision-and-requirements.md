# 02 Vision and Requirements

## Problem

Publishing ordinary markdown articles to Telegra.ph fails with
CONTENT_TOO_BIG when the article exceeds the per-page API limit.
The legacy shell script was unmaintainable; only its API URL was useful.

## Goal

A UNIX toolkit that takes a markdown file and publishes it to Telegra.ph,
splitting oversized content into linked pages automatically.

## Functional requirements

- FR1 convert markdown to Telegraph content.json (via cmark + front matter).
- FR2 extract title with fallback: front matter -> h1 -> CLI -> file name.
- FR3 normalize headings to the Telegraph set (h2->h3, cap h4, h1->title).
- FR4 validate content structure against the Telegraph tag whitelist.
- FR5 split content into pages under a byte budget; recursively split
      oversized text, lists, and elements; never lose data.
- FR6 add Part X of Y navigation to multi-page articles.
- FR7 publish via createPage; support dry-run; read token from ~/.tgrc.
- FR8 pretty/compact JSON and byte measurement utilities.

## Non-functional requirements

- NFR1 POSIX sh (dash) orchestration; no bashisms; minimal forks.
- NFR2 Perl core modules only (JSON::PP, Encode, HTTP::Tiny, Getopt::Long).
- NFR3 canonical JSON (sorted keys, UTF-8) as the data interchange format.
- NFR4 stable exit-code contract for scripting.
- NFR5 every bug fix ships a regression test; suite green each commit.
- NFR6 no network inside automated tests; smoke runs are manual.

## Out of scope

- editPage / list / delete / stats API calls.
- rate limiting and concurrency control.
- bundling cmark (external dependency).
