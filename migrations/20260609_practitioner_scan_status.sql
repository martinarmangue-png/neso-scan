-- Physio Scan - statuts praticien
-- À exécuter dans Supabase > SQL Editor après la migration réponses multiples.

alter table public.scans
add column if not exists practitioner_status text not null default 'new';

alter table public.scans
add column if not exists practitioner_status_updated_at timestamptz;

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
