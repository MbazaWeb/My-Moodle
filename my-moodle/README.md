# My Moodle — Private Classic LMS (Local Prototype)

A working, responsive React + TypeScript prototype for personal learning.

## Features currently working
- Course creation, topic editing and completion tracking
- Personal dashboard with derived metrics
- Assignment creation and completion
- Basic multiple-choice quiz creation, attempts and grades
- Study calendar and assignment deadlines
- Browser-local persistence, JSON backup and restore

## Run locally
```bash
npm install
npm run dev
```

## Security and data limitations
This is a **local prototype**. Data is stored in browser `localStorage`, which is not a secure private cloud account. It is not synchronized across devices. There is no authentication, server-side quiz grading, PDF upload, or production-ready timed exams yet. Do not store sensitive documents. The SQL in `supabase/schema.sql` is an initial proposed schema, **not applied to any database**. It requires security review and migrations before production use.

## Next build stage
1. Add Supabase Auth and owner-scoped CRUD APIs.
2. Add private PDF storage and signed URLs.
3. Implement robust quiz grading and attempt state server-side.
4. Add full calendar, assignments and validation tests.
5. Run RLS and end-to-end security tests.

**No deployment was performed.**
