# Analyse du projet EmploiConnect (état au 2026)

## Structure du dépôt

| Dossier | Rôle |
|---------|------|
| `backend/` | API Node.js (Express), JWT, Supabase `service_role`, routes auth, offres, candidatures, CV, admin, signalements |
| `frontend/` | Application Flutter (connexion API, écrans auth + accueil) |
| `database/` | Schéma SQL Supabase, documentation configuration |
| `docs/` | Documentation (Git, analyse) |
| `les diagrammes/` | Fichiers UML / explications (hors code) |

## Fonctionnalités backend (implémentées)

- Authentification : register, login, profil `GET/PATCH /users/me`
- Rôles : `chercheur`, `entreprise`, `admin` (validation admin des comptes non-admin)
- Offres : CRUD, filtres, suggestions avec score de compatibilité
- Candidatures : postulation, liste par rôle, statuts
- CV : upload PDF/DOCX, extraction locale + option RapidAPI
- Admin : utilisateurs, statistiques, signalements
- Sécurité : Helmet, rate limit global + login, validations, logger

## Frontend Flutter (état actuel)

- Auth : login, register, home avec déconnexion
- Services HTTP + stockage token (`shared_preferences`)
- À étendre : offres, candidatures, CV, admin

## Cohérence & points d’attention

- **Backend** : cohérent avec le cahier des charges fonctionnel.
- **Secrets** : uniquement dans `backend/.env` (non versionné si `.gitignore` respecté).
- **Historique Git** : si des clés ont été poussées par le passé, les régénérer sur Supabase/RapidAPI.

## Automatisation Git

- Hooks dans `.githooks/` (pre-commit, commit-msg) — pas de push automatique (risque).
- Script `scripts/save-and-push.ps1` pour un flux contrôlé add → commit → push.
