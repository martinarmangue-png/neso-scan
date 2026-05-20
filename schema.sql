-- NESO Scan - Supabase schema V1
-- À coller dans Supabase > SQL Editor > Run

create extension if not exists pgcrypto;

create table if not exists public.scans (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  prenom text,
  zones text[] default '{}',
  duree text,
  type_douleur text[] default '{}',
  score_douleur int check (score_douleur between 0 and 10),
  gene text[] default '{}',
  evolution text,
  objectif text,
  consent boolean default false,
  source text default 'neso_scan_v1'
);

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
