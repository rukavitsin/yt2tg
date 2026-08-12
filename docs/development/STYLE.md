# pubtgph Style Guide

## Iteration block format (fixed)

Every iteration block follows this exact structure:

    # run: sh ../cmd-<N> 2>&1 | xclip -selection clipboard -i
    exec 2>&1
    set -eu

    echo '=== Iteration <N>: <title> ==='

    # 1. file changes (cat > file << 'MARKER' ... MARKER)
    # 2. syntax checks (perl -Ibin/lib -c <each changed file>)
    # 3. full test suite (prove -Ibin/lib -r tests)
    # 4. git status before commit
    # 5. git add <explicit file list>
    # 6. git diff --cached --check
    # 7. git commit -m "<type>(<scope>): <subject>"
    # 8. final state (git log --oneline -n 3, git status, prove)

Rules:

- exec 2>&1 first: all output goes to stdout, so the xclip pipe captures everything.
- set -eu: stop on first error, never leave half-done state.
- POSIX sh (dash) only. No bashisms: no [[ ]], no arrays, no BASH_SOURCE, no pipefail.
- Quoted heredoc markers (<< 'MARKER') to prevent expansion.
- NEVER put triple backticks inside a block (lesson of 1.28: nested fences corrupt the message and the saved file).
- Sections delimited by echo '=== ... ==='.
- Explicit file list in git add (git add -A only for renames/deletes).
- One commit = one logical change.
- Block must end green: final prove passes, working tree clean.

## Shell scripts (project artifacts)

- Shebang #!/bin/sh, dash-compatible.
- Minimal forks: prefer builtins (printf, case, ${var%%...}, ${var##...}).
- while IFS= read -r with redirection at done < file.
- No expr; use $(( )).
- case instead of grep for pattern checks.
- set -- / shift for list management.
- Constants at top (single source of truth).
- die() and usage() as single edit points; exit codes passed as function argument.
- DRY: same logic or message must exist in exactly one place; but do not extract a function used once without readability gain.

## Perl

- use v5.36; use strict; use warnings;
- Core modules only: JSON::PP, Encode, HTTP::Tiny, Getopt::Long, IPC::Open2.
- bin/lib/ holds logic; bin/ scripts are thin CLI wrappers.
- Exit codes from Tgph::ExitCodes only.
- UTF-8: decode on input, encode on output, never double-encode (lesson of 1.36).
