# Contributing to My Moodle

This is a personal prototype, but consistency still matters — future-you is the main maintainer. Follow the rules below so every change stays reviewable and the repository stays safe.

## Local Development

```bash
npm install
cp .env.example .env   # then fill VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY
npm run dev
```

The app runs as a browser-only prototype when Supabase environment variables are absent — handy for UI work without a backend.

## Before You Push

- `npm run build` must pass — it runs `tsc -b` (strict type-check) then `vite build`.
- **Never commit secrets**, `.env` files, or personal study documents. `.gitignore` guards these; keep it that way.
- Database changes belong in `database/*.sql`. When you change the schema, document the migration steps in `docs/` so the Supabase project can be reproduced from scratch.

## Commit Style

- Imperative mood, concise subject: `Add X`, `Fix Y`, `Style Z`, `chore: ...`
- One logical change per commit; keep unrelated cleanup in separate commits.
- Reference the relevant issue number in the body when applicable (e.g. `Closes #1`).

## Branching and Releases

- Work directly on short-lived branches or straight on `main` for small fixes; `main` must always build.
- Tag user-facing milestones as `vX.Y.Z` following the version in `package.json`, and add release notes listing Added / Fixed / Project changes.

## Testing

A test suite (Vitest + React Testing Library) is planned — see the open issues. Until it lands, manually verify these flows after auth- or data-related changes:

1. Login and logout from Settings and the sidebar return to the welcome page.
2. A stale 401/403 from Supabase recovers without wiping local study data.
3. Notes, highlights, bookmarks and reading progress survive a page reload.

## Security Expectations

- Row Level Security in `database/multi_student_schema.sql` must keep every student's data private; any schema change must preserve this.
- Report anything suspicious as a GitHub issue rather than committing workarounds.
