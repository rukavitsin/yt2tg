# pubtgph Testing Guide

## Order inside an iteration block

1. perl -Ibin/lib -c for every changed module, bin script and test file.
2. prove -Ibin/lib -r tests — full suite must be green before commit.
3. After commit, repeat prove in the final state section to confirm the committed tree is green.

## Suite layout

- tests/unit/        one file per module and per CLI (Tgph-*.t, tgph-*.t)
- tests/integration/ pipeline.t, orchestrator.t, tgph-md2content.t
- tests/data/        fixtures
- tests/regression/  regression tests for fixed bugs

## Rules

- Every bug fix ships with a regression test.
- CLI tests run the real binary and check exit codes.
- Exit codes: 0 OK, 1 USAGE, 2 INPUT, 3 OUTPUT, 4 VALIDATION, 5 API, 70 INTERNAL.
- External tools (cmark) are optional: integration tests skip when absent.
- No network inside prove; real API calls only in manual smoke runs.
- UTF-8 assertions: decode module output before comparing with character regexes.

## Applicability to yt2tg Extension

The testing guidelines defined in this document apply to the yt2tg extension.
Additional yt2tg-specific testing rules:
- No network calls in tests (mock yt-dlp, Gemini API, Telegram API, Telegraph API)
- Integration tests use temp directories for artifacts
- All tests must pass with `prove -Ibin/lib -r tests`
