-- My Moodle multi-student schema. Review and run in a dedicated Supabase project.
-- Do not combine with the previous single-user owner_id schema.
create extension if not exists pgcrypto;

create table if not exists public.student_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null check (char_length(trim(full_name)) between 2 and 120),
 role text not null default 'student' check (role in ('student','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.study_subjects (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 description text not null default '',
 year integer not null check(year between 1 and 8),
 semester integer not null check(semester between 1 and 4),
 created_at timestamptz not null default now()
);
create table if not exists public.study_modules (
 id uuid primary key default gen_random_uuid(),
 subject_id uuid not null references public.study_subjects(id) on delete cascade,
 title text not null,
 notes text not null default '',
 position integer not null default 0
);
create table if not exists public.study_resources (
 id uuid primary key default gen_random_uuid(),
 module_id uuid not null references public.study_modules(id) on delete cascade,
 title text not null,
 storage_path text not null unique,
 mime_type text,
 created_at timestamptz not null default now()
);
create table if not exists public.student_module_progress (
 student_id uuid not null references auth.users(id) on delete cascade,
 module_id uuid not null references public.study_modules(id) on delete cascade,
 completed_at timestamptz not null default now(),
 primary key(student_id,module_id)
);
create table if not exists public.study_assignments (
 id uuid primary key default gen_random_uuid(),
 subject_id uuid not null references public.study_subjects(id) on delete cascade,
 title text not null,
 instructions text not null default '',
 due_at timestamptz
);
create table if not exists public.student_assignment_submissions (
 assignment_id uuid not null references public.study_assignments(id) on delete cascade,
 student_id uuid not null references auth.users(id) on delete cascade,
 submission_text text not null default '',
 submitted_at timestamptz not null default now(),
 score numeric(6,2),
 primary key(assignment_id,student_id)
);
create table if not exists public.study_quizzes (
 id uuid primary key default gen_random_uuid(),
 subject_id uuid not null references public.study_subjects(id) on delete cascade,
 title text not null
);
create table if not exists public.student_quiz_attempts (
 id uuid primary key default gen_random_uuid(),
 quiz_id uuid not null references public.study_quizzes(id) on delete cascade,
 student_id uuid not null references auth.users(id) on delete cascade,
 score numeric(6,2),
 submitted_at timestamptz not null default now()
);
-- Authorization role is never read from editable user metadata.
create or replace function public.is_study_admin()
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.student_profiles where id=(select auth.uid()) and role='admin') $$;
revoke all on function public.is_study_admin() from public, anon;
grant execute on function public.is_study_admin() to authenticated;

-- Signup trigger creates student profile; never accepts a role from metadata.
create or replace function public.create_student_profile()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
 insert into public.student_profiles(id,full_name,role)
 values(new.id,coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'),''),'Student'),'student')
 on conflict(id) do nothing;
 return new;
end $$;
drop trigger if exists on_student_signup on auth.users;
create trigger on_student_signup after insert on auth.users
for each row execute function public.create_student_profile();

alter table public.student_profiles enable row level security;
alter table public.study_subjects enable row level security;
alter table public.study_modules enable row level security;
alter table public.study_resources enable row level security;
alter table public.student_module_progress enable row level security;
alter table public.study_assignments enable row level security;
alter table public.student_assignment_submissions enable row level security;
alter table public.study_quizzes enable row level security;
alter table public.student_quiz_attempts enable row level security;

create policy "Read own profile" on public.student_profiles for select to authenticated using(id=(select auth.uid()));
create policy "Update own name only" on public.student_profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
-- Column privileges prevent changing role or id through the Data API.
revoke all on public.student_profiles from anon, authenticated;
grant select on public.student_profiles to authenticated;
grant update(full_name) on public.student_profiles to authenticated;

-- Shared content: all signed-in students can read, only admins can modify.
create policy "Read subjects" on public.study_subjects for select to authenticated using(true);
create policy "Admin subjects" on public.study_subjects for all to authenticated using((select public.is_study_admin())) with check((select public.is_study_admin()));
create policy "Read modules" on public.study_modules for select to authenticated using(true);
create policy "Admin modules" on public.study_modules for all to authenticated using((select public.is_study_admin())) with check((select public.is_study_admin()));
create policy "Read resources" on public.study_resources for select to authenticated using(true);
create policy "Admin resources" on public.study_resources for all to authenticated using((select public.is_study_admin())) with check((select public.is_study_admin()));
create policy "Read assignments" on public.study_assignments for select to authenticated using(true);
create policy "Admin assignments" on public.study_assignments for all to authenticated using((select public.is_study_admin())) with check((select public.is_study_admin()));
create policy "Read quizzes" on public.study_quizzes for select to authenticated using(true);
create policy "Admin quizzes" on public.study_quizzes for all to authenticated using((select public.is_study_admin())) with check((select public.is_study_admin()));

create policy "Own progress read" on public.student_module_progress for select to authenticated using(student_id=(select auth.uid()));
create policy "Own progress insert" on public.student_module_progress for insert to authenticated with check(student_id=(select auth.uid()));
create policy "Own progress delete" on public.student_module_progress for delete to authenticated using(student_id=(select auth.uid()));
create policy "Own submissions read" on public.student_assignment_submissions for select to authenticated using(student_id=(select auth.uid()) or (select public.is_study_admin()));
create policy "Own submissions insert" on public.student_assignment_submissions for insert to authenticated with check(student_id=(select auth.uid()) and score is null);
create policy "Own submissions update" on public.student_assignment_submissions for update to authenticated using(student_id=(select auth.uid())) with check(student_id=(select auth.uid()) and score is null);
create policy "Own attempts read" on public.student_quiz_attempts for select to authenticated using(student_id=(select auth.uid()));
-- Quiz attempts will be written by a trusted grading endpoint in a later phase, not client-side.

revoke all on public.student_assignment_submissions from anon, authenticated;
grant select, insert on public.student_assignment_submissions to authenticated;
grant update(submission_text,submitted_at) on public.student_assignment_submissions to authenticated;
grant select,insert,update,delete on public.study_subjects,public.study_modules,public.study_resources,public.study_assignments,public.study_quizzes,public.student_module_progress to authenticated;
grant select on public.student_quiz_attempts to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('shared-study-materials','shared-study-materials',false,20971520,array['application/pdf','image/png','image/jpeg','text/plain'])
on conflict(id) do nothing;
create policy "Read shared study files" on storage.objects for select to authenticated using(bucket_id='shared-study-materials');
create policy "Admin upload shared study files" on storage.objects for insert to authenticated with check(bucket_id='shared-study-materials' and (select public.is_study_admin()));
create policy "Admin update shared study files" on storage.objects for update to authenticated using(bucket_id='shared-study-materials' and (select public.is_study_admin())) with check(bucket_id='shared-study-materials' and (select public.is_study_admin()));
create policy "Admin delete shared study files" on storage.objects for delete to authenticated using(bucket_id='shared-study-materials' and (select public.is_study_admin()));

-- Promote first admin ONLY using trusted SQL editor after they register:
-- update public.student_profiles set role='admin' where id='<verified auth.users UUID>';
