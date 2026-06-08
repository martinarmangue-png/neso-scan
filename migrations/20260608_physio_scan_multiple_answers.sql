-- Physio Scan - migration réponses multiples
-- À exécuter dans Supabase > SQL Editor.
-- Objectif : conserver les anciens scans tout en permettant plusieurs réponses
-- pour evolution et objectif.

alter table public.scans add column if not exists scan_type text;
alter table public.scans add column if not exists scan_type_label text;
alter table public.scans add column if not exists douleur_depuis text;
alter table public.scans add column if not exists duration_ms bigint;
alter table public.scans add column if not exists source text default 'neso_scan_v1';
alter table public.scans add column if not exists evolution text[] default '{}';
alter table public.scans add column if not exists objectif text[] default '{}';

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
          else array(
            select btrim(answer)
            from unnest(string_to_array(evolution, ',')) as value(answer)
            where btrim(answer) <> ''
          )
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
          else array(
            select btrim(answer)
            from unnest(string_to_array(objectif, ',')) as value(answer)
            where btrim(answer) <> ''
          )
        end
      );
  end if;

  alter table public.scans alter column objectif set default '{}';
end $$;

create index if not exists scans_scan_type_created_idx
on public.scans (scan_type, created_at desc);
