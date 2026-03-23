# Configuration Supabase - EmploiConnect

## 📋 Instructions de Configuration

### 1. Créer un projet Supabase

1. Allez sur [https://supabase.com](https://supabase.com)
2. Créez un compte ou connectez-vous
3. Cliquez sur "New Project"
4. Remplissez les informations :
   - **Name**: EmploiConnect
   - **Database Password**: (choisissez un mot de passe fort)
   - **Region**: Choisissez la région la plus proche (Europe de l'Ouest recommandé)
5. Cliquez sur "Create new project"

### 2. Exécuter le schéma SQL

1. Dans votre projet Supabase, allez dans **SQL Editor** (menu de gauche)
2. Cliquez sur **New Query**
3. Copiez le contenu du fichier `supabase_schema.sql`
4. Collez-le dans l'éditeur SQL
5. Cliquez sur **Run** (ou Ctrl+Enter)
6. Vérifiez qu'il n'y a pas d'erreurs

### 3. Configurer le Storage pour les CV

1. Allez dans **Storage** (menu de gauche)
2. Cliquez sur **New bucket**
3. Créez un bucket nommé `cv-files` avec les paramètres :
   - **Name**: `cv-files`
   - **Public bucket**: ❌ Non (privé)
   - **File size limit**: 10 MB (ou selon vos besoins)
   - **Allowed MIME types**: `application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document`

4. Configurez les politiques RLS pour le bucket :
   - Les utilisateurs peuvent uploader leur propre CV
   - Les entreprises peuvent lire les CV des candidatures qu'elles reçoivent
   - Les administrateurs ont accès complet

### 4. Récupérer les clés API

1. Allez dans **Settings** → **API**
2. Notez les informations suivantes :
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: (clé publique)
   - **service_role key**: (clé secrète - à garder privée)

### 5. Variables d'environnement

Créez un fichier `.env` dans le dossier `backend/` avec :

```env
# Supabase Configuration
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# Database
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres

# JWT Secret (pour l'authentification)
JWT_SECRET=your_jwt_secret_here

# Storage
SUPABASE_STORAGE_BUCKET=cv-files
```

⚠️ **Important**: Ne commitez JAMAIS le fichier `.env` dans Git !

### 6. Configuration de l'authentification

1. Allez dans **Authentication** → **Settings**
2. Configurez :
   - **Site URL**: `http://localhost:3000` (pour le développement)
   - **Redirect URLs**: Ajoutez les URLs autorisées
   - **Email Auth**: Activez si vous utilisez l'authentification par email

### 7. Vérification

Pour vérifier que tout fonctionne :

1. Allez dans **Table Editor**
2. Vérifiez que toutes les tables sont créées :
   - ✅ utilisateurs
   - ✅ chercheurs_emploi
   - ✅ entreprises
   - ✅ administrateurs
   - ✅ cv
   - ✅ offres_emploi
   - ✅ candidatures
   - ✅ statistiques
   - ✅ signalements

### 8. Données de test (optionnel)

Vous pouvez insérer des données de test pour vérifier :

```sql
-- Créer un administrateur de test
INSERT INTO utilisateurs (nom, email, mot_de_passe, role, est_valide, est_actif)
VALUES ('Admin Test', 'admin@emploiconnect.com', '$2b$10$...', 'admin', true, true);

-- Note: Le mot de passe doit être hashé avec bcrypt
```

## 📚 Structure de la Base de Données

### Tables Principales

1. **utilisateurs**: Comptes utilisateurs (chercheurs, entreprises, admins)
2. **chercheurs_emploi**: Profils des chercheurs d'emploi
3. **entreprises**: Profils des entreprises/recruteurs
4. **administrateurs**: Comptes administrateurs
5. **cv**: CV uploadés et analysés par IA
6. **offres_emploi**: Offres d'emploi publiées
7. **candidatures**: Candidatures avec scores de compatibilité
8. **statistiques**: Statistiques globales
9. **signalements**: Signalements pour modération

### Relations

- `utilisateurs` → `chercheurs_emploi` (1:1)
- `utilisateurs` → `entreprises` (1:1)
- `utilisateurs` → `administrateurs` (1:1)
- `chercheurs_emploi` → `cv` (1:1)
- `chercheurs_emploi` → `candidatures` (1:N)
- `entreprises` → `offres_emploi` (1:N)
- `offres_emploi` → `candidatures` (1:N)
- `cv` → `candidatures` (1:N)

## 🔒 Sécurité

- **Row Level Security (RLS)**: Activé sur les tables sensibles
- **Politiques**: À configurer selon vos besoins spécifiques
- **Storage**: Buckets privés avec politiques d'accès strictes
- **Authentification**: Via Supabase Auth (JWT)

## 📝 Notes

- Les mots de passe doivent être hashés avec bcrypt avant insertion
- Les fichiers CV sont stockés dans Supabase Storage
- Les compétences extraites par IA sont stockées en JSONB pour flexibilité
- Les scores de compatibilité sont calculés par le module IA

## 🚀 Prochaines Étapes

Une fois Supabase configuré :
1. ✅ Vérifier que toutes les tables sont créées
2. ✅ Configurer le Storage pour les CV
3. ✅ Récupérer les clés API
4. ✅ Créer le fichier `.env` dans le backend
5. ➡️ Passer à la configuration du backend NestJS

