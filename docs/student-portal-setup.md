# Student portal setup — local testing only

The app keeps the original browser-only prototype when Supabase environment variables are absent. To test the new multi-student portal:

1. Create or select a **dedicated Supabase project** for My Moodle.
2. In its SQL Editor, review and execute `database/multi_student_schema.sql` once. This schema is not compatible with the old owner-based personal Moodle schema.
3. In Supabase Authentication, enable Email signups. **No administrator approval is required.** Email confirmation may still be enabled; if so students must confirm email before login.
4. Copy `.env.example` to `.env.local` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`. Never place a service role or secret key in Vite variables.
5. Run `npm install`, `npm run build`, then `npm run dev`.
6. Register your own account. In the SQL Editor, identify your actual user UUID and explicitly promote only that verified account:
   `update public.student_profiles set role='admin' where id='YOUR_VERIFIED_USER_UUID';`
7. Sign out/in. Admin can add subjects, modules and shared files. Student accounts can view shared files and record their own progress/submissions.

**Important:** The previous localStorage subject data and 28-subject catalogue are NOT automatically migrated into Supabase. Back up your local data before switching. Admin must seed/import content separately. Quizzes and secure grading are not yet implemented.

**Privacy:** Each student can read only their profile, module progress, assignment submissions and quiz attempts. Shared materials require authentication and are delivered via short-lived signed URLs. Student account creation does not require approval.

**Deployment:** Do not redeploy to Vercel until local testing is approved. If Vercel Git auto-deploy is enabled, disable it before pushing further commits.
