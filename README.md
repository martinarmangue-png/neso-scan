# NESO Scan V1 — Pack Supabase

## Fichiers
- `scan.html` : lien patient NESO Scan avec enregistrement Supabase.
- `dashboard.html` : mini dashboard praticien protégé par connexion Supabase.
- `dashboard-v2.html` : dashboard praticien connecté à l'API admin sécurisée.
- `app-v2.html` : prototype web app mobile patient avec Accueil, Suivi, Exercices, Dossier et Explore.
- `manifest.webmanifest`, `neso-icon.svg`, `sw.js` : base PWA pour une installation mobile.
- `schema.sql` : table + règles de sécurité Supabase.

## Installation rapide
1. Créer un projet Supabase.
2. Aller dans SQL Editor.
3. Coller `schema.sql` et cliquer Run.
4. Dans Supabase > Authentication > Users, créer ton compte praticien.
5. Dans Supabase > Project Settings > API, copier :
   - Project URL
   - anon public key
6. Remplacer dans `scan.html` et `dashboard.html` :
   - `https://TON-PROJET.supabase.co`
   - `TON-ANON-KEY`

## Sécurité V1
- Les patients anonymes peuvent seulement insérer un scan.
- La lecture des scans est réservée aux comptes connectés.
- Aucun document médical lourd n’est stocké dans cette V1.
- Un consentement explicite est demandé avant envoi.

## Déploiement Vercel
Tu peux mettre `scan.html` en page publique et `dashboard.html` en page dashboard privée.
