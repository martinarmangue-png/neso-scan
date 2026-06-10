-- NESO Sante - finalisation acces patient et RLS
-- A executer dans Supabase > SQL Editor apres les migrations du 2026-06-09.
--
-- Objectif :
-- 1. Exposer explicitement les tables utiles a l'API Data pour anon/authenticated.
-- 2. Garder la RLS comme barriere principale de lecture/ecriture patient.
-- 3. Fermer la lecture directe de scan_events aux patients connectes.

grant usage on schema public to anon, authenticated;

-- Scans :
-- - anon peut uniquement inserer un scan public via la policy "Public insert scans".
-- - authenticated peut lire/creer/supprimer uniquement ses propres scans via RLS.
revoke all on table public.scans from anon, authenticated;
grant insert on table public.scans to anon;
grant select, insert, delete on table public.scans to authenticated;

-- Tracking Physio Scan :
-- - anon peut inserer les evenements publics.
-- - aucune lecture directe cote patient ; le dashboard lit via l'API admin service-role.
revoke all on table public.scan_events from anon, authenticated;
grant insert on table public.scan_events to anon;

drop policy if exists "Authenticated select scan events" on public.scan_events;

-- Profils patients :
-- RLS limite chaque operation a id = auth.uid().
revoke all on table public.patient_profiles from anon, authenticated;
grant select, insert, update on table public.patient_profiles to authenticated;

-- Documents patients :
-- RLS limite chaque operation a patient_id = auth.uid().
revoke all on table public.patient_documents from anon, authenticated;
grant select, insert, update, delete on table public.patient_documents to authenticated;
