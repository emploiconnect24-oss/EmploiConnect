# EmploiConnect — Guide d'installation

## Prérequis

| Outil | Version | Téléchargement |
|-------|---------|----------------|
| Node.js | >= 18.x | https://nodejs.org |
| Flutter | >= 3.x  | https://flutter.dev |
| Git     | Dernière | https://git-scm.com |
| VS Code | Dernière | https://code.visualstudio.com |

## 1. Cloner le projet

```bash
git clone https://github.com/VOTRE_REPO/emploiconnect.git
cd emploiconnect
```

## 2. Installation Backend (Node.js)

```bash
cd backend
npm install
```

### Dépendances backend installées :

- `@supabase/supabase-js` `^2.45.0`
- `axios` `^1.14.0`
- `bcryptjs` `^2.4.3`
- `cors` `^2.8.5`
- `dotenv` `^16.4.5`
- `express` `^4.21.0`
- `express-rate-limit` `^7.5.0`
- `form-data` `^4.0.5`
- `helmet` `^7.0.0`
- `jsonwebtoken` `^9.0.2`
- `mammoth` `^1.8.0`
- `multer` `^1.4.5-lts.1`
- `node-cron` `^3.0.3`
- `nodemailer` `^6.10.1`
- `pdf-parse` `^1.1.1`
- `pdfkit` `^0.15.2`
- `redis` `^4.7.0` (optionnel — présence « en train d’écrire » multi-instance)
- `sharp` `^0.34.5`

### Redis (optionnel, recommandé en production)

Si vous déployez **plusieurs instances** de l’API Node, définissez `REDIS_URL` dans le `.env` du backend pour synchroniser l’indicateur de frappe entre tous les processus. Exemples :

- Local : `REDIS_URL=redis://127.0.0.1:6379`
- Railway / Render : variable fournie par l’addon Redis

Sans `REDIS_URL`, l’API utilise un **fallback mémoire** (suffisant en dev sur une seule instance).

### Configurer le fichier .env

```bash
cp .env.example .env
# Ouvrir .env et remplir les valeurs
```

Contenu du .env à remplir :
```env
# Supabase
SUPABASE_URL=https://VOTRE_PROJET.supabase.co
SUPABASE_SERVICE_ROLE_KEY=VOTRE_CLE_SERVICE_ROLE

# JWT
JWT_SECRET=VOTRE_SECRET_JWT_RANDOM

# RapidAPI
RAPIDAPI_KEY=VOTRE_CLE_RAPIDAPI

# Anthropic Claude (optionnel)
ANTHROPIC_API_KEY=sk-ant-api03-...

# Email SMTP (optionnel)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
EMAIL_USER=votre@gmail.com
EMAIL_PASSWORD=votre_app_password

# Serveur
PORT=3000
NODE_ENV=development

# Redis (optionnel) — messagerie « en train d’écrire » entre plusieurs instances API
# REDIS_URL=redis://127.0.0.1:6379
```

### Démarrer le backend

```bash
npm run dev
# Le serveur démarre sur http://localhost:3000
```

---

## 3. Installation Frontend (Flutter)

```bash
cd frontend
flutter pub get
```

### Dépendances Flutter installées :

- `go_router` `^13.0.0`
- `cupertino_icons` `^1.0.8`
- `http` `^1.2.0`
- `shared_preferences` `^2.2.2`
- `provider` `^6.1.2`
- `dio` `^5.4.0`
- `path_provider` `^2.1.2`
- `permission_handler` `^11.3.0`
- `file_picker` `^8.1.2`
- `image_picker` `^1.0.7`
- `http_parser` `^4.0.2`
- `intl` `^0.20.1`
- `url_launcher` `^6.3.0`
- `flutter_animate` `^4.5.0`
- `google_fonts` `^6.2.1`
- `cached_network_image` `^3.3.1`
- `animate_do` `^3.3.4`
- `lottie` `^3.1.0`
- `smooth_page_indicator` `^1.2.0`
- `font_awesome_flutter` `^10.7.0`
- `shimmer` `^3.0.0`
- `timeago` `^3.6.1`
- `visibility_detector` `^0.4.0+2`
- `fl_chart` `^1.2.0`

### Configurer l'URL du backend

```dart
// Dans frontend/lib/config/api_config.dart
// Changer selon votre environnement :

static const String baseUrl =
  'http://localhost:3000';     // Web local
  // 'http://10.0.2.2:3000';  // Android émulateur
  // 'http://192.168.X.X:3000'; // Appareil physique
```

### Démarrer le frontend

```bash
# Web (Chrome)
flutter run -d chrome --web-port 3001

# Android
flutter run -d android

# Voir les appareils disponibles
flutter devices
```

---

## 4. Base de données (Supabase)

```
1. Créer un compte sur https://supabase.com
2. Créer un nouveau projet
3. Aller dans Settings → API
4. Copier :
   → Project URL → SUPABASE_URL
   → service_role key → SUPABASE_SERVICE_ROLE_KEY
5. Exécuter les migrations SQL :
   → Aller dans SQL Editor
   → Exécuter les fichiers dans database/migrations/
   → Dans l'ordre numérique (001_, 002_, etc.)
```

---

## 5. Ordre de démarrage

```bash
# Terminal 1 — Backend
cd backend && npm run dev

# Terminal 2 — Frontend
cd frontend && flutter run -d chrome --web-port 3001
```

---

## 6. Comptes de test

```
Admin :
  Email    : admin@emploiconnect.com
  Password : [METTRE LE MOT DE PASSE]

Recruteur :
  Email    : recruteur@test.com
  Password : [METTRE LE MOT DE PASSE]

Candidat :
  Email    : candidat@test.com
  Password : [METTRE LE MOT DE PASSE]
```

---

## 7. Problèmes fréquents

### Backend ne démarre pas
```bash
# Vérifier Node.js
node --version  # doit être >= 18

# Réinstaller les dépendances
rm -rf node_modules && npm install

# Vérifier le .env
cat .env  # toutes les variables remplies ?
```

### Flutter erreurs de compilation
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Erreur CORS
```
→ Vérifier que le backend tourne sur le port 3000
→ Vérifier l'URL dans api_config.dart
```

### Scores IA = 0
```
→ Mettre la clé Anthropic dans Admin → Paramètres → IA
→ Vider le cache : DELETE FROM offres_scores_cache;
```

