# TODO (backlog)

Deferred work. Designed items link to docs/design/.

## Phase 3: API utilities — PARTIALLY DONE

Read/write utilities over the Telegraph account/page API.
Full design: docs/design/api-utilities.md

Done:
- tgph-edit (editPage)
- tgph-delete (tombstone; public API has no delete)

Deferred:
- tgph-get (getPage)
- tgph-list (getPageList)
- tgph-stats (getViews)

In progress:
- (done) orchestrator: front matter url on telegra.ph -> edit not create (Iter.78)
- rate limiting: retry with exponential backoff
- (done) publish journal relocated to /pubtg

## Not designed

- concurrency control for batch publishing
- OS packaging (deb/rpm) beyond make install DESTDIR
