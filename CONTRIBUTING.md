# Contributing

## Before you start

- Read docs/blueprint/README.md: roles, protocol, standards.
- Editor follows .editorconfig: UTF-8, LF, final newline, trimmed
  trailing whitespace, 4-space indent, tabs in Makefile.

## Workflow

1. One logical change per commit.
2. Develop via iteration blocks (docs/development/STYLE.md): fixed
   block format, exec 2>&1, set -eu, syntax checks, full suite,
   explicit git add, final green state.
3. Every bug fix ships a regression test in the same commit.
4. Never commit on a red suite; never rewrite history.
5. Real side effects (network publish) require explicit user GO.

## Run tests

    make test

## Standards

- Shell: POSIX sh (dash), minimal forks, DRY; see
  docs/development/STYLE.md.
- Perl: v5.36, core modules only; bin/ are thin wrappers,
  bin/lib/ owns the logic.
- Docs: 4-space indented code; never nest triple backticks inside
  blocks or heredocs.

## Commit messages

    type(scope): subject

Types: feat, fix, refactor, test, docs, build.

## Reporting bugs

Include a minimal reproduction and, when possible, a failing test.

## License

MIT, see LICENSE. By contributing you agree to it.
