# Neso Santé — Suite patient et praticien

## Fichiers
- `index.html` : hub public Neso Santé avec accès à Physio Scan, à l'espace patient et au dashboard praticien.
- `scan.html` : lien patient Physio Scan avec enregistrement Supabase.
- `dashboard.html` : mini dashboard praticien protégé par connexion Supabase.
- `dashboard-v2.html` : dashboard praticien connecté à l'API admin sécurisée.
- `app-v2.html` : web app mobile patient avec compte Supabase Auth, Accueil, Suivi, Exercices, Dossier et documents.
- `manifest.webmanifest`, `neso-icon.svg`, `sw.js` : base PWA pour une installation mobile.
- `schema.sql` : table + règles de sécurité Supabase.

## Installation rapide
1. Créer un projet Supabase.
2. Aller dans SQL Editor.
3. Coller `schema.sql` et cliquer Run. Le script crée aussi les tables V2, le bucket privé `patient-documents` et les policies RLS.
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

## Sécurité V2
- Les patients créent un compte via Supabase Auth.
- Les profils patients sont dans `patient_profiles`.
- Les documents sont enregistrés dans `patient_documents` et stockés dans le bucket privé `patient-documents`.
- Les policies RLS limitent chaque patient à ses propres lignes et à son propre dossier Storage.

## Déploiement Vercel
La page racine `index.html` sert de porte d'entrée. Les patients peuvent aller vers Physio Scan (`scan.html`) ou l'espace patient (`app-v2.html`), et les praticiens vers `dashboard-v2.html`.
