# yt2tg Roadmap

## Current Status

All core functionality implemented and tested (685 tests PASS).

## Completed Milestones

### Phase 1: Foundation (Iterations 1-12)
- Config, Constants, Metadata modules
- yt-dlp tools (yt2tg-meta, yt2tg-subs)
- Gemini API client
- Markdown section splitter
- Telegram publisher
- Telegraph markdown builder
- Orchestrator (POSIX sh)
- Makefile, prompt.md, docs

### Phase 2: Robustness (Iterations 13-24)
- Step progress output
- --output-file option
- Subtitle language fallback
- SRT format via ffmpeg
- Publish journal
- Pre-checks, intermediate checks, post-checks
- Wildcard fallback, diagnostic, --lang

### Phase 3: Refinement (Iterations 25-32)
- ID input, pass ID to yt-dlp
- XDG_RUNTIME_DIR for temp
- Reduce debug output
- Link format (youtu.be, Telegraph source)
- Blueprint docs updates

## Planned Improvements

### Priority 1: Real Pipeline Testing
- Test on real YouTube URL/ID with actual API calls
- Verify end-to-end flow with real Gemini/Telegram/Telegraph APIs
- Handle edge cases (no subtitles, private videos, etc.)

### Priority 2: Error Handling with Retry
- Handle transient API errors (HTTP 429, timeouts) gracefully
- Implement exponential backoff for retries
- Add --retry-count option

### Priority 3: Playlist Support
- Process multiple videos in a playlist sequentially
- Add --playlist option
- Batch journal updates

### Priority 4: Alternative LLM Providers
- Support other LLM providers (OpenAI, Anthropic, local models)
- Pluggable adapter interface
- Add --llm-provider option

## Dependencies

- yt-dlp: metadata and subtitle extraction
- ffmpeg: subtitle format conversion
- cmark: markdown to HTML conversion
- Gemini API: text processing
- Telegram Bot API: message publishing
- Telegraph API: article publishing
