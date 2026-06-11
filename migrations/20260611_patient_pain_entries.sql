-- NESO Sante - historique douleur patient
-- A executer dans Supabase > SQL Editor.

create table if not exists public.patient_pain_entries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references auth.users(id) on delete cascade,
  score integer not null check (score between 0 and 10),
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists patient_pain_entries_patient_recorded_idx
on public.patient_pain_entries (patient_id, recorded_at desc);

alter table public.patient_pain_entries enable row level security;

revoke all on table public.patient_pain_entries from anon, authenticated;
grant select, insert, delete on table public.patient_pain_entries to authenticated;

drop policy if exists "Patients select own pain entries" on public.patient_pain_entries;
create policy "Patients select own pain entries"
on public.patient_pain_entries
for select
to authenticated
using (
  auth.uid() is not null
  and patient_id = auth.uid()
);

drop policy if exists "Patients insert own pain entries" on public.patient_pain_entries;
create policy "Patients insert own pain entries"
on public.patient_pain_entries
for insert
to authenticated
with check (
  auth.uid() is not null
  and patient_id = auth.uid()
);

drop policy if exists "Patients delete own pain entries" on public.patient_pain_entries;
create policy "Patients delete own pain entries"
on public.patient_pain_entries
for delete
to authenticated
using (
  auth.uid() is not null
  and patient_id = auth.uid()
);
