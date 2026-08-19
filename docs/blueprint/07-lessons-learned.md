# 07 Lessons Learned (bug register)

Format: id / symptom / root cause / fix / prevention.

OPT-TT
    Getopt "Duplicate specification for option t".
    Short aliases t and T collide (case-insensitive shorts).
    Removed the T alias.
    Standard: no case-twin short options (05).

UTF8-TEST
    like() fails on UTF-8 output; Wide character warnings.
    Comparing UTF-8 bytes against character regexes.
    decode('UTF-8', ...) before like().
    Standard: 06 testing rules.

FENCES
    Message and saved file corrupted into garbage.
    Triple backticks inside a fenced block close the outer fence.
    Restored README; banned nested fences.
    Standard: 4-space indented code in docs; never ``` inside blocks.

NODIR
    "cannot create ...: Directory nonexistent".
    cat into a path whose directory does not exist.
    mkdir -p before first write.
    Standard: 05 shell rules.

DEPS
    "Can't locate YAML/PP.pm".
    Proposed a CPAN module against the core-only rule.
    Wrote a dependency-free front matter parser.
    Standard: core modules only (05).

FM-BLANK
    Body kept a leading blank line after front matter.
    Regex consumed only one newline after the closing ---.
    Strip leading newlines from body.
    Regression: Tgph-FrontMatter.t.

PUB-ENC
    Garbage Cyrillic in published URLs; empty page content.
    encode_utf8() then HTTP::Tiny post_form double-encoded fields.
    Pass characters to post_form; drop manual encoding.
    Standard: UTF-8 contract (03, 05).

TRANSLIT-DEAD
    transliterate() returned input unchanged; API slug already clean.
    Telegra.ph transliterates titles itself; helper was dead code.
    Deleted the helper.
    Rule: verify who owns a transformation before implementing it.

XCLIP-STDERR
    Part of block output stayed in the terminal, not the clipboard.
    stderr not redirected when piping to xclip.
    exec 2>&1 as first statement of every block.
    Standard: block format (05).

EX-H1
    examples/article.json failed tgph-validate.
    Examples contained h1/h2, invalid Telegraph tags.
    Rewrote examples with h3/p only.
    Rule: examples must pass the project's own validator.

JOIN-REF
    Test got HASH(0x...) instead of text.
    join '' over page elements that are hash nodes after split v2.
    Node-aware joiner in tests.
    Standard: 06 testing rules.

## yt2tg Extension Lessons Learned

### Iteration 18: SRT Format
- YouTube auto-subtitles are natively VTT/JSON3, not SRT
- Use `yt-dlp --convert-subs srt` (requires ffmpeg) for SRT output
- Single-line TXT improves Gemini's text reconstruction quality

### Iteration 19: Publish Journal
- JSON Lines format is simpler than full JSON for append-only logs
- Journal check prevents duplicate publications
- `--force` flag allows bypassing journal check

### Iteration 20: Pre-checks Order
- User input validation (URL, prompt) must come before environment checks (configs, tools)
- This ensures clear error messages for user errors vs environment errors

### Iteration 24: Subtitle Language Fallback
- YouTube doesn't always provide subtitles with exact language codes
- Use wildcard patterns (`en.*`) for auto-generated and regional variants
- Diagnostic output in stderr helps debug subtitle download issues

### Iteration 25: ID Input
- Accept both URL and 11-character video ID for flexibility
- Pass ID directly to yt-dlp (it accepts both formats)
- Extract ID from URL using regex for consistent handling

### Iteration 27: Debug Output
- Minimal debug output improves user experience
- Only show essential progress (step number, errors)
- Redirect tool stdout to /dev/null when output is not needed


## Iterations 35-46: pipeline hardening (subtitles, UTF-8, Telegram, Telegraph)

### UTF-8 handling
- CLI arguments arrive as raw bytes; explicitly `decode('UTF-8', $arg, FB_CROAK)` before mixing with decoded strings (35)
- Double-encoding symptom: Cyrillic `І` (U+0406) rendered as `Ð` (U+00D0) (35)
- `binmode STDOUT;` without a layer warns "Wide character in print" for Unicode; use `binmode STDOUT, ":encoding(UTF-8)";` (37)
- Telegraph renders HTML comments as visible text — never inject `<!-- ... -->` markers into content (45/46)

### YouTube subtitle language priority
- YouTube auto-captions are generated per **audio track**, not per original video language (dubbed videos!) (36)
- `language` metadata may be a regional variant (`en-US`) while captions exist only for base (`en`); put base BEFORE regional: `en, en-orig, en-US, en-US-orig` (42.6/42.8)
- `automatic_captions` holds ~150 languages in arbitrary order (`keys_unsorted` is NOT priority) — do not use it for priority; rely on `language` + `subtitles` + hardcoded fallback `en, en.*, ru, ru.*, uk, uk.*, all` (42.7)
- Filter non-language keys like `live_chat` (41)
- yt-dlp may exit 0 without creating a file ("no subtitles available") — always verify file existence after download (41)

### JSON parsing pitfalls (Perl + jq)
- Perl hashes are unordered: `sort keys` destroys source order; `JSON::PP->encode` does not preserve order (41/42)
- Naive regex over raw JSON picks up nested track fields (`ext`, `url`, `name`, `video_id`) as "languages" (42)
- Character-by-character JSON parsing in Perl hangs on 100+ KB payloads (42.1)
- `echo "$json" | jq` exceeds ARG_MAX on large payloads; fork and feed jq via stdin instead (42.3)
- Perl `qq{}` interpolates `$"` inside jq regexes (`test("...$")`); build jq filters with `q{}` + concatenation (42.4)

### Shell/Perl escaping and patching
- sed with `|` delimiter breaks when pattern contains `|`; sed `a\`/`c\` text eats backslashes (45)
- In shell double quotes `\$` becomes `$`; to grep a literal `\$` use single quotes or `\\\$` (45.4-45.6)
- perl `-pi -e` replacement side interpolates `$VAR` — escape as `\$VAR` (45.1)
- Prefer full-file heredoc rewrites or perl `\Q\E` over chained sed for multi-hunk patches (45)

### CLI and subprocess design
- `--indent`-style CLI flags for output formatting are an anti-pattern; final design: `Tgph::Diag` module + `PUBTG_INDENT` env var (UNIX way, like NO_COLOR), set once by orchestrator (39 -> 40)
- Each tool prefixes its own diagnostics (`yt2tg-subs:`); data goes to stdout, diagnostics to stderr (39/40)

### Getopt::Long
- Case-insensitive by default: alias `T` collides with `t` ("Duplicate specification") (45)
- Option values in spec must be references (`\$var`); bare `$var` dies with "Undefined argument in option spec" (45.3)

### Telegram API
- `sendMessage` with a YouTube URL triggers auto video preview; use `disable_web_page_preview=true` (43)
- Better: publish thumbnail (480px `mqdefault`) via `sendPhoto` multipart upload with HTML caption — no link preview at all (43)
- Photo caption limit is 1024 chars vs 4096 for messages (43)

### Telegraph / Cocoon AI Summary
- `createPage` API has no parameter to disable AI summaries; unknown params silently ignored (45)
- "Cocoon AI Summary" is generated **by the Telegram client**, not by telegra.ph servers — verified: absent in regular browser, present in Telegram (46)
- Server-side opt-out impossible; it is a client feature (46)

### Process discipline
- Always `git add` every changed file (38: orchestrator fix landed one commit late)
- Keep iteration numbering consistent (42.x chain)
- Unit tests cannot catch real-world API behaviour (HTTP 429, real YouTube JSON shape, client-side rendering) — run real end-to-end checks after each pipeline change (36-46)

### YouTube metadata fields
- YouTube `title` field may contain ASCII-transliterated version for non-Latin scripts (e.g., Cyrillic → Latin)
- YouTube `fulltitle` preserves original characters with accents (é, è, ñ, etc.)
- Always use `fulltitle` with fallback: `$data->{fulltitle} // $data->{title}` (50)
- `strip_emoji` removes only emoji via `\p{Emoji_Presentation}`, preserving accents and punctuation (49)

### Trailing whitespace discipline
- Heredoc-generated files routinely contain trailing spaces on blank lines; `git diff --cached --check` blocks commits on them (49.3, 53.x, 55.x)
- Systemic fix: tracked `githooks/pre-commit` + `core.hooksPath` — hook auto-strips trailing whitespace from staged text files (`grep -qI '[[:blank:]]$'` skips binaries) and re-stages them (56)
- Manual `perl -pi -e 's/[ \t]+$//'` is a one-off patch, not a solution (56)

## Iterations 52-59: bidirectional navigation between Telegraph pages

### Telegraph editPage API
- `editPage` requires `title` parameter (same as `createPage`); omitting it causes API error (57)
- `prepare_edit_requests` must emit `path + title + content` for each edit (57)
- Title format must match `createPage` naming: "Title", "Title (2)", "Title (3)" (57)

### Navigation implementation
- Bidirectional links: "← Частина N" at top (except first page), "Частина N →" at bottom (except last) (53, 55)
- Navigation transformer `tgph-nav` reads `pages.json` + `results.json` (from `tgph-publish --json`) and outputs `edits.json` ready for `tgph-edit` (53)
- `tgph-nav` requires `--title` or `--title-file` to generate per-page titles matching createPage convention (57)
- Single-page articles skip navigation entirely (53)
- `pubtgph` uses two-phase flow: create → nav → edit (55)

### CLI design
- `tgph-edit` mirrors `tgph-publish` interface: reads JSON from file or stdin, `--dry-run` for inspection, `--json` for full results (54)
- Passthrough modes (`--dry-run`, `--json`) in `pubtgph` use `exec` to avoid double-processing (55.1)

### Process discipline
- Shell variable interpolation in perl `-pi -e` requires escaping: `\$VAR` not `$VAR` (57, 58)
- Integration tests must cover real API behavior, not just unit mocks (59)
- End-to-end verification via `getPage?return_content=true` API confirms navigation links are actually rendered (59)

### Verified behavior
- 51KB markdown → 3 pages with working bidirectional navigation (59)
- No self-links: page 1 has "next" only, page N has "prev" only, middle pages have both (53, 59)
- Navigation respects `--no-navigation` flag to opt out (55)



## Iterations 61-67: tgph-delete and Telegraph API limitations

### Telegraph editPage requires non-empty content
- Telegraph API has no delete endpoint; workaround is editPage with minimal content (61)
- Empty array `content=[]` returns `CONTENT_TEXT_REQUIRED` error (66)
- Empty paragraph `{"tag":"p","children":[]}` also returns `CONTENT_TEXT_REQUIRED` (66)
- Minimum valid content: single paragraph with text, e.g., `[{"tag":"p","children":["(deleted)"]}]` (66, 67)
- "Deleted" pages retain their URL but display only "(deleted)" text (67)

### Config parsing must match shell source
- ~/.tgrc values are quoted (e.g., `TP_URL="https://..."`) because the file is sourced by shell — shell strips the quotes automatically (65)
- Custom perl parsers that don't strip quotes produce literal `"https://..."` URL; HTTP::Tiny treats `"https` as hostname → 599 Internal Exception (65)
- Rule: any parser reading shell-style config must strip matching `"..."` and `'...'` quotes (65)

### Secret handling
- Never export tokens to env or pass via argv — visible in `ps` and `/proc` (62.1)
- Perl reads ~/.tgrc directly; CLI `--access-token` for explicit override (62.2, 62.7)
- Tests touching config must run with `HOME=$tempdir` — otherwise real ~/.tgrc turns unit tests into network calls (62.4, 62.7)

### Patching discipline (the 62.x failure chain)
- sed/perl -pi replacements have hostile escaping: perl replacement interpolates $vars; sed replacement expands & to the whole match; shell double quotes eat backslashes (62.2, 62.5)
- Patching by memory fails: always `grep -n` the real line first, build the pattern from fact (62.3)
- Inserted code referencing undeclared vars slips in without a compile gate (62.6)
- **Rule:** no sed/perl -pi for non-trivial edits — full heredoc rewrite; sed only for trivial swaps with immediate `grep -qF` verification (62.7)

### Pre-publish checklist (enforced)
- All variables declared (`my $var`); no "Global symbol requires explicit package name" (62.6)
- `perl -c` on every touched .pm/.t; `sh -n` on every touched shell script
- `grep -qF` after each replacement
- Commit number **strictly equals** iteration number (`Iter.67` for Iteration 67)
- Secrets never in env or argv
- Real E2E test for API changes before claiming feature done (62.7, 67)

### Diagnosis before fix
- Before each fix: `grep -n` the real line, inspect the actual structure
- For API errors: `curl` with the same params the code uses to verify URL/token/SSL independently
- For parsing errors: print intermediate values (input vs expected)
