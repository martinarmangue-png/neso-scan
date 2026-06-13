-- NESO Sante - authentification praticien beta
-- A executer dans Supabase > SQL Editor.

create table if not exists public.practitioner_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists practitioner_profiles_email_idx
on public.practitioner_profiles (lower(email));

create index if not exists practitioner_profiles_active_idx
on public.practitioner_profiles (is_active)
where is_active = true;

alter table public.practitioner_profiles enable row level security;

grant usage on schema public to authenticated, service_role;

revoke all on table public.practitioner_profiles from anon, authenticated;
grant select on table public.practitioner_profiles to authenticated;
grant select, insert, update, delete on table public.practitioner_profiles to service_role;

drop policy if exists "Practitioners select own active profile" on public.practitioner_profiles;
create policy "Practitioners select own active profile"
on public.practitioner_profiles
for select
to authenticated
using (
  auth.uid() is not null
  and id = auth.uid()
  and is_active = true
);
