# Neso Santé — Suite patient et praticien

## Fichiers
- `index.html` : hub public Neso Santé avec accès à Physio Scan, à l'espace patient et au dashboard praticien.
- `scan.html` : lien patient Physio Scan avec enregistrement Supabase.
- `dashboard.html` : mini dashboard praticien protégé par connexion Supabase.
- `dashboard-v2.html` : dashboard praticien connecté à l'API admin sécurisée.
- `app-v2.html` : web app mobile patient avec compte Supabase Auth, onboarding patient, Accueil, Suivi, Exercices, Dossier et documents.
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

## V3 Produit
- L'accueil oriente clairement vers `Lancer Physio Scan`, `Je suis patient` ou `Je suis praticien`.
- L'espace patient propose un profil enrichi : praticien référent, motif de suivi, objectif, date de naissance et téléphone.
- Les documents affichent une preview locale avant envoi et sont classés automatiquement quand le nom du fichier le permet.
- Le dashboard praticien devient une inbox : priorités, documents reçus, fiche patient et notes d'action.
- Les champs V3 sont sauvegardés côté Supabase si `schema.sql` est appliqué ; sinon l'app garde un fallback local côté patient.

## Migration Physio Scan réponses multiples
Pour stocker les objectifs et évolutions en vrais tableaux Supabase, exécuter dans Supabase > SQL Editor :

```sql
-- migrations/20260608_physio_scan_multiple_answers.sql
```

La migration est idempotente : elle ajoute les colonnes manquantes, convertit les anciennes valeurs texte de `evolution` et `objectif` en `text[]`, puis garde les règles RLS existantes.

## Déploiement Vercel
La page racine `index.html` sert de porte d'entrée. Les patients peuvent aller vers Physio Scan (`scan.html`) ou l'espace patient (`app-v2.html`), et les praticiens vers `dashboard-v2.html`.
