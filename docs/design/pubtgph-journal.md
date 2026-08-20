# Design: pubtgph Journal (Iteration 94+)

## Problem
pubtgph publishes/edits pages but has no history tracking. Cannot:
- List all published pages
- Track edit history
- Audit what was published when

## Solution
1. Create `Tgph::Journal` module (JSONL append-only log)
2. Create `tgph-journal` CLI (list/check/append commands)
3. Integrate into pubtgph: log every create/edit action
4. Journal location: `$XDG_DATA_HOME/pubtg/publish_log.jsonl`

## Journal record schema

    {
      "timestamp": "2026-08-20T15:30:00Z",
      "action": "create",
      "source_file": "/path/to/article.md",
      "title": "Article Title",
      "path": "Article-Title-08-20",
      "url": "https://telegra.ph/Article-Title-08-20"
    }

    {
      "timestamp": "2026-08-20T16:45:00Z",
      "action": "edit",
      "source_file": "/path/to/article.md",
      "title": "Article Title",
      "path": "Article-Title-08-20",
      "url": "https://telegra.ph/Article-Title-08-20"
    }

## Tgph::Journal API

    Tgph::Journal::append_record($journal_file, \%record);
    Tgph::Journal::find_record($journal_file, $path);
    Tgph::Journal::list_entries($journal_file);

## tgph-journal CLI

    tgph-journal list                 # list all entries (newest first)
    tgph-journal check --path PATH    # check if path exists
    tgph-journal append --record JSON # append record

## Integration points in pubtgph

1. After createPage (line ~240): log action=create
2. After editPage (line ~200): log action=edit
3. Before publish: optionally check journal for existing path

## Implementation phases

### Phase 1 (Iteration 94): Tgph::Journal module + unit tests
### Phase 2 (Iteration 95): tgph-journal CLI
### Phase 3 (Iteration 96): integrate into pubtgph
