# pubtgph Blueprint

A complete documentation package for rebuilding this project from scratch.

Read in order 01..08. Each file is self-contained and actionable:
a competent engineer (or an LLM agent) can reconstruct the toolkit
using only this folder plus a stock Perl 5.36 + dash environment.

## Contents

    01-roles-and-protocol.md   who MODEL and USER are, how they talk
    02-vision-and-requirements.md  problem, goals, functional and non-functional reqs
    03-architecture.md         pipeline, module decomposition, data formats, exit codes
    04-implementation-plan.md  staged iteration plan with dependencies
    05-engineering-standards.md  shell and Perl coding standards, block format
    06-testing-strategy.md     test layout, rules, what must be green
    07-lessons-learned.md      bug register: root cause and prevention
    08-reference-manifest.md   final file manifest with one-line purposes

## Conventions

- All code blocks in this package use 4-space indentation, never fenced
  triple backticks (see 07-lessons-learned.md, item FENCES).
- Shell is POSIX sh (dash). Perl is core-modules-only.
- One commit per logical change; every block ends green.
