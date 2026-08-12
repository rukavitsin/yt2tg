# 04 Implementation Plan

Staged plan with hard dependencies. Each stage is one or more green
commits. Never start stage N+1 on a red suite.

Sources of truth: this package and the git log; the legacy context
export (tgph-perl-context-export) is historical input only.

## Stage 0  Foundation

    bin/lib/Tgph/ExitCodes.pm   exit-code constants
    bin/lib/Tgph/CLI.pm         option parsing, help/version/dry-run
    bin/lib/Tgph/IO.pm          raw byte IO
    bin/lib/Tgph/JSON.pm        canonical JSON encode/decode/bytes

Depends on: nothing. Everything else depends on this.

## Stage 1  Content model and measurement

    bin/lib/Tgph/Content.pm, bin/lib/Tgph/Node.pm
    bin/tgph-measure, bin/tgph-limit

## Stage 2  Validation

    bin/lib/Tgph/Validate.pm, bin/tgph-validate
    Telegraph tag whitelist, structural checks.

## Stage 3  Normalization

    bin/lib/Tgph/Normalize.pm, bin/tgph-normalize
    h1->title extraction, h2->h3, h3+->h4.

## Stage 4  Splitting v0

    bin/lib/Tgph/Split.pm, bin/tgph-split
    Greedy top-level packing under byte budget.

## Stage 5  Navigation

    bin/lib/Tgph/Link.pm, bin/tgph-link

## Stage 6  Publishing

    bin/lib/Tgph/Publish.pm, bin/tgph-publish
    Dry-run first; real network only after dry-run is green.

## Stage 7  Integration

    tests/integration/pipeline.t over the whole chain.

## Stage 8  Content polish

    bin/lib/Tgph/Optimize.pm, bin/lib/Tgph/Pretty.pm + bins.

## Stage 9  Orchestrator

    bin/pubtgph (POSIX sh) over content.json pipeline.

## Stage 10  Split hardening

    v1 recursive element splitting; v2 text/pre/word splitting.
    Update v0 expectations that intentionally change.

## Stage 11  Markdown input

    bin/lib/Tgph/FrontMatter.pm (dependency-free)
    bin/lib/Tgph/HTML2Content.pm (cmark output parser)
    bin/lib/Tgph/Markdown.pm, bin/tgph-md2content

## Stage 12  Orchestrator upgrade

    md input, ~/.tgrc (TP_TOKEN, TP_URL), title fallback chain.

## Stage 13  Real-world proof

    Smoke dry-run, then gated real publish; fix UTF-8 contract.

## Stage 14  Documentation

    README, examples, STYLE/TESTING, this blueprint.
