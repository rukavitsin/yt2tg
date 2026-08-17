# 08 Reference Manifest (final state)

## bin (11)

    tgph-measure           count bytes of raw input
    tgph-limit             predicate: does input fit the byte limit
    tgph-validate          validate Telegraph content structure
    tgph-normalize         heading mapping + h1 title extraction
    tgph-optimize          drop empty nodes, merge adjacent text
    tgph-split             page packing + recursive oversized splitting
    tgph-link              Part X of Y navigation indicator
    tgph-pretty            pretty/compact canonical JSON
    tgph-publish           createPage via Telegraph API
    tgph-md2content        markdown -> content.json (cmark + front matter)
    pubtgph   POSIX sh orchestrator, md -> published pages

## bin/lib/Tgph (19)

    Constants  ExitCodes  CLI  IO  JSON  Content  Node  Validate  Limit
    Normalize  Split  Link  Optimize  Pretty  Publish
    FrontMatter  HTML2Content  Markdown  Version

## tests

    unit:        Tgph-*.t per module, tgph-*.t per CLI
    integration: pipeline.t, orchestrator.t, tgph-md2content.t
    final count at release: 29 files, 496 tests, all PASS

## docs and examples

    docs/development/  STYLE.md, TESTING.md, TGPH_* context files
    docs/blueprint/    this package (01..08 + README)
    examples/          minimal, article, oversized-paragraph, broken

## External dependencies

    cmark (markdown -> HTML), IO::Socket::SSL (HTTPS), curl (smoke only)

## yt2tg Extension Reference

See [09-yt2tg-extension.md](09-yt2tg-extension.md) for the complete yt2tg extension specification, including pipeline steps, checks, journal, artifact storage, and future actions.
