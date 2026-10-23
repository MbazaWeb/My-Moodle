-- My Moodle: private single-user LMS. Run in a NEW Supabase project.
create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Student',
  created_at timestamptz not null default now()
);
create table public.courses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (length(trim(title)) between 1 and 200),
  description text not null default '',
  status text not null default 'active' check (status in ('active','archived')),
  created_at timestamptz not null default now(),
  unique (id,owner_id)
);
create table public.sections (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null,
  title text not null,
  position integer not null default 0,
  unique(id,owner_id),
  foreign key (course_id,owner_id) references public.courses(id,owner_id) on delete cascade
);
create table public.lessons (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  section_id uuid not null,
  title text not null,
  body text not null default '',
  position integer not null default 0,
  completed_at timestamptz,
  unique(id,owner_id),
  foreign key (section_id,owner_id) references public.sections(id,owner_id) on delete cascade
);
create table public.materials (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null,
  title text not null,
  storage_path text not null,
  mime_type text,
  created_at timestamptz not null default now(),
  foreign key (lesson_id,owner_id) references public.lessons(id,owner_id) on delete cascade
);
create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null,
  title text not null,
  instructions text not null default '',
  due_at timestamptz,
  status text not null default 'todo' check (status in ('todo','in_progress','submitted','completed')),
  submitted_at timestamptz,
  score numeric(6,2),
  max_score numeric(6,2) check(max_score > 0),
  check(score is null or (score >= 0 and max_score is not null and score <= max_score)),
  unique(id,owner_id),
  foreign key (course_id,owner_id) references public.courses(id,owner_id) on delete cascade
);
create table public.quizzes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null,
  title text not null,
  duration_minutes integer check(duration_minutes between 1 and 600),
  created_at timestamptz not null default now(),
  unique(id,owner_id),
  foreign key (course_id,owner_id) references public.courses(id,owner_id) on delete cascade
);
create table public.questions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid not null,
  prompt text not null,
  question_type text not null check(question_type in ('mcq','true_false','short_answer')),
  options jsonb,
  correct_answer jsonb,
  points numeric(6,2) not null default 1 check(points > 0),
  position integer not null default 0,
  unique(id,owner_id),
  foreign key (quiz_id,owner_id) references public.quizzes(id,owner_id) on delete cascade
);
create table public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  quiz_id uuid not null,
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  score numeric(8,2) check(score >= 0),
  status text not null default 'in_progress' check(status in ('in_progress','submitted','expired')),
  unique(id,owner_id),
  foreign key (quiz_id,owner_id) references public.quizzes(id,owner_id) on delete cascade
);
create table public.quiz_answers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  attempt_id uuid not null,
  question_id uuid not null,
  answer jsonb,
  awarded_points numeric(6,2) check(awarded_points >= 0),
  unique(attempt_id,question_id),
  foreign key (attempt_id,owner_id) references public.quiz_attempts(id,owner_id) on delete cascade,
  foreign key (question_id,owner_id) references public.questions(id,owner_id) on delete cascade
);
create table public.study_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid,
  title text not null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  check(ends_at is null or ends_at >= starts_at),
  foreign key (course_id,owner_id) references public.courses(id,owner_id) on delete cascade
);
create index courses_owner_idx on public.courses(owner_id);
create index assignments_due_idx on public.assignments(owner_id,due_at);
create index events_date_idx on public.study_events(owner_id,starts_at);
create index attempts_quiz_idx on public.quiz_attempts(owner_id,quiz_id);

-- Default-deny: no table access without authenticated user and ownership policy.
do $$ declare t text; begin
  foreach t in array array['profiles','courses','sections','lessons','materials','assignments','quizzes','questions','quiz_attempts','quiz_answers','study_events'] loop
    execute format('alter table public.%I enable row level security',t);
  end loop;
end $$;
-- Profiles have user ID as primary key; all other tables have owner_id.
create policy "Own profile" on public.profiles for all to authenticated
 using(id = (select auth.uid())) with check(id = (select auth.uid()));
do $$ declare t text; begin
  foreach t in array array['courses','sections','lessons','materials','assignments','quizzes','questions','quiz_attempts','quiz_answers','study_events'] loop
    execute format('create policy "Own records" on public.%I for all to authenticated using(owner_id = (select auth.uid())) with check(owner_id = (select auth.uid()))',t);
  end loop;
end $$;

-- Supabase Storage: create private bucket in dashboard or via SQL.
insert into storage.buckets(id,name,public,file_size_limit)
values('study-materials','study-materials',false,52428800)
on conflict(id) do nothing;
-- Object key convention: <auth.uid()>/<uuid>/<filename>.
create policy "Read own study files" on storage.objects for select to authenticated
using(bucket_id='study-materials' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "Upload own study files" on storage.objects for insert to authenticated
with check(bucket_id='study-materials' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "Delete own study files" on storage.objects for delete to authenticated
using(bucket_id='study-materials' and (storage.foldername(name))[1]=(select auth.uid())::text);
