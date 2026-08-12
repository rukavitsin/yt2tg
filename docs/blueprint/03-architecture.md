# 03 Architecture

## Principle

Bash orchestrates. Perl processes data. Each utility does one thing,
reads STDIN or a file, writes STDOUT, and returns a documented exit code.

## Pipeline

    article.md
      |  tgph-md2content   front matter + cmark + html2content
      |  tgph-normalize    h1->title, h2->h3, h3+->h4
      |  tgph-optimize     drop empty nodes, merge adjacent text
      |  tgph-validate     check Telegraph tag structure
      |  tgph-split        greedy pages + recursive oversized splitting
      |  tgph-link         add Part X of Y navigation
      |  tgph-publish      createPage via HTTP::Tiny

    pubtgph   POSIX sh orchestrator over the whole chain

## Data format

content.json = array of nodes.
node = scalar (text) or object { tag, children?, attrs? }.
attrs whitelisted: a->href, img->src.
Interchange is canonical JSON: sorted keys, UTF-8 bytes on the wire.

## Module decomposition (bin/lib/Tgph)

    ExitCodes  constants for the exit-code contract
    CLI        Getopt::Long wrapper, help/version/dry-run
    IO         raw byte read/write
    JSON       canonical encode/decode/bytes
    Content    node tree helpers
    Node       single-node predicates
    Validate   structural + tag whitelist validation
    Limit      byte-limit predicate
    Normalize  heading mapping + title extraction
    Split      page packing + recursive splitting (v2)
    Link       navigation indicator
    Optimize   empty-node removal + text merging
    Pretty     pretty/compact JSON
    Publish    request build + HTTP send
    FrontMatter  dependency-free YAML front matter parse
    HTML2Content cmark HTML -> content nodes
    Markdown   front matter + cmark + html2content assembly

## Exit codes

    0 OK   1 USAGE   2 INPUT   3 OUTPUT   4 VALIDATION   5 API   70 INTERNAL

## Encoding contract

Decode UTF-8 on input, encode on output, never double-encode.
HTTP::Tiny post_form receives characters, not pre-encoded bytes.
Telegra.ph auto-transliterates Cyrillic in URL slugs.
