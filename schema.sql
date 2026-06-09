-- Physio Scan - Supabase schema V2
-- À coller dans Supabase > SQL Editor > Run

create extension if not exists pgcrypto;

create table if not exists public.scans (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  scan_type text,
  scan_type_label text,
  prenom text,
  zones text[] default '{}',
  duree text,
  douleur_depuis text,
  type_douleur text[] default '{}',
  score_douleur int check (score_douleur between 0 and 10),
  gene text[] default '{}',
  evolution text[] default '{}',
  objectif text[] default '{}',
  duration_ms bigint,
  consent boolean default false,
  source text default 'neso_scan_v1',
  practitioner_status text not null default 'new',
  practitioner_status_updated_at timestamptz,
  constraint scans_practitioner_status_check
    check (practitioner_status in ('new', 'seen', 'callback', 'handled'))
);

alter table public.scans add column if not exists scan_type text;
alter table public.scans add column if not exists scan_type_label text;
alter table public.scans add column if not exists douleur_depuis text;
alter table public.scans add column if not exists duration_ms bigint;
alter table public.scans add column if not exists source text default 'neso_scan_v1';
alter table public.scans add column if not exists evolution text[] default '{}';
alter table public.scans add column if not exists objectif text[] default '{}';
alter table public.scans add column if not exists practitioner_status text not null default 'new';
alter table public.scans add column if not exists practitioner_status_updated_at timestamptz;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'scans'
      and column_name = 'evolution'
      and udt_name = 'text'
  ) then
    alter table public.scans alter column evolution drop default;
    alter table public.scans
      alter column evolution type text[]
      using (
        case
          when evolution is null or btrim(evolution) = '' then '{}'::text[]
          else regexp_split_to_array(btrim(evolution), '[[:space:]]*,[[:space:]]*')
        end
      );
  end if;

  alter table public.scans alter column evolution set default '{}';
end $$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'scans'
      and column_name = 'objectif'
      and udt_name = 'text'
  ) then
    alter table public.scans alter column objectif drop default;
    alter table public.scans
      alter column objectif type text[]
      using (
        case
          when objectif is null or btrim(objectif) = '' then '{}'::text[]
          else regexp_split_to_array(btrim(objectif), '[[:space:]]*,[[:space:]]*')
        end
      );
  end if;

  alter table public.scans alter column objectif set default '{}';
end $$;

create index if not exists scans_scan_type_created_idx
on public.scans (scan_type, created_at desc);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'scans_practitioner_status_check'
      and conrelid = 'public.scans'::regclass
  ) then
    alter table public.scans
    add constraint scans_practitioner_status_check
    check (practitioner_status in ('new', 'seen', 'callback', 'handled'));
  end if;
end $$;

update public.scans
set practitioner_status = 'new'
where practitioner_status is null
   or practitioner_status not in ('new', 'seen', 'callback', 'handled');

create index if not exists scans_practitioner_status_created_idx
on public.scans (practitioner_status, created_at desc);

alter table public.scans enable row level security;

-- Les patients anonymes peuvent créer un scan.
drop policy if exists "Public insert scans" on public.scans;
create policy "Public insert scans"
on public.scans
for insert
to anon
with check (consent = true);

-- Seuls les praticiens connectés peuvent lire les scans.
drop policy if exists "Authenticated select scans" on public.scans;
create policy "Authenticated select scans"
on public.scans
for select
to authenticated
using (true);

-- Optionnel : permettre suppression/modification uniquement aux comptes authentifiés.
drop policy if exists "Authenticated delete scans" on public.scans;
create policy "Authenticated delete scans"
on public.scans
for delete
to authenticated
using (true);

create table if not exists public.scan_events (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  session_id text,
  event_type text not null,
  page_id text,
  question_key text,
  question_label text,
  answer jsonb,
  duration_ms bigint,
  is_completed boolean default false,
  is_abandon boolean default false,
  source text default 'physio_scan_v1'
);

create index if not exists scan_events_created_idx
on public.scan_events (created_at desc);

create index if not exists scan_events_session_idx
on public.scan_events (session_id, created_at desc);

alter table public.scan_events enable row level security;

drop policy if exists "Public insert scan events" on public.scan_events;
create policy "Public insert scan events"
on public.scan_events
for insert
to anon
with check (source = 'physio_scan_v1');

drop policy if exists "Authenticated select scan events" on public.scan_events;
create policy "Authenticated select scan events"
on public.scan_events
for select
to authenticated
using (true);

-- NESO App V2 - comptes patients et documents sécurisés

create table if not exists public.patient_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  first_name text,
  full_name text,
  birth_date date,
  phone text,
  practitioner_name text,
  condition_label text,
  recovery_goal text,
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.patient_profiles add column if not exists birth_date date;
alter table public.patient_profiles add column if not exists phone text;
alter table public.patient_profiles add column if not exists practitioner_name text;
alter table public.patient_profiles add column if not exists condition_label text;
alter table public.patient_profiles add column if not exists recovery_goal text;
alter table public.patient_profiles add column if not exists onboarding_completed boolean not null default false;

alter table public.patient_profiles enable row level security;

drop policy if exists "Patients select own profile" on public.patient_profiles;
create policy "Patients select own profile"
on public.patient_profiles
for select
to authenticated
using (id = auth.uid());

drop policy if exists "Patients insert own profile" on public.patient_profiles;
create policy "Patients insert own profile"
on public.patient_profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "Patients update own profile" on public.patient_profiles;
create policy "Patients update own profile"
on public.patient_profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create or replace function public.handle_new_patient_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.patient_profiles (id, email, first_name, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'first_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'first_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_patient_profile on auth.users;
create trigger on_auth_user_created_patient_profile
after insert on auth.users
for each row execute function public.handle_new_patient_user();

create table if not exists public.patient_documents (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  category text not null check (category in ('irm', 'ordonnance', 'autre')),
  title text not null,
  storage_bucket text not null default 'patient-documents',
  storage_path text not null,
  mime_type text,
  file_size bigint,
  source text not null default 'neso_app_v2'
);

create index if not exists patient_documents_patient_created_idx
on public.patient_documents (patient_id, created_at desc);

alter table public.patient_documents enable row level security;

drop policy if exists "Patients select own documents" on public.patient_documents;
create policy "Patients select own documents"
on public.patient_documents
for select
to authenticated
using (patient_id = auth.uid());

drop policy if exists "Patients insert own documents" on public.patient_documents;
create policy "Patients insert own documents"
on public.patient_documents
for insert
to authenticated
with check (patient_id = auth.uid());

drop policy if exists "Patients update own documents" on public.patient_documents;
create policy "Patients update own documents"
on public.patient_documents
for update
to authenticated
using (patient_id = auth.uid())
with check (patient_id = auth.uid());

drop policy if exists "Patients delete own documents" on public.patient_documents;
create policy "Patients delete own documents"
on public.patient_documents
for delete
to authenticated
using (patient_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'patient-documents',
  'patient-documents',
  false,
  15728640,
  array[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif'
  ]
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Patients upload own storage documents" on storage.objects;
create policy "Patients upload own storage documents"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'patient-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Patients read own storage documents" on storage.objects;
create policy "Patients read own storage documents"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'patient-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Patients update own storage documents" on storage.objects;
create policy "Patients update own storage documents"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'patient-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'patient-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Patients delete own storage documents" on storage.objects;
create policy "Patients delete own storage documents"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'patient-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);
