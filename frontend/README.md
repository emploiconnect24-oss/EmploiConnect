# EmploiConnect — Frontend Flutter

Application mobile / web connectée à l’API Node.js du dossier `../backend/`.

## Fonctionnalités (par rôle)

| Rôle | Onglets / écrans |
|------|------------------|
| **Chercheur** | Offres (liste + filtres), Pour moi (suggestions IA), Candidatures, Mon CV (upload PDF/DOCX), Profil |
| **Entreprise** | Mes offres (création / édition / suppression, candidatures par offre), Profil |
| **Admin** | Statistiques, Utilisateurs (validation / activation), Signalements |

Les appels utilisent les routes documentées dans `backend/README.md`.

## Prérequis

- Flutter SDK
- Backend lancé : `cd ../backend && npm run dev`

## Configuration

- **URL API** : `lib/config/api_config.dart`  
  - Web : `http://localhost:3000`  
  - Émulateur Android : `http://10.0.2.2:3000`

### CORS (Flutter Web)

Le backend doit autoriser l’origine du navigateur. Dans `backend/.env`, ajoute le port utilisé par Flutter (souvent aléatoire en dev), par exemple :

```env
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:12345
```

Remplace `12345` par le port affiché quand tu lances `flutter run -d chrome`.

## Commandes

```bash
flutter pub get
flutter run -d chrome
# ou
flutter run -d windows
```

## Structure `lib/`

- `config/` — URL API
- `services/` — clients HTTP (auth, offres, candidatures, CV, utilisateurs, admin)
- `providers/` — état global (auth)
- `screens/` — UI par rôle (`chercheur/`, `entreprise/`, `admin/`, profil commun)
