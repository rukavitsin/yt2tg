# TODO (backlog)

Deferred work. Designed items link to docs/design/.

## Phase 3: API utilities — DESIGNED, DEFERRED

Read/write utilities over the Telegraph account/page API.
Full design: docs/design/api-utilities.md

- tgph-get (getPage)
- tgph-edit (editPage)
- tgph-list (getPageList)
- tgph-stats (getViews)
- tgph-delete (tombstone; public API has no delete)
- orchestrator: front matter url on telegra.ph -> edit not create

## Not designed

- rate limiting / concurrency control for batch publishing
- OS packaging (deb/rpm) beyond make install DESTDIR
