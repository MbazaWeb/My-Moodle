-- Personal subject enrollment; admin owns catalog, students own study lists.
create table if not exists public.student_study_list (
 student_id uuid not null references auth.users(id) on delete cascade,
 subject_id uuid not null references public.study_subjects(id) on delete cascade,
 added_at timestamptz not null default now(),
 primary key(student_id,subject_id)
);
alter table public.student_study_list enable row level security;
create policy "Students read own study list" on public.student_study_list for select to authenticated using(student_id=(select auth.uid()));
create policy "Students add own study subjects" on public.student_study_list for insert to authenticated with check(student_id=(select auth.uid()));
create policy "Students remove own study subjects" on public.student_study_list for delete to authenticated using(student_id=(select auth.uid()));
grant select,insert,delete on public.student_study_list to authenticated;
create index if not exists student_study_list_subject_idx on public.student_study_list(subject_id);
