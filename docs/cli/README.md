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

## yt2tg

    yt2tg [OPTIONS] YOUTUBE_URL

Full pipeline orchestrator (POSIX sh): YouTube -> Gemini -> Telegraph -> Telegram.

Options: -h/--help, -V/--version, -p/--prompt FILE (default: prompt.md).

Pipeline steps:
1. yt2tg-meta: extract metadata via yt-dlp
2. yt2tg-subs: download and clean subtitles via yt-dlp
3. yt2tg-gemini: send transcript + prompt to Gemini API
4. yt2tg-split-md: split response into section1 / section234
5. yt2tg-telegraph: build Telegraph markdown
6. pubtgph: publish to Telegraph, get URL
7. yt2tg-tg: publish section 1 + URL to Telegram

Config: ~/.tgrc (TG_TOKEN, TG_CHAT_ID, TP_TOKEN, TG_URL, TP_URL),
~/.geminirc (GEMINI_API_KEY, URL_GEMINI).

## yt2tg-meta

    yt2tg-meta URL

Extracts YouTube metadata (title, channel, date, video_id) via yt-dlp.
Outputs JSON with fields: video_id, title, channel, date, date_short,
url, title_fn, channel_fn.

## yt2tg-subs

    yt2tg-subs [OPTIONS] URL

Downloads and cleans YouTube subtitles via yt-dlp.
Options: -o/--output-dir DIR (default: srt).
Outputs path to the cleaned transcript file.

## yt2tg-gemini

    yt2tg-gemini [OPTIONS]

Sends transcript with prompt to Gemini API, prints markdown response.
Options: -p/--prompt-file FILE, -t/--transcript-file FILE,
-o/--output FILE, -n/--dry-run.

## yt2tg-split-md

    yt2tg-split-md --out-dir DIR [FILE]

Splits Gemini markdown response into section1.md and section234.md
by ### 1. and ### 2. headings.

## yt2tg-tg

    yt2tg-tg [OPTIONS]

Publishes section 1 and Telegraph link to Telegram.
Options: -m/--meta FILE, -s/--section1 FILE, -u/--telegraph-url URL,
-n/--dry-run.

Message format (HTML parse_mode):
- Title: bold
- Channel: plain
- Date: italic
- Source URL: linked
- Section 1 body
- Telegraph URL: linked

## yt2tg-telegraph

    yt2tg-telegraph [OPTIONS]

Builds Telegraph markdown from metadata and sections 2-4.
Options: -m/--meta FILE, -s/--section234 FILE.
Outputs markdown to stdout for pubtgph.

## yt2tg-journal

    yt2tg-journal <check|append> [OPTIONS]

Manages the publish journal (publish_log.jsonl).

Commands:
- check: Check if video_id was successfully published (exit 0 + URL, or 1)
- append: Append a JSON record to the journal

Options: -h/--help, -V/--version, -j/--journal FILE, --video-id ID, -r/--record JSON.

Default journal file: publish_log.jsonl next to the binary.

## yt2tg pipeline checks

The yt2tg orchestrator performs checks at multiple stages:

Pre-checks (before pipeline):
- P1: yt-dlp in PATH
- P2: cmark in PATH
- P3/P4: ~/.tgrc and ~/.geminirc exist
- P5: prompt file exists and is not empty
- P6: URL is a valid YouTube URL
- P7: video_id not already in publish journal (use --force to override)

Intermediate checks (between steps):
- C1: metadata fields extracted (video_id, date_short, channel_fn, title_fn)
- C2: transcript file not empty
- C3: Gemini response contains ### 1. and ### 2. headings
- C4: section1.md and section234.md not empty
- C5: Telegraph URL starts with https://telegra.ph/
- C6: Telegram returned message_id

Post-checks (after pipeline):
- F1: artifacts (transcript.txt, response.md) exist
- F2: journal record appended

## yt2tg artifact storage

Artifacts (srt/, md/) are stored in $XDG_DATA_HOME/pubtg/ (default: ~/.local/share/pubtg/).

File naming: date--ID--channel_fn--title_fn.ext

## yt2tg-subs update (Iteration 18)

yt2tg-subs now downloads subtitles as SRT via yt-dlp --convert-subs srt (requires ffmpeg).
The SRT is converted to a single-line TXT for Gemini processing.
Both .srt and .txt files are saved to the srt/ directory.
