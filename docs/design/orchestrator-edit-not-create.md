# Design: orchestrator edit-not-create (Iteration 76+)

## Problem
When an article is re-published with the same content, pubtgph creates
a duplicate Telegraph page instead of updating the existing one.

## Solution
1. Read front matter from markdown file
2. If `telegra_ph_url` exists in metadata:
   - Extract path from URL (e.g., `https://telegra.ph/Test-Page` -> `Test-Page`)
   - Use editPage flow instead of createPage
3. After successful publish/edit:
   - Write URL back to front matter in the source md file
4. For multi-page articles:
   - Store array of paths in front matter (`telegra_ph_paths:`)
   - Edit existing pages, create new ones, tombstone extras via tgph-delete

## Front matter schema

Single page:

    ---
    title: Article Title
    telegra_ph_url: https://telegra.ph/Article-Title-08-20
    ---

Multi-page (future):

    ---
    title: Long Article
    telegra_ph_paths:
      - Long-Article-08-20
      - Long-Article-2-08-20
      - Long-Article-3-08-20
    ---

## Implementation phases

### Phase 1 (Iteration 76): single-page edit
- FrontMatter::extract returns metadata with telegra_ph_url
- pubtgph checks front matter before publish
- If URL exists: call tgph-edit with new content
- After edit: write URL back to front matter

### Phase 2 (future): multi-page with nav
- Store telegra_ph_paths array in front matter
- Match existing paths with new pages
- Edit matched, create new, tombstone orphaned
