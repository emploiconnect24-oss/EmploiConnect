# EmploiConnect

Plateforme intelligente d’offres et de recherche d’emploi — **Guinée**.

## Stack

| Couche | Technologie |
|--------|-------------|
| Frontend | **Flutter** |
| Backend | **Node.js** (Express) |
| Base de données | **Supabase** (PostgreSQL) |

Voir aussi `Technologies à utiliser.txt`.

## Démarrage rapide

### Backend

```bash
cd backend
npm install
npm run dev
```

API : `http://localhost:3000` — `GET /api/health`

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Configurer l’URL API dans `frontend/lib/config/api_config.dart` si besoin.

### Base de données

Scripts et doc dans le dossier `database/`.

## Git & sécurité

- **Ne jamais committer** `backend/.env` ni de fichiers contenant des clés.
- `.gitignore` à la racine du dépôt.
- Documentation : `docs/GIT_WORKFLOW.md`
- Activer les hooks : `powershell -ExecutionPolicy Bypass -File scripts/install-hooks.ps1`

## Licence / contexte

Projet académique — mémoire de fin de cycle (voir cahier des charges).
