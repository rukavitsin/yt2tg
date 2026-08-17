# 05 Engineering Standards

## Iteration block format (fixed)

    # run: sh ../cmd-<N> 2>&1 | xclip -selection clipboard -i
    exec 2>&1
    set -eu
    echo '=== Iteration <N>: <title> ==='
    # 1 file changes via quoted heredocs
    # 2 perl -Ibin/lib -c for each changed file
    # 3 prove -Ibin/lib -r tests
    # 4 git status; 5 git add <explicit>; 6 git diff --cached --check
    # 7 git commit -m "type(scope): subject"; 8 final state + prove

## Shell (blocks and artifacts)

- POSIX sh (dash). No [[ ]], arrays, BASH_SOURCE, pipefail.
- exec 2>&1 first so the clipboard pipe captures stderr too.
- set -eu; stop on first error, no half-done state.
- Minimal forks: printf/case/${var%%}/${var##}, set -- and shift,
  while IFS= read -r with done < file, $(( )) not expr,
  case not grep for patterns, exec > file for redirection.
- Constants at top; die()/usage() as single edit points;
  exit codes passed as function arguments.
- DRY with judgement: do not extract one-use helpers.
- Quoted heredoc markers; mkdir -p before writing into new dirs.
- NEVER place triple backticks inside a block or doc heredoc.

## Perl

- use v5.36; use strict; use warnings;
- Core modules only: JSON::PP, Encode, HTTP::Tiny, Getopt::Long,
  IPC::Open2. No CPAN, no XS.
- bin/lib/ owns logic; bin/ scripts are thin wrappers (parse, IO, exit codes).
- Exit codes only from Tgph::ExitCodes.
- Canonical JSON (sorted keys) everywhere; UTF-8 decode on input,
  encode on output; never double-encode.
- Getopt::Long: never register short aliases differing only by case.

## Commits

- One logical change per commit; message type(scope): subject.
- Block must end green: final prove passes, tree clean.

## Applicability to yt2tg Extension

The engineering standards defined in this document apply to the yt2tg extension.
Additional yt2tg-specific standards:
- POSIX sh for orchestrator (no bashisms)
- Perl modules in bin/lib/Yt2tg/
- yt-dlp for YouTube metadata and subtitle extraction
- ffmpeg for subtitle format conversion
