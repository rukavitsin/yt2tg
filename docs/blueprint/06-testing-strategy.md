# 06 Testing Strategy

## Layout

    tests/unit/         one file per module (Tgph-*.t) and per CLI (tgph-*.t)
    tests/integration/  pipeline.t, orchestrator.t, tgph-md2content.t
    tests/data/         fixtures
    tests/regression/   dedicated regression tests for fixed bugs

## In-block order

    1 perl -Ibin/lib -c each changed file
    2 prove -Ibin/lib -r tests (must pass before commit)
    3 after commit, repeat prove in final state

## Rules

- Every bug fix ships a regression test in the same commit.
- CLI tests execute the real binary and assert exit codes and stdout.
- Exit-code contract under test: 0,1,2,3,4,5,70.
- External tools optional: integration tests skip_all when cmark absent.
- No network inside prove; real API calls only in manual smoke runs,
  gated behind explicit user approval.
- UTF-8: module output is bytes; decode before comparing with
  character regexes in tests.
- When behavior intentionally changes (split v0 -> v2), update the
  stale expectations in the same commit as the feature.
- Node-aware joining in tests: pages may contain element nodes,
  never join '' over refs blindly.

## yt2tg Extension Testing Strategy

The yt2tg extension follows the same testing strategy as the pubtgph foundation, with additional integration tests for the pipeline.

### Test Categories

- Unit tests: Yt2tg modules (Config, Metadata, Gemini, SplitMd, Telegraph, Telegram, Journal)
- CLI tests: yt2tg-meta, yt2tg-subs, yt2tg-gemini, yt2tg-split-md, yt2tg-tg, yt2tg-telegraph, yt2tg-journal
- Integration tests: yt2tg orchestrator (pre-checks, ID input, error handling)

### Test Coverage

685 tests total, all PASS.

Key test areas:
- Metadata extraction and cleaning (emoji removal, timestamp formatting)
- Subtitle download and SRT->TXT conversion (single-line output)
- Gemini API request/response handling
- Markdown section splitting
- Telegraph markdown building (front matter, heading levels, source link)
- Telegram message formatting (HTML parse_mode, bold/italic, links)
- Publish journal (check, append, JSON Lines format)
- Orchestrator pre-checks (URL validation, prompt file, config files)
- ID input parsing (11-char ID, URL extraction)

## Test isolation (added Iter.64)

- Любой тест, касающийся конфигов/токенов/внешних файлов, запускается с `HOME=$tempdir` (пустой tempdir через `File::Temp::tempdir`).
- Реальный `~/.tgrc` пользователя не должен влиять на unit-тесты — иначе тест превращается в сетевой вызов.
- Временные файлы всегда в `tempdir`, никогда в `/tmp` с фиксированными именами (гонки при параллельном запуске).
