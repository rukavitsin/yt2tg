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
