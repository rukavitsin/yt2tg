# Design: Phase 3 API utilities

Status: DESIGNED, DEFERRED. Backlog entry: docs/TODO.md.

## Shared contract

- One Telegraph API method per utility.
- Canonical JSON to STDOUT, diagnostics to STDERR.
- Exit codes: 0 OK, 1 USAGE, 2 INPUT, 5 API, 70 INTERNAL.
- Token from ~/.tgrc (TP_TOKEN) or --access-token; required only
  where the API requires it.

## Method mapping

    utility      method         token   purpose
    tgph-get     getPage        no      read published page incl. content
    tgph-edit    editPage       yes     update existing page at same URL
    tgph-list    getPageList    yes     account inventory, pagination
    tgph-stats   getViews       no      view counts, optional y/m/d slices
    tgph-delete  (none)         yes     see honesty note below

## delete honesty

The public Telegraph API has no deletePage. Options considered:

1. do not implement; document the limitation;
2. tombstone via editPage (content replaced by a note, URL stays);
3. revokeAccessToken (revokes account control, pages stay).

Proposed decision: implement tombstone behind an explicit
--tombstone flag, warn in --help, and document that true deletion
is impossible via the public API.

## Architecture

Generalize the Tgph::Publish HTTP layer into
Tgph::Api::call(method, params). The five utilities become thin CLI
wrappers over it; no duplicated request logic.

## Implementation order

1. Tgph::Api + tgph-get   (read-only)
2. tgph-stats            (read-only)
3. tgph-list             (read-only)
4. tgph-edit             (mutating)
5. tgph-delete tombstone (mutating, warned)

After 4: orchestrator integration — when front matter url points to
telegra.ph, edit the existing page instead of creating a new one.
