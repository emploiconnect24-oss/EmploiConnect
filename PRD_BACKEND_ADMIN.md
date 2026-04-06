# PRD — EmploiConnect · Backend Complet — Module Administration
## Product Requirements Document v3.0 — Backend Admin
**Stack : Node.js + Express · PostgreSQL via Supabase · JWT**
**Outil : Cursor / Kirsoft AI**
**Module : Backend Administration — API complètes + Migrations**
**Statut : Phase 7 — Backend après Frontend validé**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> 1. **Stack existant confirmé** : Node.js + Express, PostgreSQL (Supabase), JWT + bcrypt
> 2. **NE PAS** toucher aux routes déjà fonctionnelles sauf pour les améliorer
> 3. **NE PAS** utiliser Supabase Auth — rester sur le système JWT custom existant
> 4. **Client Flutter** : package `http` avec baseURL `http://localhost:3000/api`
> 5. **Schéma SQL** existe dans `database/supabase_schema.sql` — faire les ALTER TABLE
>    et nouvelles tables via des fichiers SQL séparés dans `database/migrations/`
> 6. Toutes les nouvelles routes admin sous le préfixe `/api/admin/`
> 7. **Middleware auth existant** : `backend/src/middleware/auth.js` — l'utiliser partout
> 8. Implémenter **dans l'ordre exact** de ce PRD

---

## Table des Matières

1. [État des Lieux — Ce qui existe déjà](#1-état-des-lieux--ce-qui-existe-déjà)
2. [Ce qui manque — Gap Analysis Admin](#2-ce-qui-manque--gap-analysis-admin)
3. [Nouvelles Migrations SQL](#3-nouvelles-migrations-sql)
4. [Architecture Backend Admin](#4-architecture-backend-admin)
5. [Middleware Admin](#5-middleware-admin)
6. [Routes Admin — Statistiques](#6-routes-admin--statistiques)
7. [Routes Admin — Gestion Utilisateurs](#7-routes-admin--gestion-utilisateurs)
8. [Routes Admin — Gestion Offres](#8-routes-admin--gestion-offres)
9. [Routes Admin — Gestion Entreprises](#9-routes-admin--gestion-entreprises)
10. [Routes Admin — Gestion Candidatures](#10-routes-admin--gestion-candidatures)
11. [Routes Admin — Modération & Signalements](#11-routes-admin--modération--signalements)
12. [Routes Admin — Notifications](#12-routes-admin--notifications)
13. [Routes Admin — Paramètres Plateforme](#13-routes-admin--paramètres-plateforme)
14. [Connexion Flutter — Service Admin](#14-connexion-flutter--service-admin)
15. [Mise à jour du Client Flutter](#15-mise-à-jour-du-client-flutter)
16. [Tests des Endpoints](#16-tests-des-endpoints)
17. [Critères d'Acceptation](#17-critères-dacceptation)

---

## 1. État des Lieux — Ce qui existe déjà

### Routes Admin Existantes (à conserver et améliorer)
```
✅ GET  /api/admin/utilisateurs      → Liste users (admin)
✅ PATCH /api/admin/utilisateurs/:id → Valider/activer user
✅ GET  /api/admin/statistiques      → Compteurs temps réel
✅ GET  /api/admin/signalements      → Liste signalements
✅ PATCH /api/admin/signalements/:id → Traiter signalement
```

### Tables Existantes (confirmées dans supabase_schema.sql)
```
✅ utilisateurs       → id, nom, email, mot_de_passe, role, telephone,
                         adresse, photo_url, est_actif, est_valide,
                         date_creation, date_modification
✅ chercheurs_emploi  → id, utilisateur_id, date_naissance, genre,
                         competences (JSONB), niveau_etude, disponibilite
✅ entreprises        → id, utilisateur_id, nom_entreprise, description,
                         secteur_activite, taille_entreprise, site_web,
                         logo_url, adresse_siege
✅ administrateurs    → id, utilisateur_id, niveau_acces
✅ cv                 → id, chercheur_id, fichier_url, nom_fichier,
                         competences_extrait (JSONB), experience (JSONB)
✅ offres_emploi      → id, entreprise_id, titre, description, exigences,
                         competences_requises (JSONB), salaire_min,
                         salaire_max, devise, localisation, type_contrat,
                         niveau_experience_requis, domaine, statut,
                         nombre_postes, date_publication, date_limite
✅ candidatures       → id, chercheur_id, offre_id, cv_id,
                         date_candidature, statut, score_compatibilite,
                         lettre_motivation
✅ statistiques       → id, date_collecte, nombre_chercheurs,
                         nombre_entreprises, nombre_offres_actives,
                         nombre_candidatures, nombre_candidatures_acceptees,
                         nombre_cv_analyses (UNIQUE sur date_collecte)
✅ signalements       → id, utilisateur_signalant_id, type_objet,
                         objet_id, raison, statut, date_signalement,
                         date_traitement, admin_traitant_id
```

### Ce qui est manquant dans les tables existantes
```
❌ notifications        → Table absente
❌ alertes_emploi       → Table absente
❌ offres_sauvegardees  → Table absente
❌ messages             → Table absente
❌ parametres_plateforme→ Table absente
❌ activite_admin       → Journal d'audit absent
```

---

## 2. Ce qui manque — Gap Analysis Admin

### Routes manquantes pour le Dashboard Admin
```
❌ GET  /api/admin/statistiques/historique → Évolution sur période
❌ GET  /api/admin/statistiques/export     → Export CSV/Excel
❌ GET  /api/admin/utilisateurs/stats      → Stats par rôle
❌ DELETE /api/admin/utilisateurs/:id      → Supprimer un user
❌ GET  /api/admin/offres                  → Liste toutes les offres
❌ GET  /api/admin/offres/:id              → Détail offre admin
❌ PATCH /api/admin/offres/:id             → Valider/rejeter/featured
❌ DELETE /api/admin/offres/:id            → Supprimer offre
❌ GET  /api/admin/entreprises             → Liste entreprises
❌ GET  /api/admin/entreprises/:id         → Détail entreprise
❌ PATCH /api/admin/entreprises/:id        → Valider/suspendre
❌ DELETE /api/admin/entreprises/:id       → Supprimer entreprise
❌ GET  /api/admin/candidatures            → Vue globale candidatures
❌ POST /api/admin/notifications           → Envoyer notification
❌ GET  /api/admin/notifications           → Historique notifications
❌ GET  /api/admin/activite               → Journal d'audit
❌ GET  /api/admin/parametres             → Lire paramètres plateforme
❌ PUT  /api/admin/parametres             → Modifier paramètres
❌ GET  /api/admin/dashboard              → Données dashboard complet
```

### Améliorations des routes existantes
```
⚠️ GET /api/admin/statistiques     → Ajouter évolution vs période précédente
⚠️ GET /api/admin/utilisateurs     → Ajouter pagination, filtres, recherche
⚠️ PATCH /api/admin/utilisateurs/:id → Ajouter action bloquer/débloquer
⚠️ GET /api/admin/signalements     → Ajouter filtres par type et priorité
```

---

## 3. Nouvelles Migrations SQL

### Fichier : `database/migrations/001_add_notifications.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 001 : Table notifications
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS notifications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  destinataire_id   UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
  -- NULL = notification globale (tous les users)
  type_destinataire VARCHAR(20) CHECK (
    type_destinataire IN ('tous', 'chercheurs', 'entreprises', 'individuel')
  ) DEFAULT 'individuel',
  titre             VARCHAR(255) NOT NULL,
  message           TEXT NOT NULL,
  type              VARCHAR(50) CHECK (
    type IN (
      'candidature', 'offre', 'message', 'systeme',
      'alerte_emploi', 'validation_compte', 'autre'
    )
  ) DEFAULT 'systeme',
  lien              VARCHAR(500),     -- Route Flutter (ex: /dashboard/candidatures)
  est_lue           BOOLEAN DEFAULT FALSE,
  envoye_par        UUID REFERENCES utilisateurs(id) ON DELETE SET NULL,
  -- Pour les notifications planifiées
  date_envoi_prevu  TIMESTAMP WITH TIME ZONE,
  date_envoi_reel   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  date_creation     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX IF NOT EXISTS idx_notifications_destinataire
  ON notifications(destinataire_id);
CREATE INDEX IF NOT EXISTS idx_notifications_est_lue
  ON notifications(est_lue);
CREATE INDEX IF NOT EXISTS idx_notifications_type
  ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_date
  ON notifications(date_creation DESC);

-- RLS Supabase (si activé)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
```

### Fichier : `database/migrations/002_add_parametres_plateforme.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 002 : Table paramètres plateforme
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parametres_plateforme (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cle                   VARCHAR(100) UNIQUE NOT NULL,
  valeur                TEXT NOT NULL,
  type_valeur           VARCHAR(20) CHECK (
    type_valeur IN ('string', 'boolean', 'integer', 'json')
  ) DEFAULT 'string',
  description           TEXT,
  categorie             VARCHAR(50) CHECK (
    categorie IN (
      'general', 'comptes', 'notifications', 'ia_matching',
      'maintenance', 'securite'
    )
  ) DEFAULT 'general',
  modifiable_admin      BOOLEAN DEFAULT TRUE,
  date_modification     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  modifie_par           UUID REFERENCES utilisateurs(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_parametres_cle ON parametres_plateforme(cle);
CREATE INDEX IF NOT EXISTS idx_parametres_categorie
  ON parametres_plateforme(categorie);

-- Données initiales (paramètres par défaut)
INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('nom_plateforme',
   'EmploiConnect', 'string',
   'Nom de la plateforme', 'general'),
  ('description_plateforme',
   'Plateforme intelligente d''offres et de recherche d''emploi en Guinée',
   'string', 'Description courte', 'general'),
  ('email_contact',
   'contact@emploiconnect.gn', 'string',
   'Email de contact public', 'general'),
  ('telephone_contact',
   '+224 620 00 00 00', 'string',
   'Téléphone public', 'general'),
  ('inscription_libre',
   'true', 'boolean',
   'Autoriser l''inscription libre', 'comptes'),
  ('validation_manuelle_comptes',
   'false', 'boolean',
   'Validation manuelle des nouveaux comptes', 'comptes'),
  ('max_offres_gratuit',
   '5', 'integer',
   'Nombre max d''offres actives pour compte gratuit', 'comptes'),
  ('duree_validite_offre_jours',
   '30', 'integer',
   'Durée de validité d''une offre en jours', 'comptes'),
  ('notif_email_candidature',
   'true', 'boolean',
   'Envoyer email à chaque candidature', 'notifications'),
  ('notif_email_validation',
   'true', 'boolean',
   'Envoyer email de validation de compte', 'notifications'),
  ('notif_resume_hebdo',
   'true', 'boolean',
   'Résumé hebdomadaire par email', 'notifications'),
  ('seuil_matching_minimum',
   '40', 'integer',
   'Score minimum pour suggérer une offre (%)', 'ia_matching'),
  ('suggestions_automatiques',
   'true', 'boolean',
   'Activer suggestions IA automatiques', 'ia_matching'),
  ('mode_maintenance',
   'false', 'boolean',
   'Mode maintenance actif', 'maintenance'),
  ('message_maintenance',
   'La plateforme est en cours de maintenance. Revenez bientôt.',
   'string', 'Message affiché en maintenance', 'maintenance'),
  ('duree_session_minutes',
   '1440', 'integer',
   'Durée de session en minutes (1440 = 24h)', 'securite'),
  ('max_tentatives_connexion',
   '5', 'integer',
   'Nombre max de tentatives avant blocage', 'securite')
ON CONFLICT (cle) DO NOTHING;
```

### Fichier : `database/migrations/003_add_activite_admin.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 003 : Journal d'audit des actions admin
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS activite_admin (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id        UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  action          VARCHAR(100) NOT NULL,
  -- Ex: 'VALIDER_USER', 'SUPPRIMER_OFFRE', 'MODIFIER_PARAMETRES'
  type_objet      VARCHAR(50),
  -- Ex: 'utilisateur', 'offre', 'entreprise', 'signalement'
  objet_id        UUID,
  details         JSONB,
  -- Infos supplémentaires (valeur avant, valeur après, etc.)
  ip_address      VARCHAR(45),
  user_agent      TEXT,
  date_action     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activite_admin_id
  ON activite_admin(admin_id);
CREATE INDEX IF NOT EXISTS idx_activite_admin_date
  ON activite_admin(date_action DESC);
CREATE INDEX IF NOT EXISTS idx_activite_admin_action
  ON activite_admin(action);
```

### Fichier : `database/migrations/004_alter_offres_add_featured.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 004 : Ajouter colonne 'en_vedette' aux offres
-- ═══════════════════════════════════════════════════════════

-- Colonne pour les offres mises en avant par l'admin
ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS en_vedette BOOLEAN DEFAULT FALSE;

ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS raison_refus TEXT;
  -- Motif si l'admin refuse une offre

ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS valide_par UUID
    REFERENCES utilisateurs(id) ON DELETE SET NULL;

ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS date_validation TIMESTAMP WITH TIME ZONE;

-- Index
CREATE INDEX IF NOT EXISTS idx_offres_en_vedette
  ON offres_emploi(en_vedette) WHERE en_vedette = TRUE;
CREATE INDEX IF NOT EXISTS idx_offres_statut
  ON offres_emploi(statut);
```

### Fichier : `database/migrations/005_alter_utilisateurs_add_fields.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 005 : Ajouter colonnes manquantes dans utilisateurs
-- ═══════════════════════════════════════════════════════════

-- Raison du blocage d'un compte
ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS raison_blocage TEXT;

-- Date de dernière connexion
ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMP WITH TIME ZONE;

-- Admin qui a traité ce compte
ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS traite_par UUID
    REFERENCES utilisateurs(id) ON DELETE SET NULL;

-- Index
CREATE INDEX IF NOT EXISTS idx_utilisateurs_role
  ON utilisateurs(role);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_est_actif
  ON utilisateurs(est_actif);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_est_valide
  ON utilisateurs(est_valide);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_date_creation
  ON utilisateurs(date_creation DESC);
```

### Fichier : `database/migrations/006_add_stats_view.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 006 : Vue statistiques admin enrichie
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_stats_admin AS
SELECT
  -- Utilisateurs
  COUNT(DISTINCT u.id) FILTER (WHERE u.role = 'chercheur')
    AS total_chercheurs,
  COUNT(DISTINCT u.id) FILTER (WHERE u.role = 'entreprise')
    AS total_entreprises,
  COUNT(DISTINCT u.id) FILTER (WHERE u.role = 'admin')
    AS total_admins,
  COUNT(DISTINCT u.id) FILTER (
    WHERE u.date_creation >= NOW() - INTERVAL '30 days')
    AS nouveaux_users_30j,
  COUNT(DISTINCT u.id) FILTER (WHERE NOT u.est_valide)
    AS comptes_en_attente,
  COUNT(DISTINCT u.id) FILTER (WHERE NOT u.est_actif AND u.est_valide)
    AS comptes_bloques,

  -- Offres
  COUNT(DISTINCT o.id) FILTER (WHERE o.statut = 'publiee')
    AS offres_actives,
  COUNT(DISTINCT o.id) FILTER (WHERE o.statut = 'en_attente')
    AS offres_en_attente,
  COUNT(DISTINCT o.id) FILTER (WHERE o.statut = 'refusee')
    AS offres_refusees,
  COUNT(DISTINCT o.id) FILTER (WHERE o.statut = 'expiree')
    AS offres_expirees,
  COUNT(DISTINCT o.id) FILTER (
    WHERE o.date_publication >= NOW() - INTERVAL '30 days')
    AS nouvelles_offres_30j,

  -- Candidatures
  COUNT(DISTINCT c.id) AS total_candidatures,
  COUNT(DISTINCT c.id) FILTER (WHERE c.statut = 'acceptee')
    AS candidatures_acceptees,
  COUNT(DISTINCT c.id) FILTER (
    WHERE c.date_candidature >= NOW() - INTERVAL '30 days')
    AS nouvelles_candidatures_30j,

  -- Signalements
  COUNT(DISTINCT s.id) FILTER (WHERE s.statut = 'en_attente')
    AS signalements_en_attente,
  COUNT(DISTINCT s.id) FILTER (WHERE s.statut = 'urgent')
    AS signalements_urgents,

  -- CV
  COUNT(DISTINCT cv.id) AS total_cv

FROM utilisateurs u
LEFT JOIN offres_emploi o ON TRUE
LEFT JOIN candidatures c ON TRUE
LEFT JOIN signalements s ON TRUE
LEFT JOIN cv ON TRUE;
```

---

## 4. Architecture Backend Admin

### Structure des fichiers à créer
```
backend/src/
├── routes/
│   ├── index.js                    ← Mettre à jour avec nouvelles routes
│   └── admin/
│       ├── index.js                ← Agrégateur routes admin
│       ├── dashboard.routes.js     ← Dashboard + activité
│       ├── users.routes.js         ← Gestion utilisateurs (améliorer existant)
│       ├── offres.routes.js        ← Gestion offres
│       ├── entreprises.routes.js   ← Gestion entreprises
│       ├── candidatures.routes.js  ← Vue globale candidatures
│       ├── signalements.routes.js  ← Améliorer existant
│       ├── notifications.routes.js ← Nouvelles
│       └── parametres.routes.js    ← Nouvelles
├── controllers/
│   └── admin/
│       ├── dashboard.controller.js
│       ├── users.controller.js
│       ├── offres.controller.js
│       ├── entreprises.controller.js
│       ├── candidatures.controller.js
│       ├── signalements.controller.js
│       ├── notifications.controller.js
│       └── parametres.controller.js
├── middleware/
│   ├── auth.js                     ← Existant (conserver)
│   ├── adminAuth.js                ← NOUVEAU : vérif rôle admin
│   └── auditLog.js                 ← NOUVEAU : journal d'audit auto
└── services/
    └── admin/
        ├── stats.service.js        ← Calculs statistiques
        └── notification.service.js ← Envoi notifications
```

---

## 5. Middleware Admin

### `backend/src/middleware/adminAuth.js`
```javascript
// Middleware de vérification rôle administrateur
// S'utilise APRÈS le middleware auth.js existant

const { supabase } = require('../config/supabase');

/**
 * Vérifie que l'utilisateur connecté est bien un administrateur
 * Utilise auth.js en amont (req.user est déjà défini)
 */
const requireAdmin = async (req, res, next) => {
  try {
    // req.user est défini par le middleware auth.js existant
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentification requise'
      });
    }

    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Droits administrateur requis.'
      });
    }

    // Vérifier que le compte admin est actif
    const { data: admin, error } = await supabase
      .from('administrateurs')
      .select('id, niveau_acces')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (error || !admin) {
      return res.status(403).json({
        success: false,
        message: 'Compte administrateur non trouvé'
      });
    }

    req.admin = admin; // Attacher les infos admin à la requête
    next();
  } catch (err) {
    console.error('[adminAuth] Erreur:', err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la vérification des droits'
    });
  }
};

module.exports = { requireAdmin };
```

### `backend/src/middleware/auditLog.js`
```javascript
// Middleware d'audit — enregistre automatiquement les actions admin

const { supabase } = require('../config/supabase');

/**
 * Factory : crée un middleware qui loggue une action admin
 * @param {string} action - Code de l'action (ex: 'VALIDER_USER')
 * @param {string} typeObjet - Type d'objet concerné (ex: 'utilisateur')
 */
const auditLog = (action, typeObjet = null) => {
  return async (req, res, next) => {
    // Sauvegarder la fonction json originale
    const originalJson = res.json.bind(res);

    // Intercepter la réponse pour logger seulement si succès
    res.json = async (body) => {
      // Logger seulement si la réponse est un succès (2xx)
      if (res.statusCode >= 200 && res.statusCode < 300 && req.user) {
        try {
          const objetId = req.params?.id || body?.data?.id || null;
          await supabase.from('activite_admin').insert({
            admin_id:   req.user.id,
            action,
            type_objet: typeObjet,
            objet_id:   objetId,
            details: {
              body_request: req.body,
              params: req.params,
              status_code: res.statusCode,
            },
            ip_address: req.ip || req.connection?.remoteAddress,
            user_agent: req.headers['user-agent'],
          });
        } catch (logErr) {
          // Ne pas bloquer la réponse si le log échoue
          console.error('[auditLog] Erreur logging:', logErr.message);
        }
      }
      return originalJson(body);
    };

    next();
  };
};

module.exports = { auditLog };
```

---

## 6. Routes Admin — Statistiques

### `backend/src/controllers/admin/dashboard.controller.js`
```javascript
const { supabase } = require('../../config/supabase');

// ══════════════════════════════════════════════════════════════
// GET /api/admin/dashboard
// Toutes les données du dashboard en un seul appel
// ══════════════════════════════════════════════════════════════
const getDashboard = async (req, res) => {
  try {
    // 1. Stats principales en parallèle
    const [
      usersResult,
      offresResult,
      candidaturesResult,
      signalementsResult,
    ] = await Promise.all([

      // Compteurs utilisateurs
      supabase.from('utilisateurs').select('role, est_actif, est_valide', { count: 'exact' }),

      // Compteurs offres
      supabase.from('offres_emploi').select('statut', { count: 'exact' }),

      // Compteurs candidatures (30 derniers jours)
      supabase.from('candidatures')
        .select('statut, date_candidature', { count: 'exact' })
        .gte('date_candidature', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()),

      // Signalements urgents
      supabase.from('signalements')
        .select('statut', { count: 'exact' })
        .eq('statut', 'en_attente'),
    ]);

    const users = usersResult.data || [];
    const offres = offresResult.data || [];
    const candidatures = candidaturesResult.data || [];
    const signalements = signalementsResult.data || [];

    // Calcul des statistiques
    const stats = {
      utilisateurs: {
        total:        users.length,
        chercheurs:   users.filter(u => u.role === 'chercheur').length,
        entreprises:  users.filter(u => u.role === 'entreprise').length,
        en_attente:   users.filter(u => !u.est_valide).length,
        bloques:      users.filter(u => u.est_actif === false && u.est_valide).length,
      },
      offres: {
        total:        offres.length,
        actives:      offres.filter(o => o.statut === 'publiee').length,
        en_attente:   offres.filter(o => o.statut === 'en_attente').length,
        refusees:     offres.filter(o => o.statut === 'refusee').length,
        expirees:     offres.filter(o => o.statut === 'expiree').length,
      },
      candidatures: {
        total_30j:    candidatures.length,
        acceptees:    candidatures.filter(c => c.statut === 'acceptee').length,
      },
      signalements: {
        en_attente:   signalements.length,
      },
    };

    // 2. Activité récente (10 dernières actions)
    const { data: activiteRecente } = await supabase
      .from('activite_admin')
      .select(`
        id, action, type_objet, objet_id, date_action,
        admin:admin_id (nom, email)
      `)
      .order('date_action', { ascending: false })
      .limit(10);

    // 3. Offres en attente de validation (5 premières)
    const { data: offresEnAttente } = await supabase
      .from('offres_emploi')
      .select(`
        id, titre, localisation, type_contrat, date_creation,
        entreprise:entreprise_id (
          nom_entreprise, logo_url,
          utilisateur:utilisateur_id (email)
        )
      `)
      .eq('statut', 'en_attente')
      .order('date_creation', { ascending: true })
      .limit(5);

    // 4. Derniers utilisateurs inscrits
    const { data: derniersUsers } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, role, est_actif, est_valide, date_creation')
      .order('date_creation', { ascending: false })
      .limit(5);

    return res.json({
      success: true,
      data: {
        stats,
        activite_recente: activiteRecente || [],
        offres_en_attente: offresEnAttente || [],
        derniers_utilisateurs: derniersUsers || [],
      }
    });

  } catch (err) {
    console.error('[getDashboard]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// GET /api/admin/statistiques
// Stats complètes avec évolution vs période précédente
// Query params: ?periode=7d|30d|3m|6m|1an
// ══════════════════════════════════════════════════════════════
const getStatistiques = async (req, res) => {
  try {
    const { periode = '30d' } = req.query;

    const periodeJours = {
      '7d':  7,
      '30d': 30,
      '3m':  90,
      '6m':  180,
      '1an': 365,
    }[periode] || 30;

    const dateDebut = new Date(Date.now() - periodeJours * 24 * 60 * 60 * 1000);
    const datePrecedente = new Date(Date.now() - 2 * periodeJours * 24 * 60 * 60 * 1000);

    // Période actuelle
    const [usersActuel, offresActuel, candidActuel] = await Promise.all([
      supabase.from('utilisateurs')
        .select('id, role, date_creation', { count: 'exact' })
        .gte('date_creation', dateDebut.toISOString()),
      supabase.from('offres_emploi')
        .select('id, statut, date_creation', { count: 'exact' })
        .gte('date_creation', dateDebut.toISOString()),
      supabase.from('candidatures')
        .select('id, statut, date_candidature', { count: 'exact' })
        .gte('date_candidature', dateDebut.toISOString()),
    ]);

    // Période précédente (pour calcul tendance)
    const [usersPrecedent, offresPrecedent, candidPrecedent] = await Promise.all([
      supabase.from('utilisateurs').select('id', { count: 'exact' })
        .gte('date_creation', datePrecedente.toISOString())
        .lt('date_creation', dateDebut.toISOString()),
      supabase.from('offres_emploi').select('id', { count: 'exact' })
        .gte('date_creation', datePrecedente.toISOString())
        .lt('date_creation', dateDebut.toISOString()),
      supabase.from('candidatures').select('id', { count: 'exact' })
        .gte('date_candidature', datePrecedente.toISOString())
        .lt('date_candidature', dateDebut.toISOString()),
    ]);

    // Calcul tendances (%)
    const tendance = (actuel, precedent) => {
      if (!precedent || precedent === 0) return actuel > 0 ? 100 : 0;
      return Math.round(((actuel - precedent) / precedent) * 100);
    };

    const nbUsersActuel = usersActuel.count || 0;
    const nbUsersPrecedent = usersPrecedent.count || 0;
    const nbOffresActuel = offresActuel.count || 0;
    const nbOffresPrecedent = offresPrecedent.count || 0;
    const nbCandidActuel = candidActuel.count || 0;
    const nbCandidPrecedent = candidPrecedent.count || 0;

    // Évolution par jour (pour graphiques)
    const evolutionParJour = await _getEvolutionParJour(periodeJours);

    // Distribution par ville (offres)
    const { data: distribVilles } = await supabase
      .from('offres_emploi')
      .select('localisation')
      .eq('statut', 'publiee');

    const villesCount = {};
    (distribVilles || []).forEach(o => {
      const v = o.localisation || 'Non précisé';
      villesCount[v] = (villesCount[v] || 0) + 1;
    });

    // Distribution par secteur
    const { data: distribSecteurs } = await supabase
      .from('offres_emploi')
      .select('domaine');

    const secteursCount = {};
    (distribSecteurs || []).forEach(o => {
      const s = o.domaine || 'Autre';
      secteursCount[s] = (secteursCount[s] || 0) + 1;
    });

    return res.json({
      success: true,
      data: {
        periode,
        kpis: {
          nouveaux_utilisateurs: {
            valeur: nbUsersActuel,
            tendance: tendance(nbUsersActuel, nbUsersPrecedent),
          },
          nouvelles_offres: {
            valeur: nbOffresActuel,
            tendance: tendance(nbOffresActuel, nbOffresPrecedent),
          },
          nouvelles_candidatures: {
            valeur: nbCandidActuel,
            tendance: tendance(nbCandidActuel, nbCandidPrecedent),
          },
        },
        evolution_par_jour: evolutionParJour,
        distribution_villes: villesCount,
        distribution_secteurs: secteursCount,
      }
    });

  } catch (err) {
    console.error('[getStatistiques]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// Calcul évolution par jour sur N jours
const _getEvolutionParJour = async (nbJours) => {
  const { data: users } = await supabase
    .from('utilisateurs')
    .select('date_creation')
    .gte('date_creation',
      new Date(Date.now() - nbJours * 24 * 60 * 60 * 1000).toISOString());

  const { data: offres } = await supabase
    .from('offres_emploi')
    .select('date_creation')
    .gte('date_creation',
      new Date(Date.now() - nbJours * 24 * 60 * 60 * 1000).toISOString());

  // Grouper par jour
  const parJour = {};
  const today = new Date();

  for (let i = nbJours - 1; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    const key = date.toISOString().split('T')[0];
    parJour[key] = { date: key, utilisateurs: 0, offres: 0 };
  }

  (users || []).forEach(u => {
    const key = u.date_creation?.split('T')[0];
    if (key && parJour[key]) parJour[key].utilisateurs++;
  });

  (offres || []).forEach(o => {
    const key = o.date_creation?.split('T')[0];
    if (key && parJour[key]) parJour[key].offres++;
  });

  return Object.values(parJour);
};

// ══════════════════════════════════════════════════════════════
// GET /api/admin/activite
// Journal d'audit des actions admin
// ══════════════════════════════════════════════════════════════
const getActivite = async (req, res) => {
  try {
    const { page = 1, limite = 20, action, type_objet } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('activite_admin')
      .select(`
        id, action, type_objet, objet_id, details,
        ip_address, date_action,
        admin:admin_id (id, nom, email, photo_url)
      `, { count: 'exact' })
      .order('date_action', { ascending: false })
      .range(offset, offset + parseInt(limite) - 1);

    if (action) query = query.eq('action', action);
    if (type_objet) query = query.eq('type_objet', type_objet);

    const { data, count, error } = await query;
    if (error) throw error;

    return res.json({
      success: true,
      data: {
        activites: data || [],
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[getActivite]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getDashboard, getStatistiques, getActivite };
```

---

## 7. Routes Admin — Gestion Utilisateurs

### `backend/src/controllers/admin/users.controller.js`
```javascript
const { supabase } = require('../../config/supabase');
const bcrypt = require('bcryptjs');

// ══════════════════════════════════════════════════════════════
// GET /api/admin/utilisateurs
// Liste paginée avec filtres et recherche
// ══════════════════════════════════════════════════════════════
const getUtilisateurs = async (req, res) => {
  try {
    const {
      page = 1,
      limite = 20,
      role,           // 'chercheur' | 'entreprise' | 'admin'
      statut,         // 'actif' | 'en_attente' | 'bloque'
      recherche,      // nom ou email
      ville,
      ordre = 'date_creation',
      direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('utilisateurs')
      .select(`
        id, nom, email, role, telephone, adresse,
        photo_url, est_actif, est_valide,
        derniere_connexion, date_creation,
        chercheur:chercheurs_emploi (
          disponibilite, niveau_etude
        ),
        entreprise:entreprises (
          nom_entreprise, secteur_activite, logo_url
        )
      `, { count: 'exact' })
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    // Filtres
    if (role) query = query.eq('role', role);
    if (statut === 'actif')       query = query.eq('est_actif', true).eq('est_valide', true);
    if (statut === 'en_attente')  query = query.eq('est_valide', false);
    if (statut === 'bloque')      query = query.eq('est_actif', false).eq('est_valide', true);
    if (recherche) {
      query = query.or(`nom.ilike.%${recherche}%,email.ilike.%${recherche}%`);
    }
    if (ville) query = query.ilike('adresse', `%${ville}%`);

    const { data, count, error } = await query;
    if (error) throw error;

    // Compteurs par statut
    const { data: compteurs } = await supabase
      .from('utilisateurs')
      .select('role, est_actif, est_valide');

    const stats = {
      total: count || 0,
      chercheurs: compteurs?.filter(u => u.role === 'chercheur').length || 0,
      entreprises: compteurs?.filter(u => u.role === 'entreprise').length || 0,
      en_attente: compteurs?.filter(u => !u.est_valide).length || 0,
      bloques: compteurs?.filter(u => !u.est_actif && u.est_valide).length || 0,
    };

    return res.json({
      success: true,
      data: {
        utilisateurs: data || [],
        stats,
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[getUtilisateurs]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// GET /api/admin/utilisateurs/:id
// Détail complet d'un utilisateur
// ══════════════════════════════════════════════════════════════
const getUtilisateur = async (req, res) => {
  try {
    const { id } = req.params;

    const { data: user, error } = await supabase
      .from('utilisateurs')
      .select(`
        id, nom, email, role, telephone, adresse,
        photo_url, est_actif, est_valide,
        derniere_connexion, date_creation, date_modification,
        raison_blocage,
        chercheur:chercheurs_emploi (
          disponibilite, niveau_etude, genre,
          competences, date_naissance
        ),
        entreprise:entreprises (
          nom_entreprise, description, secteur_activite,
          taille_entreprise, site_web, logo_url
        )
      `)
      .eq('id', id)
      .single();

    if (error || !user) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    // Candidatures si chercheur
    let candidatures = [];
    if (user.role === 'chercheur') {
      const chercheur = user.chercheur;
      if (chercheur) {
        const { data: c } = await supabase
          .from('candidatures')
          .select('id, statut, date_candidature, offre:offre_id (titre)')
          .eq('chercheur_id', user.chercheur.id || id)
          .order('date_candidature', { ascending: false })
          .limit(10);
        candidatures = c || [];
      }
    }

    // Offres si entreprise
    let offres = [];
    if (user.role === 'entreprise') {
      const { data: ent } = await supabase
        .from('entreprises')
        .select('id')
        .eq('utilisateur_id', id)
        .single();

      if (ent) {
        const { data: o } = await supabase
          .from('offres_emploi')
          .select('id, titre, statut, date_publication')
          .eq('entreprise_id', ent.id)
          .order('date_publication', { ascending: false })
          .limit(10);
        offres = o || [];
      }
    }

    return res.json({
      success: true,
      data: { ...user, candidatures, offres }
    });
  } catch (err) {
    console.error('[getUtilisateur]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// PATCH /api/admin/utilisateurs/:id
// Actions admin : valider, activer, bloquer, modifier
// Body: { action: 'valider'|'activer'|'bloquer'|'modifier', raison?, ... }
// ══════════════════════════════════════════════════════════════
const updateUtilisateur = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, raison, ...updates } = req.body;

    let updateData = { date_modification: new Date().toISOString() };

    switch (action) {
      case 'valider':
        updateData.est_valide = true;
        updateData.est_actif = true;
        updateData.traite_par = req.user.id;
        break;

      case 'activer':
        updateData.est_actif = true;
        updateData.raison_blocage = null;
        updateData.traite_par = req.user.id;
        break;

      case 'bloquer':
        if (!raison) {
          return res.status(400).json({
            success: false,
            message: 'Une raison est requise pour bloquer un compte'
          });
        }
        updateData.est_actif = false;
        updateData.raison_blocage = raison;
        updateData.traite_par = req.user.id;
        break;

      case 'modifier':
        // Modification directe de champs admin
        Object.assign(updateData, updates);
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Action invalide. Valeurs: valider, activer, bloquer, modifier'
        });
    }

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: `Compte ${action === 'valider' ? 'validé' : action === 'bloquer' ? 'bloqué' : 'mis à jour'} avec succès`,
      data
    });
  } catch (err) {
    console.error('[updateUtilisateur]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// DELETE /api/admin/utilisateurs/:id
// Suppression définitive d'un compte
// ══════════════════════════════════════════════════════════════
const deleteUtilisateur = async (req, res) => {
  try {
    const { id } = req.params;

    // Empêcher la suppression de soi-même
    if (id === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Vous ne pouvez pas supprimer votre propre compte'
      });
    }

    // Vérifier que le compte existe
    const { data: user } = await supabase
      .from('utilisateurs')
      .select('id, nom, role')
      .eq('id', id)
      .single();

    if (!user) {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }

    // CASCADE DELETE sur toutes les tables liées (géré par FK ON DELETE CASCADE)
    const { error } = await supabase
      .from('utilisateurs')
      .delete()
      .eq('id', id);

    if (error) throw error;

    return res.json({
      success: true,
      message: `Compte de ${user.nom} supprimé définitivement`
    });
  } catch (err) {
    console.error('[deleteUtilisateur]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = {
  getUtilisateurs,
  getUtilisateur,
  updateUtilisateur,
  deleteUtilisateur,
};
```

---

## 8. Routes Admin — Gestion Offres

### `backend/src/controllers/admin/offres.controller.js`
```javascript
const { supabase } = require('../../config/supabase');

// ══════════════════════════════════════════════════════════════
// GET /api/admin/offres
// Liste toutes les offres avec filtres
// ══════════════════════════════════════════════════════════════
const getOffres = async (req, res) => {
  try {
    const {
      page = 1, limite = 20,
      statut,           // 'publiee'|'en_attente'|'refusee'|'expiree'
      domaine,
      localisation,
      entreprise_id,
      recherche,
      ordre = 'date_creation', direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('offres_emploi')
      .select(`
        id, titre, localisation, type_contrat, domaine,
        statut, nombre_postes, en_vedette,
        salaire_min, salaire_max, devise,
        date_publication, date_limite, date_creation,
        raison_refus,
        entreprise:entreprise_id (
          id, nom_entreprise, logo_url, secteur_activite,
          utilisateur:utilisateur_id (email)
        )
      `, { count: 'exact' })
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (statut)       query = query.eq('statut', statut);
    if (domaine)      query = query.eq('domaine', domaine);
    if (localisation) query = query.ilike('localisation', `%${localisation}%`);
    if (entreprise_id) query = query.eq('entreprise_id', entreprise_id);
    if (recherche)    query = query.ilike('titre', `%${recherche}%`);

    const { data, count, error } = await query;
    if (error) throw error;

    // Compteurs par statut
    const { data: tousStatuts } = await supabase
      .from('offres_emploi').select('statut');

    const statsStatuts = {
      total:      count || 0,
      publiees:   tousStatuts?.filter(o => o.statut === 'publiee').length || 0,
      en_attente: tousStatuts?.filter(o => o.statut === 'en_attente').length || 0,
      refusees:   tousStatuts?.filter(o => o.statut === 'refusee').length || 0,
      expirees:   tousStatuts?.filter(o => o.statut === 'expiree').length || 0,
    };

    // Nombre de candidatures par offre
    const offreIds = (data || []).map(o => o.id);
    let candidaturesCount = {};
    if (offreIds.length > 0) {
      const { data: cands } = await supabase
        .from('candidatures')
        .select('offre_id')
        .in('offre_id', offreIds);
      (cands || []).forEach(c => {
        candidaturesCount[c.offre_id] = (candidaturesCount[c.offre_id] || 0) + 1;
      });
    }

    const offresAvecStats = (data || []).map(o => ({
      ...o,
      nb_candidatures: candidaturesCount[o.id] || 0,
    }));

    return res.json({
      success: true,
      data: {
        offres: offresAvecStats,
        stats: statsStatuts,
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[admin/getOffres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// PATCH /api/admin/offres/:id
// Actions : valider, refuser, mettre_en_vedette, archiver
// ══════════════════════════════════════════════════════════════
const updateOffre = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, raison_refus } = req.body;

    let updateData = { date_modification: new Date().toISOString() };

    switch (action) {
      case 'valider':
        updateData.statut = 'publiee';
        updateData.valide_par = req.user.id;
        updateData.date_validation = new Date().toISOString();
        updateData.date_publication = new Date().toISOString();
        updateData.raison_refus = null;
        break;

      case 'refuser':
        if (!raison_refus) {
          return res.status(400).json({
            success: false,
            message: 'Un motif de refus est requis'
          });
        }
        updateData.statut = 'refusee';
        updateData.raison_refus = raison_refus;
        break;

      case 'mettre_en_vedette':
        // Toggle
        const { data: offre } = await supabase
          .from('offres_emploi').select('en_vedette').eq('id', id).single();
        updateData.en_vedette = !offre?.en_vedette;
        break;

      case 'archiver':
        updateData.statut = 'expiree';
        break;

      case 'republier':
        updateData.statut = 'publiee';
        updateData.date_publication = new Date().toISOString();
        // Recalculer date limite
        const { data: params } = await supabase
          .from('parametres_plateforme')
          .select('valeur')
          .eq('cle', 'duree_validite_offre_jours')
          .single();
        const nbJours = parseInt(params?.valeur || '30');
        const dateLimite = new Date();
        dateLimite.setDate(dateLimite.getDate() + nbJours);
        updateData.date_limite = dateLimite.toISOString();
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Action invalide'
        });
    }

    const { data, error } = await supabase
      .from('offres_emploi')
      .update(updateData)
      .eq('id', id)
      .select(`
        id, titre, statut, en_vedette, raison_refus,
        entreprise:entreprise_id (nom_entreprise)
      `)
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: `Offre ${action === 'valider' ? 'validée' : action === 'refuser' ? 'refusée' : 'mise à jour'} avec succès`,
      data
    });
  } catch (err) {
    console.error('[admin/updateOffre]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// DELETE /api/admin/offres/:id
// ══════════════════════════════════════════════════════════════
const deleteOffre = async (req, res) => {
  try {
    const { id } = req.params;

    const { data: offre } = await supabase
      .from('offres_emploi').select('titre').eq('id', id).single();

    if (!offre) {
      return res.status(404).json({ success: false, message: 'Offre non trouvée' });
    }

    const { error } = await supabase.from('offres_emploi').delete().eq('id', id);
    if (error) throw error;

    return res.json({
      success: true,
      message: `Offre "${offre.titre}" supprimée définitivement`
    });
  } catch (err) {
    console.error('[admin/deleteOffre]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getOffres, updateOffre, deleteOffre };
```

---

## 9. Routes Admin — Gestion Entreprises

### `backend/src/controllers/admin/entreprises.controller.js`
```javascript
const { supabase } = require('../../config/supabase');

// GET /api/admin/entreprises
const getEntreprises = async (req, res) => {
  try {
    const {
      page = 1, limite = 20,
      statut, secteur, ville, recherche,
      ordre = 'date_creation', direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('entreprises')
      .select(`
        id, nom_entreprise, description, secteur_activite,
        taille_entreprise, site_web, logo_url, adresse_siege,
        date_creation,
        utilisateur:utilisateur_id (
          id, nom, email, telephone,
          est_actif, est_valide, date_creation
        )
      `, { count: 'exact' })
      .order(`utilisateur_id(date_creation)`, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (secteur)   query = query.eq('secteur_activite', secteur);
    if (ville)     query = query.ilike('adresse_siege', `%${ville}%`);
    if (recherche) query = query.ilike('nom_entreprise', `%${recherche}%`);

    const { data, count, error } = await query;
    if (error) throw error;

    // Filtrer par statut utilisateur
    let entreprises = data || [];
    if (statut === 'actif')      entreprises = entreprises.filter(e => e.utilisateur?.est_actif && e.utilisateur?.est_valide);
    if (statut === 'en_attente') entreprises = entreprises.filter(e => !e.utilisateur?.est_valide);
    if (statut === 'bloque')     entreprises = entreprises.filter(e => !e.utilisateur?.est_actif && e.utilisateur?.est_valide);

    // Compter les offres par entreprise
    const entIds = entreprises.map(e => e.id);
    let offresCount = {};
    if (entIds.length > 0) {
      const { data: offres } = await supabase
        .from('offres_emploi')
        .select('entreprise_id, statut')
        .in('entreprise_id', entIds);
      (offres || []).forEach(o => {
        if (!offresCount[o.entreprise_id]) {
          offresCount[o.entreprise_id] = { total: 0, actives: 0 };
        }
        offresCount[o.entreprise_id].total++;
        if (o.statut === 'publiee') offresCount[o.entreprise_id].actives++;
      });
    }

    const result = entreprises.map(e => ({
      ...e,
      nb_offres_total: offresCount[e.id]?.total || 0,
      nb_offres_actives: offresCount[e.id]?.actives || 0,
    }));

    return res.json({
      success: true,
      data: {
        entreprises: result,
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[admin/getEntreprises]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// PATCH /api/admin/entreprises/:id (id = entreprise.utilisateur_id)
const updateEntreprise = async (req, res) => {
  try {
    const { id } = req.params; // utilisateur_id
    const { action, raison } = req.body;

    // Déléguer à la logique de gestion utilisateur
    // car les actions (valider/bloquer) s'appliquent à l'utilisateur lié
    let updateData = { date_modification: new Date().toISOString() };

    switch (action) {
      case 'valider':
        updateData = { est_valide: true, est_actif: true, traite_par: req.user.id };
        break;
      case 'suspendre':
        if (!raison) return res.status(400).json({ success: false, message: 'Raison requise' });
        updateData = { est_actif: false, raison_blocage: raison };
        break;
      case 'reactiver':
        updateData = { est_actif: true, raison_blocage: null };
        break;
      default:
        return res.status(400).json({ success: false, message: 'Action invalide' });
    }

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(updateData)
      .eq('id', id)
      .select('id, nom, email, est_actif, est_valide')
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: `Entreprise ${action === 'valider' ? 'validée' : action === 'suspendre' ? 'suspendue' : 'réactivée'}`,
      data
    });
  } catch (err) {
    console.error('[admin/updateEntreprise]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getEntreprises, updateEntreprise };
```

---

## 10. Routes Admin — Gestion Candidatures

### `backend/src/controllers/admin/candidatures.controller.js`
```javascript
const { supabase } = require('../../config/supabase');

// GET /api/admin/candidatures
// Vue globale de toutes les candidatures de la plateforme
const getCandidatures = async (req, res) => {
  try {
    const {
      page = 1, limite = 20,
      statut,
      offre_id,
      entreprise_id,
      chercheur_id,
      ordre = 'date_candidature', direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite,
        date_candidature, date_modification,
        chercheur:chercheur_id (
          id,
          utilisateur:utilisateur_id (nom, email, photo_url)
        ),
        offre:offre_id (
          id, titre, localisation, type_contrat,
          entreprise:entreprise_id (nom_entreprise, logo_url)
        )
      `, { count: 'exact' })
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (statut) query = query.eq('statut', statut);
    if (offre_id) query = query.eq('offre_id', offre_id);
    if (chercheur_id) query = query.eq('chercheur_id', chercheur_id);

    const { data, count, error } = await query;
    if (error) throw error;

    // Stats globales candidatures
    const { data: statsData } = await supabase
      .from('candidatures').select('statut');

    const stats = {
      total: statsData?.length || 0,
      en_attente: statsData?.filter(c => c.statut === 'en_attente').length || 0,
      en_cours: statsData?.filter(c => c.statut === 'en_cours').length || 0,
      entretien: statsData?.filter(c => c.statut === 'entretien').length || 0,
      acceptees: statsData?.filter(c => c.statut === 'acceptee').length || 0,
      refusees: statsData?.filter(c => c.statut === 'refusee').length || 0,
    };

    return res.json({
      success: true,
      data: {
        candidatures: data || [],
        stats,
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[admin/getCandidatures]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getCandidatures };
```

---

## 11. Routes Admin — Modération & Signalements

### `backend/src/controllers/admin/signalements.controller.js`
```javascript
const { supabase } = require('../../config/supabase');

// GET /api/admin/signalements (amélioration de l'existant)
const getSignalements = async (req, res) => {
  try {
    const {
      page = 1, limite = 20,
      statut,        // 'en_attente'|'traite'|'ignore'|'urgent'
      type_objet,    // 'offre'|'utilisateur'|'entreprise'
      ordre = 'date_signalement', direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('signalements')
      .select(`
        id, type_objet, objet_id, raison, statut,
        date_signalement, date_traitement,
        signalant:utilisateur_signalant_id (
          id, nom, email, role
        ),
        admin_traitant:admin_traitant_id (
          id, nom, email
        )
      `, { count: 'exact' })
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (statut)     query = query.eq('statut', statut);
    if (type_objet) query = query.eq('type_objet', type_objet);

    const { data, count, error } = await query;
    if (error) throw error;

    // Enrichir avec les détails de l'objet signalé
    const signalementsEnrichis = await Promise.all(
      (data || []).map(async (s) => {
        let objetDetails = null;
        if (s.type_objet === 'offre') {
          const { data: offre } = await supabase
            .from('offres_emploi')
            .select('titre, statut, entreprise:entreprise_id(nom_entreprise)')
            .eq('id', s.objet_id).single();
          objetDetails = offre;
        } else if (s.type_objet === 'utilisateur') {
          const { data: user } = await supabase
            .from('utilisateurs')
            .select('nom, email, role, est_actif')
            .eq('id', s.objet_id).single();
          objetDetails = user;
        }
        return { ...s, objet_details: objetDetails };
      })
    );

    // Compteurs par statut
    const { data: tousStatuts } = await supabase
      .from('signalements').select('statut');

    const stats = {
      en_attente: tousStatuts?.filter(s => s.statut === 'en_attente').length || 0,
      urgent:     tousStatuts?.filter(s => s.statut === 'urgent').length || 0,
      traites:    tousStatuts?.filter(s => s.statut === 'traite').length || 0,
      ignores:    tousStatuts?.filter(s => s.statut === 'ignore').length || 0,
    };

    return res.json({
      success: true,
      data: {
        signalements: signalementsEnrichis,
        stats,
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[getSignalements]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// PATCH /api/admin/signalements/:id
const updateSignalement = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, note } = req.body;
    // action: 'traiter'|'ignorer'|'marquer_urgent'

    const statuts = {
      traiter:         'traite',
      ignorer:         'ignore',
      marquer_urgent:  'urgent',
    };

    if (!statuts[action]) {
      return res.status(400).json({
        success: false,
        message: 'Action invalide. Valeurs: traiter, ignorer, marquer_urgent'
      });
    }

    const { data, error } = await supabase
      .from('signalements')
      .update({
        statut: statuts[action],
        admin_traitant_id: req.user.id,
        date_traitement: ['traiter', 'ignorer'].includes(action)
          ? new Date().toISOString() : null,
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: `Signalement ${action === 'traiter' ? 'traité' : action === 'ignorer' ? 'ignoré' : 'marqué urgent'}`,
      data
    });
  } catch (err) {
    console.error('[updateSignalement]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { getSignalements, updateSignalement };
```

---

## 12. Routes Admin — Notifications

### `backend/src/controllers/admin/notifications.controller.js`
```javascript
const { supabase } = require('../../config/supabase');

// ══════════════════════════════════════════════════════════════
// POST /api/admin/notifications
// Envoyer une notification à un groupe ou à un individu
// ══════════════════════════════════════════════════════════════
const envoyerNotification = async (req, res) => {
  try {
    const {
      titre,
      message,
      type = 'systeme',
      type_destinataire = 'tous', // 'tous'|'chercheurs'|'entreprises'|'individuel'
      destinataire_id = null,      // si 'individuel'
      lien = null,
    } = req.body;

    if (!titre || !message) {
      return res.status(400).json({
        success: false,
        message: 'Titre et message requis'
      });
    }

    if (type_destinataire === 'individuel' && !destinataire_id) {
      return res.status(400).json({
        success: false,
        message: 'destinataire_id requis pour envoi individuel'
      });
    }

    let notificationsAInserer = [];

    if (type_destinataire === 'individuel') {
      // Notification à un seul utilisateur
      notificationsAInserer.push({
        destinataire_id,
        type_destinataire: 'individuel',
        titre, message, type, lien,
        envoye_par: req.user.id,
      });
    } else {
      // Notification à un groupe
      let roleFilter = null;
      if (type_destinataire === 'chercheurs') roleFilter = 'chercheur';
      if (type_destinataire === 'entreprises') roleFilter = 'entreprise';

      let query = supabase.from('utilisateurs')
        .select('id').eq('est_actif', true);

      if (roleFilter) query = query.eq('role', roleFilter);

      const { data: users, error } = await query;
      if (error) throw error;

      notificationsAInserer = (users || []).map(u => ({
        destinataire_id: u.id,
        type_destinataire,
        titre, message, type, lien,
        envoye_par: req.user.id,
      }));
    }

    // Insertion en batch
    const { data, error } = await supabase
      .from('notifications')
      .insert(notificationsAInserer)
      .select('id');

    if (error) throw error;

    return res.status(201).json({
      success: true,
      message: `Notification envoyée à ${notificationsAInserer.length} utilisateur(s)`,
      data: {
        nb_envoyes: notificationsAInserer.length,
        ids: data?.map(n => n.id) || [],
      }
    });
  } catch (err) {
    console.error('[envoyerNotification]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// GET /api/admin/notifications
// Historique des notifications envoyées par les admins
const getNotifications = async (req, res) => {
  try {
    const { page = 1, limite = 20, type } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limite);

    // Récupérer les notifications envoyées par des admins
    // groupées par envoi (pas individuelles)
    let query = supabase
      .from('notifications')
      .select(`
        titre, message, type, type_destinataire, lien,
        date_envoi_reel, envoye_par,
        admin:envoye_par (nom, email)
      `, { count: 'exact' })
      .not('envoye_par', 'is', null)
      .order('date_envoi_reel', { ascending: false })
      .range(offset, offset + parseInt(limite) - 1);

    if (type) query = query.eq('type', type);

    const { data, count, error } = await query;
    if (error) throw error;

    return res.json({
      success: true,
      data: {
        notifications: data || [],
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });
  } catch (err) {
    console.error('[getNotifications]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

module.exports = { envoyerNotification, getNotifications };
```

---

## 13. Routes Admin — Paramètres Plateforme

### `backend/src/controllers/admin/parametres.controller.js`
```javascript
const { supabase } = require('../../config/supabase');

// GET /api/admin/parametres
// Lire tous les paramètres (groupés par catégorie)
const getParametres = async (req, res) => {
  try {
    const { categorie } = req.query;

    let query = supabase
      .from('parametres_plateforme')
      .select('*')
      .order('categorie')
      .order('cle');

    if (categorie) query = query.eq('categorie', categorie);

    const { data, error } = await query;
    if (error) throw error;

    // Grouper par catégorie
    const grouped = {};
    (data || []).forEach(p => {
      if (!grouped[p.categorie]) grouped[p.categorie] = [];

      // Convertir la valeur selon le type
      let valeurConvertie = p.valeur;
      if (p.type_valeur === 'boolean') valeurConvertie = p.valeur === 'true';
      if (p.type_valeur === 'integer') valeurConvertie = parseInt(p.valeur);
      if (p.type_valeur === 'json') {
        try { valeurConvertie = JSON.parse(p.valeur); } catch (e) {}
      }

      grouped[p.categorie].push({ ...p, valeur: valeurConvertie });
    });

    return res.json({ success: true, data: grouped });
  } catch (err) {
    console.error('[getParametres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// PUT /api/admin/parametres
// Modifier un ou plusieurs paramètres
// Body: { parametres: [{cle: 'xxx', valeur: 'yyy'}, ...] }
const updateParametres = async (req, res) => {
  try {
    const { parametres } = req.body;

    if (!Array.isArray(parametres) || parametres.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Tableau de paramètres requis'
      });
    }

    const resultats = [];
    const erreurs = [];

    for (const param of parametres) {
      if (!param.cle || param.valeur === undefined) {
        erreurs.push(`Paramètre invalide: ${JSON.stringify(param)}`);
        continue;
      }

      // Convertir la valeur en string pour le stockage
      const valeurString = typeof param.valeur === 'object'
        ? JSON.stringify(param.valeur)
        : String(param.valeur);

      const { data, error } = await supabase
        .from('parametres_plateforme')
        .update({
          valeur: valeurString,
          date_modification: new Date().toISOString(),
          modifie_par: req.user.id,
        })
        .eq('cle', param.cle)
        .eq('modifiable_admin', true)
        .select()
        .single();

      if (error) {
        erreurs.push(`Erreur pour '${param.cle}': ${error.message}`);
      } else {
        resultats.push(data);
      }
    }

    return res.json({
      success: erreurs.length === 0,
      message: erreurs.length === 0
        ? `${resultats.length} paramètre(s) mis à jour`
        : `${resultats.length} succès, ${erreurs.length} erreur(s)`,
      data: { mis_a_jour: resultats, erreurs }
    });
  } catch (err) {
    console.error('[updateParametres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// POST /api/admin/parametres/vider-cache
const viderCache = async (req, res) => {
  // Simuler vidage de cache (à adapter si cache Redis en place)
  return res.json({ success: true, message: 'Cache vidé avec succès' });
};

module.exports = { getParametres, updateParametres, viderCache };
```

---

## 14. Connexion Flutter — Service Admin

### `frontend/lib/services/admin_service.dart`
```dart
// lib/services/admin_service.dart
// Service Flutter pour toutes les API admin

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart'; // Service existant pour les headers auth

class AdminService {
  final String _base = '${ApiConfig.baseUrl}/api/admin';

  // Headers avec JWT
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── DASHBOARD ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard(String token) async {
    final res = await http.get(
      Uri.parse('$_base/dashboard'),
      headers: _headers(token),
    );
    return _handleResponse(res);
  }

  // ── STATISTIQUES ───────────────────────────────────────────
  Future<Map<String, dynamic>> getStatistiques(
    String token, {String periode = '30d'}
  ) async {
    final res = await http.get(
      Uri.parse('$_base/statistiques?periode=$periode'),
      headers: _headers(token),
    );
    return _handleResponse(res);
  }

  // ── UTILISATEURS ───────────────────────────────────────────
  Future<Map<String, dynamic>> getUtilisateurs(
    String token, {
    int page = 1, int limite = 20,
    String? role, String? statut, String? recherche,
  }) async {
    final params = {
      'page': '$page', 'limite': '$limite',
      if (role != null) 'role': role,
      if (statut != null) 'statut': statut,
      if (recherche != null) 'recherche': recherche,
    };
    final uri = Uri.parse('$_base/utilisateurs')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> getUtilisateur(String token, String id) async {
    final res = await http.get(
      Uri.parse('$_base/utilisateurs/$id'),
      headers: _headers(token),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateUtilisateur(
    String token, String id, String action, {String? raison}
  ) async {
    final res = await http.patch(
      Uri.parse('$_base/utilisateurs/$id'),
      headers: _headers(token),
      body: jsonEncode({'action': action, if (raison != null) 'raison': raison}),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteUtilisateur(String token, String id) async {
    final res = await http.delete(
      Uri.parse('$_base/utilisateurs/$id'),
      headers: _headers(token),
    );
    return _handleResponse(res);
  }

  // ── OFFRES ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getOffres(
    String token, {
    int page = 1, int limite = 20,
    String? statut, String? recherche,
  }) async {
    final params = {
      'page': '$page', 'limite': '$limite',
      if (statut != null) 'statut': statut,
      if (recherche != null) 'recherche': recherche,
    };
    final uri = Uri.parse('$_base/offres')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateOffre(
    String token, String id, String action, {String? raisonRefus}
  ) async {
    final res = await http.patch(
      Uri.parse('$_base/offres/$id'),
      headers: _headers(token),
      body: jsonEncode({
        'action': action,
        if (raisonRefus != null) 'raison_refus': raisonRefus,
      }),
    );
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> deleteOffre(String token, String id) async {
    final res = await http.delete(
      Uri.parse('$_base/offres/$id'),
      headers: _headers(token),
    );
    return _handleResponse(res);
  }

  // ── ENTREPRISES ────────────────────────────────────────────
  Future<Map<String, dynamic>> getEntreprises(
    String token, {int page = 1, int limite = 20, String? statut}
  ) async {
    final params = {
      'page': '$page', 'limite': '$limite',
      if (statut != null) 'statut': statut,
    };
    final uri = Uri.parse('$_base/entreprises')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateEntreprise(
    String token, String utilisateurId, String action, {String? raison}
  ) async {
    final res = await http.patch(
      Uri.parse('$_base/entreprises/$utilisateurId'),
      headers: _headers(token),
      body: jsonEncode({'action': action, if (raison != null) 'raison': raison}),
    );
    return _handleResponse(res);
  }

  // ── CANDIDATURES ───────────────────────────────────────────
  Future<Map<String, dynamic>> getCandidatures(
    String token, {int page = 1, int limite = 20, String? statut}
  ) async {
    final params = {
      'page': '$page', 'limite': '$limite',
      if (statut != null) 'statut': statut,
    };
    final uri = Uri.parse('$_base/candidatures')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    return _handleResponse(res);
  }

  // ── SIGNALEMENTS ───────────────────────────────────────────
  Future<Map<String, dynamic>> getSignalements(
    String token, {String? statut, String? typeObjet}
  ) async {
    final params = {
      if (statut != null) 'statut': statut,
      if (typeObjet != null) 'type_objet': typeObjet,
    };
    final uri = Uri.parse('$_base/signalements')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateSignalement(
    String token, String id, String action
  ) async {
    final res = await http.patch(
      Uri.parse('$_base/signalements/$id'),
      headers: _headers(token),
      body: jsonEncode({'action': action}),
    );
    return _handleResponse(res);
  }

  // ── NOTIFICATIONS ──────────────────────────────────────────
  Future<Map<String, dynamic>> envoyerNotification(
    String token, {
    required String titre,
    required String message,
    required String typeDestinataire,
    String? destinataireId,
    String type = 'systeme',
    String? lien,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/notifications'),
      headers: _headers(token),
      body: jsonEncode({
        'titre': titre,
        'message': message,
        'type': type,
        'type_destinataire': typeDestinataire,
        if (destinataireId != null) 'destinataire_id': destinataireId,
        if (lien != null) 'lien': lien,
      }),
    );
    return _handleResponse(res);
  }

  // ── PARAMÈTRES ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getParametres(
    String token, {String? categorie}
  ) async {
    final params = {if (categorie != null) 'categorie': categorie};
    final uri = Uri.parse('$_base/parametres')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> updateParametres(
    String token,
    List<Map<String, dynamic>> parametres,
  ) async {
    final res = await http.put(
      Uri.parse('$_base/parametres'),
      headers: _headers(token),
      body: jsonEncode({'parametres': parametres}),
    );
    return _handleResponse(res);
  }

  // ── ACTIVITÉ ───────────────────────────────────────────────
  Future<Map<String, dynamic>> getActivite(
    String token, {int page = 1, int limite = 20}
  ) async {
    final res = await http.get(
      Uri.parse('$_base/activite?page=$page&limite=$limite'),
      headers: _headers(token),
    );
    return _handleResponse(res);
  }

  // ── UTILITAIRE ─────────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    throw Exception(body['message'] ?? 'Erreur serveur ${res.statusCode}');
  }
}
```

---

## 15. Mise à jour du Client Flutter

### Mettre à jour les pages admin pour utiliser AdminService

```dart
// Pattern à utiliser dans TOUTES les pages admin :
// Remplacer les données mock par de vrais appels API

// Exemple : admin_dashboard_page.dart

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Récupérer le token depuis le provider/storage
      final token = context.read<AuthProvider>().token ?? '';
      final data = await _adminService.getDashboard(token);
      setState(() {
        _dashboardData = data['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState();

    final stats = _dashboardData?['stats'];
    // Utiliser stats['utilisateurs']['total'] etc.
    // Remplacer les valeurs hardcodées par ces vraies données

    return SingleChildScrollView(/* ... */);
  }

  // Pull-to-refresh
  Future<void> _onRefresh() => _loadDashboard();
}
```

### Modèles Dart à créer

```dart
// lib/models/admin_stats.dart
class AdminStats {
  final int totalUtilisateurs;
  final int totalChercheurs;
  final int totalEntreprises;
  final int usersEnAttente;
  final int usersBloques;
  final int offresActives;
  final int offresEnAttente;
  final int totalCandidatures;
  final int signalementsEnAttente;

  AdminStats.fromJson(Map<String, dynamic> json)
    : totalUtilisateurs = json['utilisateurs']?['total'] ?? 0,
      totalChercheurs   = json['utilisateurs']?['chercheurs'] ?? 0,
      totalEntreprises  = json['utilisateurs']?['entreprises'] ?? 0,
      usersEnAttente    = json['utilisateurs']?['en_attente'] ?? 0,
      usersBloques      = json['utilisateurs']?['bloques'] ?? 0,
      offresActives     = json['offres']?['actives'] ?? 0,
      offresEnAttente   = json['offres']?['en_attente'] ?? 0,
      totalCandidatures = json['candidatures']?['total_30j'] ?? 0,
      signalementsEnAttente = json['signalements']?['en_attente'] ?? 0;
}
```

---

## 16. Tests des Endpoints

### Fichier : `backend/tests/admin.test.http`
```http
### Variables
@baseUrl = http://localhost:3000/api
@token = VOTRE_JWT_TOKEN_ADMIN

### ── DASHBOARD ──────────────────────────────────────────────

# GET Dashboard complet
GET {{baseUrl}}/admin/dashboard
Authorization: Bearer {{token}}

###

# GET Statistiques (30 jours)
GET {{baseUrl}}/admin/statistiques?periode=30d
Authorization: Bearer {{token}}

###

# GET Statistiques (7 jours)
GET {{baseUrl}}/admin/statistiques?periode=7d
Authorization: Bearer {{token}}

###

# GET Activité admin
GET {{baseUrl}}/admin/activite?page=1&limite=10
Authorization: Bearer {{token}}

### ── UTILISATEURS ───────────────────────────────────────────

# GET Liste utilisateurs (tous)
GET {{baseUrl}}/admin/utilisateurs?page=1&limite=20
Authorization: Bearer {{token}}

###

# GET Liste utilisateurs (chercheurs en attente)
GET {{baseUrl}}/admin/utilisateurs?role=chercheur&statut=en_attente
Authorization: Bearer {{token}}

###

# GET Détail utilisateur
GET {{baseUrl}}/admin/utilisateurs/UUID_ICI
Authorization: Bearer {{token}}

###

# PATCH Valider un compte
PATCH {{baseUrl}}/admin/utilisateurs/UUID_ICI
Authorization: Bearer {{token}}
Content-Type: application/json

{"action": "valider"}

###

# PATCH Bloquer un compte
PATCH {{baseUrl}}/admin/utilisateurs/UUID_ICI
Authorization: Bearer {{token}}
Content-Type: application/json

{"action": "bloquer", "raison": "Compte suspect"}

###

# DELETE Supprimer un compte
DELETE {{baseUrl}}/admin/utilisateurs/UUID_ICI
Authorization: Bearer {{token}}

### ── OFFRES ─────────────────────────────────────────────────

# GET Liste offres en attente
GET {{baseUrl}}/admin/offres?statut=en_attente
Authorization: Bearer {{token}}

###

# PATCH Valider une offre
PATCH {{baseUrl}}/admin/offres/UUID_OFFRE
Authorization: Bearer {{token}}
Content-Type: application/json

{"action": "valider"}

###

# PATCH Refuser une offre
PATCH {{baseUrl}}/admin/offres/UUID_OFFRE
Authorization: Bearer {{token}}
Content-Type: application/json

{"action": "refuser", "raison_refus": "Offre incomplète ou non conforme"}

###

# PATCH Mettre en vedette
PATCH {{baseUrl}}/admin/offres/UUID_OFFRE
Authorization: Bearer {{token}}
Content-Type: application/json

{"action": "mettre_en_vedette"}

### ── SIGNALEMENTS ────────────────────────────────────────────

# GET Signalements en attente
GET {{baseUrl}}/admin/signalements?statut=en_attente
Authorization: Bearer {{token}}

###

# PATCH Traiter un signalement
PATCH {{baseUrl}}/admin/signalements/UUID_SIGNALEMENT
Authorization: Bearer {{token}}
Content-Type: application/json

{"action": "traiter"}

### ── NOTIFICATIONS ───────────────────────────────────────────

# POST Envoyer notification à tous
POST {{baseUrl}}/admin/notifications
Authorization: Bearer {{token}}
Content-Type: application/json

{
  "titre": "Maintenance planifiée",
  "message": "La plateforme sera en maintenance samedi de 2h à 4h.",
  "type": "systeme",
  "type_destinataire": "tous"
}

###

# POST Envoyer à un individu
POST {{baseUrl}}/admin/notifications
Authorization: Bearer {{token}}
Content-Type: application/json

{
  "titre": "Bienvenue !",
  "message": "Votre compte a été validé. Commencez dès maintenant !",
  "type": "validation_compte",
  "type_destinataire": "individuel",
  "destinataire_id": "UUID_USER"
}

### ── PARAMÈTRES ──────────────────────────────────────────────

# GET Tous les paramètres
GET {{baseUrl}}/admin/parametres
Authorization: Bearer {{token}}

###

# GET Paramètres d'une catégorie
GET {{baseUrl}}/admin/parametres?categorie=securite
Authorization: Bearer {{token}}

###

# PUT Modifier des paramètres
PUT {{baseUrl}}/admin/parametres
Authorization: Bearer {{token}}
Content-Type: application/json

{
  "parametres": [
    {"cle": "mode_maintenance", "valeur": false},
    {"cle": "max_offres_gratuit", "valeur": 10}
  ]
}
```

---

## 17. Critères d'Acceptation

### ✅ Migrations SQL
- [ ] `001_add_notifications.sql` exécuté dans Supabase SQL Editor
- [ ] `002_add_parametres_plateforme.sql` exécuté (avec données initiales)
- [ ] `003_add_activite_admin.sql` exécuté
- [ ] `004_alter_offres_add_featured.sql` exécuté
- [ ] `005_alter_utilisateurs_add_fields.sql` exécuté
- [ ] `006_add_stats_view.sql` exécuté
- [ ] Vérifier toutes les tables dans Supabase Table Editor

### ✅ Middleware
- [ ] `adminAuth.js` créé et fonctionne (401 si non connecté, 403 si non admin)
- [ ] `auditLog.js` créé et logue les actions sans bloquer les réponses
- [ ] Toutes les routes `/api/admin/` utilisent `auth + requireAdmin`

### ✅ Routes Dashboard & Stats
- [ ] `GET /api/admin/dashboard` → retourne stats, activité récente, offres en attente, derniers users
- [ ] `GET /api/admin/statistiques?periode=7d` → retourne KPIs avec tendances %
- [ ] `GET /api/admin/statistiques?periode=30d` → idem
- [ ] `GET /api/admin/activite` → journal d'audit paginé

### ✅ Routes Utilisateurs
- [ ] `GET /api/admin/utilisateurs` → liste paginée avec filtres (role, statut, recherche)
- [ ] `GET /api/admin/utilisateurs/:id` → détail complet avec candidatures/offres liées
- [ ] `PATCH /api/admin/utilisateurs/:id` → actions valider/activer/bloquer/modifier
- [ ] `DELETE /api/admin/utilisateurs/:id` → suppression avec cascade

### ✅ Routes Offres
- [ ] `GET /api/admin/offres` → liste avec stats candidatures par offre
- [ ] `PATCH /api/admin/offres/:id` → valider/refuser/vedette/archiver
- [ ] `DELETE /api/admin/offres/:id` → suppression

### ✅ Routes Entreprises
- [ ] `GET /api/admin/entreprises` → liste avec nb offres
- [ ] `PATCH /api/admin/entreprises/:id` → valider/suspendre/réactiver

### ✅ Routes Candidatures
- [ ] `GET /api/admin/candidatures` → vue globale avec filtres

### ✅ Routes Signalements
- [ ] `GET /api/admin/signalements` → liste enrichie avec détails objet signalé
- [ ] `PATCH /api/admin/signalements/:id` → traiter/ignorer/urgent

### ✅ Routes Notifications
- [ ] `POST /api/admin/notifications` → envoi groupé ou individuel
- [ ] `GET /api/admin/notifications` → historique

### ✅ Routes Paramètres
- [ ] `GET /api/admin/parametres` → lecture groupée par catégorie
- [ ] `PUT /api/admin/parametres` → modification batch

### ✅ Flutter AdminService
- [ ] `AdminService` créé dans `frontend/lib/services/admin_service.dart`
- [ ] Toutes les méthodes retournent `Map<String, dynamic>`
- [ ] Gestion des erreurs avec `throw Exception(message)`
- [ ] Pages admin remplacent les données mock par appels réels
- [ ] Modèle `AdminStats` créé et utilisé dans le dashboard

### ✅ Qualité Backend
- [ ] Tous les endpoints retournent `{ success: true/false, data: ..., message: ... }`
- [ ] Pagination cohérente sur toutes les listes
- [ ] Validation des paramètres d'entrée sur chaque route
- [ ] Logs d'erreur avec `console.error('[context]', err)`
- [ ] Aucune donnée sensible (mot de passe) dans les réponses API
- [ ] Tests `.http` validés sur tous les endpoints

---

*PRD EmploiConnect v3.0 — Backend Admin — Node.js + Express + PostgreSQL/Supabase*
*Projet académique — Licence Professionnelle Génie Logiciel — Guinée 2025-2026*
*BARRY YOUSSOUF (22 000 46) · DIALLO ISMAILA (23 008 60)*
*Encadré par M. DIALLO BOUBACAR — CEO Rasenty*
*Cursor / Kirsoft AI — Phase 7 — Backend Admin après Frontend validé*
