# 9. yt2tg Extension

**Purpose:** Define the YouTube-to-Telegram/Telegraph publishing pipeline as an extension over the pubtgph foundation.
**Status:** Implemented. All core functionality tested (685 tests PASS).

## Overview

yt2tg is a wrapper over pubtgph that processes YouTube videos:

1. Extract metadata via yt-dlp
2. Download and clean subtitles (SRT -> single-line TXT)
3. Send transcript + prompt to Gemini LLM
4. Split markdown response into sections
5. Publish sections 2-4 to Telegraph
6. Publish section 1 + Telegraph URL to Telegram

## Pipeline Steps

| Step | Tool | Description |
|---|---|---|
| 1/7 | yt2tg-meta | Extract metadata (title, channel, date, video_id) |
| 2/7 | yt2tg-subs | Download subtitles as SRT, convert to single-line TXT |
| 3/7 | yt2tg-gemini | Send transcript + prompt to Gemini API |
| 4/7 | yt2tg-split-md | Split response into section1 / section234 |
| 5/7 | yt2tg-telegraph | Build Telegraph markdown with front matter |
| 6/7 | pubtgph | Publish sections 2-4 to Telegraph, get URL |
| 7/7 | yt2tg-tg | Publish section 1 + Telegraph URL to Telegram |

## Input

The orchestrator `yt2tg` accepts either:
- Full YouTube URL (e.g., `https://www.youtube.com/watch?v=ID`, `https://youtu.be/ID`)
- 11-character video ID directly (e.g., `dQw4w9WgXcQ`)

## Checks

### Pre-checks (P1-P7)
- P1: yt-dlp in PATH
- P2: cmark in PATH
- P3/P4: ~/.tgrc and ~/.geminirc exist
- P5: prompt file exists and is not empty
- P6: URL is a valid YouTube URL or 11-char ID
- P7: video_id not already in publish journal (use --force to override)

### Intermediate checks (C1-C6)
- C1: metadata fields extracted (video_id, date_short, channel_fn, title_fn)
- C2: transcript file not empty
- C3: Gemini response contains ### 1. and ### 2. headings
- C4: section1.md and section234.md not empty
- C5: Telegraph URL starts with https://telegra.ph/
- C6: Telegram returned message_id

### Post-checks (F1-F2)
- F1: artifacts (transcript.txt, response.md) exist
- F2: journal record appended

## Publish Journal

Location: `bin/publish_log.jsonl` (next to the orchestrator).
Format: JSON Lines (one JSON object per line).
Fields: video_id, date_short, title, channel, telegraph_url, telegram_message_id, published_at, status.

Before running the pipeline, yt2tg checks if video_id is already in the journal.
Use `--force` to bypass this check.

## Artifact Storage

Artifacts (srt/, md/) are stored in `$XDG_DATA_HOME/pubtg/` (default: `~/.local/share/pubtg/`).
Temp workspace: `$XDG_RUNTIME_DIR/yt2tg.XXXXXX` (fallback `/tmp`).
File naming: `date--ID--channel_fn--title_fn.ext`

## Link Format

- Telegram message: `Джерело: http://youtu.be/ID` (short link)
- Telegraph article: source link between date and section 2 heading

## Configuration

- `~/.tgrc` — Telegram/Telegraph tokens (TG_TOKEN, TG_CHAT_ID, TP_TOKEN)
- `~/.geminirc` — Gemini API key and URL (GEMINI_API_KEY, URL_GEMINI)
- `prompt.md` — prompt for Gemini (reference included in project root)

## Current Status

All core functionality implemented and tested.

## Future Actions

1. **Real pipeline testing** — test on real YouTube URL/ID with actual API calls
2. **Error handling with retry** — handle transient API errors (HTTP 429, timeouts) gracefully with exponential backoff
3. **Playlist support** — process multiple videos in a playlist sequentially
4. **Alternative LLMs** — support other LLM providers (OpenAI, Anthropic, local models) via a pluggable adapter interface
