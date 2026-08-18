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

### Iteration 35: UTF-8 Double Encoding in Telegram
- Shell arguments with UTF-8 characters arrive as raw bytes, not decoded strings
- `decode('UTF-8', $arg)` must be called explicitly before concatenation with decoded strings
- Symptom: Cyrillic `І` (U+0406) becomes `Ð` (U+00D0) — first byte of UTF-8 sequence interpreted as Latin-1

### Iteration 36: Dubbed-Auto Videos Language Priority
- YouTube generates auto-captions for the **audio track**, not the original video language
- Dubbed videos have auto-captions on the dub language, not original
- Solution: add `language` + `language-orig` to priority list, limit auto-captions to first 5

### Iteration 37: Wide Character in Print in tgph-publish
- `binmode STDOUT;` without encoding layer causes "Wide character in print" warnings
- Fix: use `binmode STDOUT, ":encoding(UTF-8)";`

### Iteration 39: Formatting is each process's responsibility
- Do not use `--indent` flags or `PUBTG_INDENT` env vars to format child process stderr
- Each tool formats its own output with its own prefix (e.g., `yt2tg-subs:`)
- Orchestrator formats its own messages; child stderr passes through unchanged

### Iteration 41: Preserve YouTube Language Order
- `sort keys %$hash` destroys YouTube's priority order for subtitle languages
- JSON already provides keys in priority order — preserve insertion order
- `live_chat` and similar non-language keys appear in `automatic_captions` — must be filtered
- yt-dlp can exit 0 without creating a file ("no subtitles available") — must check file existence

### Iteration 42: Proper Top-Level JSON Key Extraction
- `JSON::PP->new->encode($hash)` does NOT preserve key order (Perl hashes are unordered)
- Regex `/"([^"]+)"\s*:/g` on raw JSON extracts ALL keys, including nested ones inside track objects
- Fields like `video_id`, `ext`, `protocol`, `url`, `name` are **track properties**, not languages
- Solution: track brace/bracket depth when parsing raw JSON to extract only top-level keys
- Filter known non-language keys (`live_chat`) explicitly
