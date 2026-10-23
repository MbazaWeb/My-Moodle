# Structured learning content — next phase (not implemented yet)

The Admin Console currently manages subjects, modules, text notes and uploaded files. Do not auto-import a fixed RUCU curriculum.

## Proposed JSON chapter/page format

```json
{
  "schemaVersion": 1,
  "subjectId": "uuid",
  "chapterId": "uuid",
  "title": "Introduction",
  "pages": [
    {
      "id": "stable-uuid",
      "order": 1,
      "title": "Overview",
      "blocks": [
        {"id": "stable-block-uuid", "type": "paragraph", "text": "Study content"},
        {"id": "stable-block-uuid-2", "type": "heading", "level": 2, "text": "Key ideas"}
      ]
    }
  ]
}
```

## Requirements for the later phase
- Admin imports/edits JSON and previews chapters/pages before publishing.
- Validate against a versioned JSON schema, sanitize rendered content, enforce admin-only writes with RLS.
- Students navigate by subject > chapter > page; record progress individually.
- Highlights anchored to stable block IDs and text offsets, with selected-text quote for recovery after edits.
- Personal notes and bookmarks belong to auth.uid() and are never shared by default.
- Preserve old chapter versions or migrate annotations when admin edits text; avoid relying only on page indices.
- Store student annotations in separate RLS-protected tables, not inside shared JSON.
- Search within chapter text and export personal notes in a later release.

This is an architecture proposal only. Do not claim JSON reader, highlights or personal annotations are live until implemented and tested.
