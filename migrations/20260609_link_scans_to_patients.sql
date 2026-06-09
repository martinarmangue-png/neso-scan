-- Physio Scan - liaison scans / comptes patients
-- À exécuter dans Supabase > SQL Editor après les migrations précédentes.
-- Objectif : rattacher les nouveaux scans aux comptes patients Supabase Auth,
-- tout en gardant le scan public accessible sans compte.

alter table public.scans
add column if not exists patient_id uuid references auth.users(id) on delete set null;

alter table public.scans
add column if not exists patient_email text;

alter table public.scans
add column if not exists patient_full_name text;

create index if not exists scans_patient_created_idx
on public.scans (patient_id, created_at desc);

alter table public.scans enable row level security;

drop policy if exists "Public insert scans" on public.scans;
create policy "Public insert scans"
on public.scans
for insert
to anon
with check (
  consent = true
  and patient_id is null
  and patient_email is null
  and patient_full_name is null
);

drop policy if exists "Authenticated select scans" on public.scans;
drop policy if exists "Patients select own scans" on public.scans;
create policy "Patients select own scans"
on public.scans
for select
to authenticated
using (patient_id = auth.uid());

drop policy if exists "Patients insert own scans" on public.scans;
create policy "Patients insert own scans"
on public.scans
for insert
to authenticated
with check (
  consent = true
  and patient_id = auth.uid()
);

drop policy if exists "Authenticated delete scans" on public.scans;
drop policy if exists "Patients delete own scans" on public.scans;
create policy "Patients delete own scans"
on public.scans
for delete
to authenticated
using (patient_id = auth.uid());
