# My Moodle — RUCU Personal Study App

Personal local-first study system for the Diploma in Business Administration at Ruaha Catholic University (RUCU), organised around 2 academic years with 2 semesters per year.

## Features

- Splash and welcome onboarding with compact student login
- Editable student profile with secure email change
- **My Courses** — subject enrolment with progress overview, year and semester filters
- **Assignments** — status tabs, statistics, subject filters and in-app submission form
- **Calendar workspace** — exams, alerts, reminders and personal to-dos
- **Book reader** — JSON chapter/page reading with private notes, highlights and comments
- Bookmarks and per-student reading progress ("Continue Studying")
- Settings for dark theme, reading size and reduced motion, persisted locally
- Mobile-first layout with bottom navigation and responsive book reading

## Tech Stack

- [React 19](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/)
- [Vite 6](https://vite.dev/) for dev server and production builds
- [Supabase](https://supabase.com/) for auth, data and row level security (RLS)
- [Lucide](https://lucide.dev/) icons

## Getting Started

```bash
npm install
npm run dev
```

The app runs as a browser-only prototype when Supabase environment variables are absent. To enable the multi-student portal:

1. Copy `.env.example` to `.env`
2. Fill in `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` from your Supabase project
3. Run the SQL in [`database/`](database/) against your Supabase project — see [`docs/student-portal-setup.md`](docs/student-portal-setup.md)

Other scripts:

| Command           | Description                              |
| ----------------- | ---------------------------------------- |
| `npm run dev`     | Start the dev server (host on LAN)       |
| `npm run build`   | Type-check and build for production      |
| `npm run preview` | Preview the production build locally     |

## Project Structure

```
├── src/                  # Application source (React + TypeScript)
│   ├── CloudApp.tsx      # Main student workspace
│   ├── main.tsx          # Entry point and routing
│   ├── supabase.ts       # Supabase client
│   └── style.css         # Global styles
├── my-moodle/            # Earlier standalone prototype (kept for reference)
├── database/             # Supabase SQL schemas and seed data
├── docs/                 # Setup guides and design notes
├── public/               # Static assets (favicon, subject JSON content)
└── .github/workflows/    # CI build validation
```

## Documentation

- [Student portal setup](docs/student-portal-setup.md) — dedicated Supabase project and local testing
- [Structured learning roadmap](docs/structured-learning-roadmap.md) — proposed JSON chapter/page format
- [Multi-student schema](database/multi_student_schema.sql) and [study list SQL](database/student_study_list.sql)

## Deployment

The app is deployed on Vercel. Never commit secrets, `.env` files or personal study documents.

## License

Released under the [MIT License](LICENSE).
