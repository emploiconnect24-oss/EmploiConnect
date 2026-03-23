# Base de Données - EmploiConnect

Ce dossier contient tous les fichiers de configuration pour la base de données Supabase.

## 📁 Fichiers

- **`supabase_schema.sql`**: Schéma complet de la base de données avec toutes les tables, index, triggers et vues
- **`supabase_config.md`**: Guide détaillé de configuration de Supabase
- **`README.md`**: Ce fichier

## 🗄️ Structure de la Base de Données

### Diagramme des Relations

```
utilisateurs (classe parente)
├── chercheurs_emploi (1:1)
│   └── cv (1:1)
│       └── candidatures (1:N)
├── entreprises (1:1)
│   └── offres_emploi (1:N)
│       └── candidatures (1:N)
└── administrateurs (1:1)
```

### Tables Principales

| Table | Description | Relations |
|-------|-------------|-----------|
| `utilisateurs` | Comptes utilisateurs de base | Parent de chercheurs, entreprises, admins |
| `chercheurs_emploi` | Profils des candidats | 1:1 avec utilisateurs, 1:1 avec cv, 1:N avec candidatures |
| `entreprises` | Profils des recruteurs | 1:1 avec utilisateurs, 1:N avec offres_emploi |
| `administrateurs` | Comptes administrateurs | 1:1 avec utilisateurs |
| `cv` | CV uploadés et analysés | 1:1 avec chercheurs_emploi |
| `offres_emploi` | Offres d'emploi | N:1 avec entreprises, 1:N avec candidatures |
| `candidatures` | Candidatures avec scores IA | N:1 avec chercheurs, N:1 avec offres |
| `statistiques` | Statistiques globales | - |
| `signalements` | Signalements pour modération | - |

## 🚀 Démarrage Rapide

1. **Créer un projet Supabase** sur [supabase.com](https://supabase.com)
2. **Exécuter le schéma SQL** dans le SQL Editor de Supabase
3. **Configurer le Storage** pour les fichiers CV
4. **Récupérer les clés API** dans Settings → API
5. **Créer le fichier `.env`** dans le backend avec les clés

Voir `supabase_config.md` pour les instructions détaillées.

## 🔑 Clés et Variables d'Environnement

Les variables suivantes seront nécessaires pour le backend :

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
DATABASE_URL=
JWT_SECRET=
SUPABASE_STORAGE_BUCKET=cv-files
```

## 📊 Vues Disponibles

- **`v_offres_completes`**: Offres avec informations entreprise et nombre de candidatures
- **`v_candidatures_completes`**: Candidatures avec tous les détails (chercheur, offre, entreprise)

## 🔒 Sécurité

- Row Level Security (RLS) activé sur les tables sensibles
- Politiques d'accès à configurer selon les besoins
- Storage privé pour les fichiers CV
- Authentification via Supabase Auth

## 📝 Notes Techniques

- **UUID**: Tous les IDs utilisent UUID v4
- **JSONB**: Utilisé pour les compétences et expériences (flexible pour l'IA)
- **Timestamps**: Tous les enregistrements ont `date_creation` et `date_modification`
- **Triggers**: Mise à jour automatique de `date_modification`
- **Index**: Index créés sur les colonnes fréquemment utilisées pour les requêtes

## ✅ Checklist de Configuration

- [ ] Projet Supabase créé
- [ ] Schéma SQL exécuté sans erreurs
- [ ] Toutes les tables créées et visibles
- [ ] Bucket Storage `cv-files` créé
- [ ] Politiques RLS configurées (optionnel pour le moment)
- [ ] Clés API récupérées
- [ ] Fichier `.env` créé dans le backend
- [ ] Variables d'environnement configurées

Une fois cette checklist complétée, vous pouvez passer à la configuration du backend ! 🎉

