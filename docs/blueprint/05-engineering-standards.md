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

## File patching discipline (added Iter.64)

- **Запрет на sed/perl -pi для нетривиальных правок кода и тестов.** Используется только полный rewrite через heredoc (детерминирован, не зависит от текущего состояния файла).
- sed допустим только для односимвольных/очевидных замен с немедленной `grep -qF` верификацией сразу после.
- Причины: perl replacement интерполирует $vars; sed replacement расширяет & до всего совпадения; shell double quotes едят backslashes.
- Исключения: массовая замена одного идентификатора на другой (rename) с явным указанием точного паттерна.

## Diagnosis before fix (added Iter.64)

- Перед каждым исправлением — диагностика: `grep -n` реальную строку, понимание точной структуры.
- Паттерн для замены строится из факта (вывода диагностики), не из памяти.
- Для API-ошибок: curl с теми же параметрами что использует код, для проверки URL/токена/SSL.
- Для parsing-ошибок: распечатка промежуточных данных (что пришло, что ожидалось).

## Pre-publish checklist (added Iter.64)

Перед публикацией итерации (commit):
- Все переменные объявлены (`my $var`, нет `Global symbol requires explicit package name`).
- `perl -c` на каждом изменённом .pm/.t файле.
- `sh -n` на каждом изменённом shell-скрипте.
- `grep -qF` после каждой замены для верификации.
- Номер коммита **строго равен** номеру итерации (`Iter.64` для Iteration 64).
- Секреты не в env и не в argv (не видны в `ps`/`/proc`).
- Реальное E2E тестирование для API-изменений.

## Iteration block formatting (added Iter.68)

- The outer shell fence of an iteration block must never contain triple
  backticks inside: the first inner fence closes the block early and the
  rest renders as markdown mush (68).
- Nested code inside heredocs (docs, examples) must use 4-space-indented
  code blocks instead of fenced blocks (68).
- Before publishing, scan the block for triple backticks beyond the outer
  open/close pair.
