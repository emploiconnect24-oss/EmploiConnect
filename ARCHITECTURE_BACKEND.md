# Analyse technique — Backend, base de données & connexion Flutter

Document généré à partir du dépôt (structure de code et fichiers versionnés). Les secrets (`.env`) et l’état réel de la base Supabase ne sont pas inclus.

---

## 1. Stack backend

- **Framework : Node.js avec Express** (`express` ^4.21.0), point d’entrée `backend/src/index.js`.
- Ce n’est **ni** Laravel, **ni** Django, **ni** FastAPI.

---

## 2. Base de données (SGBD + version)

- **SGBD : PostgreSQL**, hébergé via **Supabase** (client `@supabase/supabase-js`).
- **Version PostgreSQL : non indiquée dans le projet** ; elle dépend du projet Supabase (dashboard Supabase → *Database* / *Settings*). Le dépôt ne fixe pas de numéro de version.

---

## 3. Tables / modèles et colonnes (schéma versionné)

Le schéma documenté est dans `database/supabase_schema.sql`.

| Table | Colonnes |
|--------|-----------|
| **utilisateurs** | `id` (UUID PK), `nom`, `email` (unique), `mot_de_passe`, `role` (check: chercheur, entreprise, admin), `telephone`, `adresse`, `photo_url`, `est_actif`, `est_valide`, `date_creation`, `date_modification` |
| **chercheurs_emploi** | `id`, `utilisateur_id` (FK unique → utilisateurs), `date_naissance`, `genre`, `competences` (JSONB), `niveau_etude`, `disponibilite`, `date_creation`, `date_modification` |
| **entreprises** | `id`, `utilisateur_id` (FK unique), `nom_entreprise`, `description`, `secteur_activite`, `taille_entreprise`, `site_web`, `logo_url`, `adresse_siege`, `date_creation`, `date_modification` |
| **administrateurs** | `id`, `utilisateur_id` (FK unique), `niveau_acces`, `date_creation` |
| **cv** | `id`, `chercheur_id` (FK unique), `fichier_url`, `nom_fichier`, `type_fichier`, `taille_fichier`, `competences_extrait` (JSONB), `experience` (JSONB), `domaine_activite`, `niveau_experience`, `texte_complet`, `date_upload`, `date_analyse`, `date_modification` |
| **offres_emploi** | `id`, `entreprise_id` (FK), `titre`, `description`, `exigences`, `competences_requises` (JSONB), `salaire_min`, `salaire_max`, `devise`, `localisation`, `type_contrat`, `niveau_experience_requis`, `domaine`, `statut`, `nombre_postes`, `date_publication`, `date_limite`, `date_creation`, `date_modification` |
| **candidatures** | `id`, `chercheur_id`, `offre_id`, `cv_id`, `date_candidature`, `statut`, `score_compatibilite`, `lettre_motivation`, `date_modification` + contrainte unique `(chercheur_id, offre_id)` |
| **statistiques** | `id`, `date_collecte`, `nombre_chercheurs`, `nombre_entreprises`, `nombre_offres_actives`, `nombre_candidatures`, `nombre_candidatures_acceptees`, `nombre_cv_analyses` + unique sur `date_collecte` |
| **signalements** | `id`, `utilisateur_signalant_id`, `type_objet`, `objet_id`, `raison`, `statut`, `date_signalement`, `date_traitement`, `admin_traitant_id` |

**Vues SQL** dans le même fichier : `v_offres_completes`, `v_candidatures_completes`.

---

## 4. Migrations

- **Pas de migrations** type Laravel / Django / Alembic dans le dépôt.
- Un **script SQL unique** : `database/supabase_schema.sql`, à exécuter manuellement dans le SQL Editor Supabase (voir `database/README.md`).
- **Statut « exécuté ou non »** : à vérifier sur le projet Supabase (dashboard ou `SELECT` sur `information_schema.tables`).

---

## 5. Authentification

- **JWT** (`jsonwebtoken`) + **bcrypt** (`bcryptjs`) sur la table `utilisateurs`.
- Middleware : `backend/src/middleware/auth.js` — header `Authorization: Bearer <token>`.
- **Pas** Laravel Sanctum, **pas** Passport, **pas** sessions serveur classiques.
- **Supabase Auth** n’est **pas** utilisée pour login/register dans le code actuel (client Supabase en **service_role** pour la DB). La documentation `database/` peut mentionner Supabase Auth ; l’implémentation réelle est **auth custom + JWT**.

---

## 6. Routes API (préfixe global `/api`)

Toutes les routes sont montées sous `app.use('/api', routes)` dans `backend/src/index.js`.

| Méthode | URL | Rôle / notes |
|---------|-----|----------------|
| **GET** | `/api/health` | Santé API |
| **POST** | `/api/auth/register` | Inscription |
| **POST** | `/api/auth/login` | Connexion (rate limit dédié) |
| **GET** | `/api/users/me` | Profil connecté (auth) |
| **PATCH** | `/api/users/me` | Mise à jour profil (auth) |
| **GET** | `/api/offres` | Liste offres (+ query params) |
| **GET** | `/api/offres/suggestions` | Suggestions (chercheur, auth) |
| **GET** | `/api/offres/:id` | Détail offre |
| **POST** | `/api/offres` | Créer offre (entreprise) |
| **PATCH** | `/api/offres/:id` | Modifier offre |
| **DELETE** | `/api/offres/:id` | Supprimer offre |
| **POST** | `/api/candidatures` | Postuler (chercheur) |
| **GET** | `/api/candidatures` | Liste selon rôle (+ `offre_id` pour entreprise) |
| **GET** | `/api/candidatures/:id` | Détail |
| **PATCH** | `/api/candidatures/:id` | Statut (règles par rôle) |
| **POST** | `/api/cv/upload` | Upload CV multipart `file` |
| **GET** | `/api/cv/me` | Mon CV |
| **GET** | `/api/cv/download-url` | URL signée (+ `candidature_id` optionnel) |
| **POST** | `/api/signalements` | Créer signalement |
| **GET** | `/api/admin/utilisateurs` | Liste users (admin) |
| **PATCH** | `/api/admin/utilisateurs/:id` | Valider / activer (admin) |
| **GET** | `/api/admin/statistiques` | Compteurs temps réel |
| **GET** | `/api/admin/signalements` | Liste signalements |
| **PATCH** | `/api/admin/signalements/:id` | Traiter signalement |

**Aucune route `PUT`** définie dans le backend listé.

---

## 7. Flutter ↔ backend (`http` / `dio`, base URL)

- **Client HTTP principal :** package **`http`** (`frontend/lib/services/api_service.dart`).
- **`dio`** est déclaré dans `pubspec.yaml` mais **sans utilisation** dans `frontend/lib/` (aucun import `dio` repéré).
- **Base URL** (`frontend/lib/config/api_config.dart`) :
  - **Web :** `http://localhost:3000`
  - **Autres plateformes (ex. émulateur Android) :** `http://10.0.2.2:3000`
- **Préfixe API :** `apiPrefix = '/api'` → URLs du type `http://localhost:3000/api/...`.

---

## 8. Données déjà en base

- **Non déterminable depuis le dépôt** (pas de dump ni seed versionné avec volumes).
- Pour les volumes : **Table Editor Supabase** ou requêtes `COUNT(*)` sur chaque table.

---

## 9. Fichiers de configuration

- **`backend/.env` n’est pas versionné** (ne pas commiter les secrets).
- **Variables attendues** (d’après le code et la doc) :

| Variable | Rôle |
|----------|------|
| `SUPABASE_URL` | Obligatoire (`backend/src/config/supabase.js`) |
| `SUPABASE_SERVICE_ROLE_KEY` | Obligatoire |
| `JWT_SECRET` | Obligatoire (`backend/src/index.js`, `middleware/auth.js`) |
| `SUPABASE_STORAGE_BUCKET` | Optionnel, défaut `cv-files` |
| `JWT_EXPIRES_IN` | Optionnel, défaut `7d` |
| `PORT` | Optionnel, défaut `3000` |
| `CORS_ORIGIN` | Optionnel |
| `CORS_STRICT` | Optionnel (`1` / `true` pour mode strict) |
| `RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_MAX` | Rate limiting global `/api` |
| `LOGIN_RATE_LIMIT_WINDOW_MS`, `LOGIN_RATE_LIMIT_MAX` | Rate limiting `/auth/login` |
| `RAPIDAPI_KEY`, `RAPIDAPI_SIMILARITY_HOST`, `RAPIDAPI_RESUME_PARSER_HOST` | NLP optionnel (`backend/src/config/rapidApi.js`) |

Documentation complémentaire : `database/README.md`, `database/supabase_config.md` (ex. `SUPABASE_ANON_KEY`, `DATABASE_URL`).

---

## 10. Écarts / manques côté backend (par rapport au produit riche)

- **Pas d’API** dans ce dépôt pour : messagerie temps réel, notifications in-app/push, alertes emploi, favoris / offres sauvegardées, nombre de fonctionnalités « avancées » des PRD — souvent **UI ou mock** côté Flutter.
- Table **`statistiques`** présente dans le schéma ; **`GET /api/admin/statistiques`** fait des **comptages à la volée** (pas de remplissage planifié de `statistiques`).
- **Supabase Auth** non utilisée pour les flux login du backend.
- **`dio`** : dépendance Flutter potentiellement superflue si tout passe par `http`.

---

## Fichiers clés à consulter

| Sujet | Chemin |
|--------|--------|
| Entrée API | `backend/src/index.js` |
| Agrégation routes | `backend/src/routes/index.js` |
| Schéma SQL | `database/supabase_schema.sql` |
| Client Flutter API | `frontend/lib/services/api_service.dart` |
| Base URL Flutter | `frontend/lib/config/api_config.dart` |
