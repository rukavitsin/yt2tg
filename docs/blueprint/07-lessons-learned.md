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
