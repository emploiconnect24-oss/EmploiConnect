# Backend EmploiConnect

API Node.js (Express) avec **authentification custom** (JWT + bcrypt) et Supabase (service_role).

## Démarrage

```bash
npm install
npm run dev    # avec rechargement auto
# ou
npm start
```

Le serveur écoute sur `http://localhost:3000` (ou `PORT` dans `.env`).

## Variables d'environnement (.env)

- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` : connexion Supabase (obligatoire)
- `JWT_SECRET` : clé pour signer les tokens (obligatoire pour auth)
- `JWT_EXPIRES_IN` : durée de vie du token (ex. `7d`)
- `PORT` : port du serveur (défaut 3000)
- `CORS_ORIGIN` : origines autorisées, séparées par des virgules
- **NLP (optionnel)** : `RAPIDAPI_KEY` pour activer le NLP externe. Avec la clé :
  - **Resume Parser** : extraction structurée du CV (compétences, expérience) via une API RapidAPI (ex. Resume Parser API).
  - **Text Similarity** : score de compatibilité candidat/offre par similarité sémantique (ex. Twinword Text Similarity).
  - Variables optionnelles : `RAPIDAPI_SIMILARITY_HOST`, `RAPIDAPI_RESUME_PARSER_HOST`, `RAPIDAPI_RESUME_PARSER_PATH`.
  - Sans clé : le backend utilise l’extraction locale (mots-clés) et le score par recoupement de termes.

## Endpoints

| Méthode | Route | Auth | Description |
|--------|--------|------|-------------|
| GET | `/api/health` | Non | Santé de l'API |
| POST | `/api/auth/register` | Non | Inscription (body: email, mot_de_passe, nom, role) |
| POST | `/api/auth/login` | Non | Connexion (body: email, mot_de_passe) |
| GET | `/api/users/me` | Bearer | Profil de l'utilisateur connecté |
| PATCH | `/api/users/me` | Bearer | Mise à jour du profil |
| GET | `/api/offres` | Optionnel | Liste offres (filtres: statut, domaine, localisation, type_contrat; ?mes=1 pour « mes offres » entreprise; admin voit toutes sans filtre statut) |
| GET | `/api/offres/suggestions` | Bearer (chercheur) | Offres recommandées selon le CV (score de compatibilité) |
| GET | `/api/offres/:id` | Optionnel | Détail d'une offre |
| POST | `/api/offres` | Bearer (entreprise) | Créer une offre |
| PATCH | `/api/offres/:id` | Bearer (propriétaire ou admin) | Modifier une offre |
| DELETE | `/api/offres/:id` | Bearer (propriétaire ou admin) | Supprimer une offre |
| GET | `/api/candidatures` | Bearer | Chercheur : mes candidatures. Entreprise : ?offre_id=xxx obligatoire. Admin : toutes |
| GET | `/api/candidatures/:id` | Bearer | Détail d'une candidature |
| POST | `/api/candidatures` | Bearer (chercheur) | Postuler (body: offre_id, lettre_motivation?, cv_id?). Score calculé si CV présent. |
| PATCH | `/api/candidatures/:id` | Bearer | Chercheur : statut=annulee uniquement. Entreprise/admin : tous les statuts |
| POST | `/api/cv/upload` | Bearer (chercheur) | Envoyer un CV (multipart, champ `file`, PDF ou DOCX, max 5 Mo) |
| GET | `/api/cv/me` | Bearer (chercheur) | Mon CV (métadonnées + compétences extraites) |
| GET | `/api/cv/download-url` | Bearer | URL signée : sans param = mon CV ; `?candidature_id=xxx` = CV de la candidature (entreprise propriétaire) |
| POST | `/api/signalements` | Bearer | Signaler un contenu (body: type_objet, objet_id, raison). type_objet: offre \| profil \| candidature |
| GET | `/api/admin/utilisateurs` | Bearer (admin) | Liste utilisateurs (query: role, est_valide, est_actif, limit, offset) |
| PATCH | `/api/admin/utilisateurs/:id` | Bearer (admin) | Valider/désactiver un compte (body: est_valide, est_actif) |
| GET | `/api/admin/statistiques` | Bearer (admin) | Tableau de bord (comptages: chercheurs, entreprises, offres, candidatures, CV, signalements) |
| GET | `/api/admin/signalements` | Bearer (admin) | Liste signalements (query: statut, type_objet, limit, offset) |
| PATCH | `/api/admin/signalements/:id` | Bearer (admin) | Traiter un signalement (body: statut = traite \| rejete) |

**Rôles** : `chercheur`, `entreprise`, `admin`.  
Les comptes non-admin sont créés avec `est_valide = false` ; un administrateur doit les valider pour qu’ils puissent se connecter.

## Test rapide

```bash
# Santé
curl http://localhost:3000/api/health

# Inscription
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","mot_de_passe":"password123","nom":"User","role":"chercheur"}'

# Connexion
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","mot_de_passe":"password123"}'

# Profil (remplacer TOKEN par le token reçu)
curl http://localhost:3000/api/users/me -H "Authorization: Bearer TOKEN"
```

## Structure

```
backend/
├── src/
│   ├── config/       # Supabase, constantes (rôles, statuts)
│   ├── helpers/      # userProfile (chercheurId, entrepriseId)
│   ├── middleware/   # auth (JWT), optionalAuth, requireRole
│   ├── routes/       # auth, users, offres, candidatures, cv, signalements, admin
│   ├── services/     # cvExtract, matchingScore
│   └── index.js      # point d'entrée
├── .env
├── package.json
└── README.md
```

**CV** : le bucket Supabase `cv-files` doit exister (Storage). À la création du projet, exécuter le schéma SQL puis créer le bucket dans Supabase Dashboard (Storage → New bucket, nom `cv-files`, privé).

Le backend couvre l’ensemble du cahier des charges : auth, profils, offres, candidatures, CV (upload + analyse texte + score), signalements, tableau de bord admin et modération des comptes.

### NLP (RapidAPI)

Pour un projet plus robuste et pertinent, configurez une clé **RapidAPI** (gratuite) :

1. Créer un compte sur [rapidapi.com](https://rapidapi.com).
2. S’abonner aux APIs (plans gratuits) :
   - **Text Similarity** (ex. [Twinword Text Similarity](https://rapidapi.com/twinword/api/text-similarity)) pour le score de matching sémantique.
   - **Resume Parser** (ex. [Resume Parser API](https://rapidapi.com/hiteshw02/api/resumeparser1) ou équivalent) pour l’extraction structurée du CV.
3. Copier la clé « X-RapidAPI-Key » et l’ajouter dans `.env` : `RAPIDAPI_KEY=votre_cle`.

Une fois la clé définie : à l’upload d’un CV, le backend peut enrichir les compétences et l’expérience via l’API ; au calcul du score (candidature ou suggestions d’offres), la similarité sémantique est utilisée quand l’API est disponible.

**Guide détaillé** : voir **[GUIDE_RAPIDAPI_ENV.md](GUIDE_RAPIDAPI_ENV.md)** pour obtenir pas à pas les valeurs (RAPIDAPI_KEY, hosts, path) sur le site RapidAPI et les reporter dans le fichier `.env`.
