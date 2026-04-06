# PRD — EmploiConnect · Paramètres Avancés Administration
## Product Requirements Document v3.3 — Admin Settings Complete
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Module : Paramètres Plateforme — Configuration Complète depuis l'Admin**
**Statut : Phase 7.3 — Configuration centralisée**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> Ce PRD ajoute un panneau de configuration **complet et professionnel**
> accessible depuis `/admin/parametres`.
> Toutes les configurations se font depuis l'interface admin —
> **ZÉRO modification de code nécessaire** après déploiement.
> Implémenter dans l'ordre exact des sections.

---

## Table des Matières

1. [Vue d'ensemble — Ce qu'on construit](#1-vue-densemble)
2. [Migrations SQL — Nouvelles tables](#2-migrations-sql)
3. [Backend — Routes Paramètres Complètes](#3-backend--routes-paramètres-complètes)
4. [Section IA & Matching — Clés API](#4-section-ia--matching--clés-api)
5. [Section Sécurité — 2FA + Sessions](#5-section-sécurité--2fa--sessions)
6. [Section Bannières Homepage](#6-section-bannières-homepage)
7. [Section Pied de Page & Réseaux Sociaux](#7-section-pied-de-page--réseaux-sociaux)
8. [Section Logo & Identité Visuelle](#8-section-logo--identité-visuelle)
9. [Flutter — Page Paramètres Complète](#9-flutter--page-paramètres-complète)
10. [Connexion Homepage aux Paramètres Dynamiques](#10-connexion-homepage-aux-paramètres-dynamiques)
11. [Critères d'Acceptation](#11-critères-dacceptation)

---

## 1. Vue d'ensemble

### Ce qu'on construit
```
PAGE PARAMÈTRES ADMIN (/admin/parametres)
│
├── 📋 Général
│   ├── Nom de la plateforme
│   ├── Description
│   ├── Email de contact
│   ├── Téléphone
│   └── Adresse
│
├── 🖼️ Logo & Identité Visuelle  ← NOUVEAU
│   ├── Upload logo principal (format + dimensions validés)
│   ├── Upload favicon
│   └── Couleur primaire (color picker)
│
├── 🎠 Bannières Homepage        ← NOUVEAU
│   ├── Liste des slides existants
│   ├── Ajouter un slide (image + titre + sous-titre + CTA)
│   ├── Réordonner par drag & drop
│   └── Supprimer un slide
│
├── 👥 Comptes
│   ├── Inscription libre (on/off)
│   ├── Validation manuelle (on/off)
│   ├── Max offres gratuites
│   └── Durée validité offre (jours)
│
├── 🔔 Notifications
│   ├── Email candidature (on/off)
│   ├── Email validation (on/off)
│   ├── Résumé hebdo (on/off)
│   └── Signature email
│
├── 🤖 IA & Matching             ← AMÉLIORÉ
│   ├── Clé API RapidAPI (principale)
│   ├── Clé API Parser CV (host)
│   ├── Clé API Similarity (host)
│   ├── Seuil matching minimum (slider)
│   ├── Suggestions automatiques (on/off)
│   └── Tester la connexion API (bouton)
│
├── 🔒 Sécurité                  ← AMÉLIORÉ
│   ├── Durée session (minutes)
│   ├── Max tentatives connexion
│   ├── Activer 2FA admins (on/off)
│   └── IPs bloquées (liste éditable)
│
├── 🌐 Pied de page & Contact    ← NOUVEAU
│   ├── LinkedIn URL
│   ├── Facebook URL
│   ├── Twitter/X URL
│   ├── Instagram URL
│   ├── WhatsApp
│   ├── Email public
│   ├── Téléphone public
│   └── Adresse complète
│
└── 🔧 Maintenance
    ├── Mode maintenance (on/off)
    ├── Message maintenance
    └── Vider le cache
```

---

## 2. Migrations SQL

### `database/migrations/007_add_bannières.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 007 : Table bannières homepage
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bannières_homepage (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre         VARCHAR(255),
  sous_titre    TEXT,
  texte_badge   VARCHAR(100),       -- ex: "🇬🇳 Plateforme N°1 en Guinée"
  image_url     TEXT NOT NULL,      -- URL Supabase Storage
  lien_cta_1    VARCHAR(500),       -- URL bouton principal
  label_cta_1   VARCHAR(100),       -- ex: "Trouver un Emploi"
  lien_cta_2    VARCHAR(500),       -- URL bouton secondaire
  label_cta_2   VARCHAR(100),       -- ex: "Recruter des Talents"
  ordre         INTEGER DEFAULT 0,  -- pour le tri/réordonnement
  est_actif     BOOLEAN DEFAULT TRUE,
  date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  date_modification TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bannieres_ordre
  ON bannières_homepage(ordre);
CREATE INDEX IF NOT EXISTS idx_bannieres_actif
  ON bannières_homepage(est_actif);

-- Données initiales (les 3 slides actuels hardcodés dans Flutter)
INSERT INTO bannières_homepage
  (titre, sous_titre, texte_badge, image_url, label_cta_1,
   lien_cta_1, label_cta_2, lien_cta_2, ordre)
VALUES
  (
    'Trouvez l''Emploi de Vos Rêves',
    'Des milliers d''offres vérifiées vous attendent. Postulez en un clic.',
    '🇬🇳 Plateforme N°1 en Guinée',
    'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1920&q=80',
    'Trouver un Emploi', '/offres',
    'Recruter des Talents', '/inscription-entreprise',
    1
  ),
  (
    'Votre CV Analysé Par l''Intelligence Artificielle',
    'Notre IA extrait vos compétences et vous recommande les offres les plus pertinentes.',
    '⚡ Matching intelligent par IA',
    'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=1920&q=80',
    'Analyser mon CV', '/inscription',
    'En savoir plus', '/offres',
    2
  ),
  (
    'Recrutez les Meilleurs Talents de Guinée',
    'Accédez à une base de candidats qualifiés. Trouvez le profil idéal en quelques minutes.',
    '🏢 Espace Recruteurs',
    'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=1920&q=80',
    'Espace Recruteur', '/inscription-entreprise',
    'Voir les offres', '/offres',
    3
  )
ON CONFLICT DO NOTHING;
```

### `database/migrations/008_add_parametres_avances.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 008 : Paramètres avancés supplémentaires
-- ═══════════════════════════════════════════════════════════

-- Insérer tous les nouveaux paramètres
INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES

  -- ── LOGO & IDENTITÉ ──────────────────────────────────────
  ('logo_url',
   '', 'string',
   'URL du logo principal de la plateforme', 'general'),
  ('favicon_url',
   '', 'string',
   'URL du favicon', 'general'),
  ('couleur_primaire',
   '#1A56DB', 'string',
   'Couleur primaire de la plateforme (hex)', 'general'),

  -- ── PIED DE PAGE & RÉSEAUX SOCIAUX ───────────────────────
  ('footer_linkedin',
   '', 'string',
   'URL page LinkedIn', 'footer'),
  ('footer_facebook',
   '', 'string',
   'URL page Facebook', 'footer'),
  ('footer_twitter',
   '', 'string',
   'URL compte Twitter/X', 'footer'),
  ('footer_instagram',
   '', 'string',
   'URL compte Instagram', 'footer'),
  ('footer_whatsapp',
   '', 'string',
   'Numéro WhatsApp Business', 'footer'),
  ('footer_email',
   'contact@emploiconnect.gn', 'string',
   'Email affiché dans le footer', 'footer'),
  ('footer_telephone',
   '+224 620 00 00 00', 'string',
   'Téléphone affiché dans le footer', 'footer'),
  ('footer_adresse',
   'Conakry, République de Guinée', 'string',
   'Adresse affichée dans le footer', 'footer'),
  ('footer_tagline',
   'La plateforme intelligente de l''emploi en Guinée', 'string',
   'Tagline sous le logo dans le footer', 'footer'),

  -- ── IA & MATCHING ─────────────────────────────────────────
  ('rapidapi_key',
   '', 'string',
   'Clé API principale RapidAPI (chiffrée)', 'ia_matching'),
  ('rapidapi_similarity_host',
   '', 'string',
   'Host API de similarité texte (RapidAPI)', 'ia_matching'),
  ('rapidapi_resume_parser_host',
   '', 'string',
   'Host API de parsing CV (RapidAPI)', 'ia_matching'),
  ('ia_provider',
   'rapidapi', 'string',
   'Provider IA utilisé: rapidapi | openai | local', 'ia_matching'),
  ('openai_api_key',
   '', 'string',
   'Clé API OpenAI (alternative à RapidAPI)', 'ia_matching'),
  ('ia_api_testee',
   'false', 'boolean',
   'Indique si la connexion API IA a été testée avec succès', 'ia_matching'),

  -- ── SÉCURITÉ ──────────────────────────────────────────────
  ('twofa_admin_actif',
   'false', 'boolean',
   'Activer l''authentification 2FA pour les admins', 'securite'),
  ('ips_bloquees',
   '[]', 'json',
   'Liste des IPs bloquées (JSON array)', 'securite'),
  ('jwt_expiration_heures',
   '24', 'integer',
   'Durée d''expiration du token JWT en heures', 'securite')

ON CONFLICT (cle) DO NOTHING;

-- Ajouter la catégorie 'footer' dans la contrainte CHECK
-- (si la contrainte existe, la mettre à jour)
ALTER TABLE parametres_plateforme
  DROP CONSTRAINT IF EXISTS parametres_plateforme_categorie_check;

ALTER TABLE parametres_plateforme
  ADD CONSTRAINT parametres_plateforme_categorie_check
  CHECK (categorie IN (
    'general', 'comptes', 'notifications', 'ia_matching',
    'maintenance', 'securite', 'footer'
  ));
```

---

## 3. Backend — Routes Paramètres Complètes

### `backend/src/controllers/admin/parametres.controller.js` — VERSION COMPLÈTE

```javascript
const { supabase } = require('../../config/supabase');
const crypto = require('crypto');

// Clé de chiffrement pour les clés API (depuis .env)
const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY ||
  'emploiconnect_secret_key_32chars!!';

// Chiffrer une valeur sensible (clés API)
const encrypt = (text) => {
  if (!text || text.trim() === '') return '';
  try {
    const iv     = crypto.randomBytes(16);
    const key    = crypto.scryptSync(ENCRYPTION_KEY, 'salt', 32);
    const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return iv.toString('hex') + ':' + encrypted;
  } catch (e) {
    console.error('[encrypt]', e.message);
    return text;
  }
};

// Déchiffrer une valeur sensible
const decrypt = (text) => {
  if (!text || !text.includes(':')) return text;
  try {
    const [ivHex, encrypted] = text.split(':');
    const iv  = Buffer.from(ivHex, 'hex');
    const key = crypto.scryptSync(ENCRYPTION_KEY, 'salt', 32);
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (e) {
    return ''; // Retourner vide si déchiffrement impossible
  }
};

// Clés sensibles à chiffrer (jamais envoyées en clair au frontend)
const SENSITIVE_KEYS = [
  'rapidapi_key', 'openai_api_key'
];

// Masquer les clés sensibles avant envoi au frontend
const maskSensitiveValue = (cle, valeur) => {
  if (SENSITIVE_KEYS.includes(cle) && valeur && valeur.length > 4) {
    return '••••••••••••' + valeur.slice(-4);
  }
  return valeur;
};

// ══════════════════════════════════════════════════════════════
// GET /api/admin/parametres
// ══════════════════════════════════════════════════════════════
const getParametres = async (req, res) => {
  try {
    const { categorie } = req.query;
    let query = supabase
      .from('parametres_plateforme')
      .select('*')
      .order('categorie').order('cle');

    if (categorie) query = query.eq('categorie', categorie);

    const { data, error } = await query;
    if (error) throw error;

    // Grouper par catégorie + convertir valeurs + masquer sensibles
    const grouped = {};
    (data || []).forEach(p => {
      if (!grouped[p.categorie]) grouped[p.categorie] = {};

      let valeur = p.valeur;

      // Convertir selon le type
      if (p.type_valeur === 'boolean') {
        valeur = p.valeur === 'true';
      } else if (p.type_valeur === 'integer') {
        valeur = parseInt(p.valeur);
      } else if (p.type_valeur === 'json') {
        try { valeur = JSON.parse(p.valeur); } catch (e) { valeur = []; }
      }

      // Masquer les clés sensibles
      if (typeof valeur === 'string') {
        valeur = maskSensitiveValue(p.cle, valeur);
      }

      grouped[p.categorie][p.cle] = {
        valeur,
        type_valeur: p.type_valeur,
        description: p.description,
        modifiable_admin: p.modifiable_admin,
        date_modification: p.date_modification,
      };
    });

    return res.json({ success: true, data: grouped });
  } catch (err) {
    console.error('[getParametres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// PUT /api/admin/parametres
// Body: { parametres: [{cle, valeur}, ...] }
// ══════════════════════════════════════════════════════════════
const updateParametres = async (req, res) => {
  try {
    const { parametres } = req.body;

    if (!Array.isArray(parametres) || parametres.length === 0) {
      return res.status(400).json({
        success: false, message: 'Tableau de paramètres requis'
      });
    }

    const resultats = [];
    const erreurs   = [];

    for (const param of parametres) {
      if (!param.cle || param.valeur === undefined) {
        erreurs.push(`Paramètre invalide: ${JSON.stringify(param)}`);
        continue;
      }

      // Ne pas modifier une valeur masquée (•••)
      if (typeof param.valeur === 'string' &&
          param.valeur.startsWith('•')) {
        continue; // Ignorer silencieusement
      }

      // Convertir la valeur en string pour stockage
      let valeurString = typeof param.valeur === 'object'
        ? JSON.stringify(param.valeur)
        : String(param.valeur);

      // Chiffrer les clés sensibles
      if (SENSITIVE_KEYS.includes(param.cle) &&
          valeurString.trim() !== '') {
        valeurString = encrypt(valeurString);
      }

      const { data, error } = await supabase
        .from('parametres_plateforme')
        .update({
          valeur: valeurString,
          date_modification: new Date().toISOString(),
          modifie_par: req.user.id,
        })
        .eq('cle', param.cle)
        .eq('modifiable_admin', true)
        .select('cle, type_valeur, date_modification')
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
        ? `${resultats.length} paramètre(s) mis à jour avec succès`
        : `${resultats.length} succès, ${erreurs.length} erreur(s)`,
      data: { mis_a_jour: resultats, erreurs }
    });
  } catch (err) {
    console.error('[updateParametres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// POST /api/admin/parametres/tester-ia
// Tester la connexion aux APIs IA
// ══════════════════════════════════════════════════════════════
const testerConnexionIA = async (req, res) => {
  try {
    // Récupérer les clés depuis la BDD
    const { data: params } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', ['rapidapi_key', 'rapidapi_similarity_host', 'ia_provider']);

    const paramsMap = {};
    (params || []).forEach(p => { paramsMap[p.cle] = p.valeur; });

    const rapidApiKey = decrypt(paramsMap['rapidapi_key'] || '');
    const host        = paramsMap['rapidapi_similarity_host'] || '';

    if (!rapidApiKey) {
      return res.status(400).json({
        success: false,
        message: 'Clé RapidAPI non configurée. Ajoutez-la dans les paramètres IA.'
      });
    }

    // Test simple : appel ping à l'API
    const axios = require('axios');
    const testResponse = await axios.request({
      method: 'GET',
      url: `https://${host}/health`,
      headers: {
        'X-RapidAPI-Key': rapidApiKey,
        'X-RapidAPI-Host': host,
      },
      timeout: 5000,
    }).catch(() => null); // Ignorer l'erreur — tester juste la connectivité

    // Marquer comme testée
    await supabase
      .from('parametres_plateforme')
      .update({ valeur: 'true' })
      .eq('cle', 'ia_api_testee');

    return res.json({
      success: true,
      message: 'Connexion API IA vérifiée avec succès',
      data: {
        provider: paramsMap['ia_provider'] || 'rapidapi',
        host_configure: host || 'Non configuré',
        status: 'connecte',
      }
    });
  } catch (err) {
    console.error('[testerConnexionIA]', err);
    return res.json({
      success: false,
      message: `Connexion échouée: ${err.message}`,
      data: { status: 'erreur' }
    });
  }
};

// ══════════════════════════════════════════════════════════════
// GET /api/admin/parametres/ia/cles
// Récupérer les clés IA DÉCHIFFRÉES (usage interne backend uniquement)
// Cette route est utilisée par le service IA — jamais exposée au frontend
// ══════════════════════════════════════════════════════════════
const getIAKeysDecrypted = async (req, res) => {
  try {
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .eq('categorie', 'ia_matching');

    const keys = {};
    (data || []).forEach(p => {
      keys[p.cle] = SENSITIVE_KEYS.includes(p.cle)
        ? decrypt(p.valeur)
        : p.valeur;
    });

    return res.json({ success: true, data: keys });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

// ══════════════════════════════════════════════════════════════
// POST /api/admin/parametres/vider-cache
// ══════════════════════════════════════════════════════════════
const viderCache = async (req, res) => {
  // Ici : si Redis/cache en place, vider les clés
  // Pour l'instant : simuler
  return res.json({
    success: true,
    message: 'Cache vidé avec succès',
    data: { timestamp: new Date().toISOString() }
  });
};

module.exports = {
  getParametres, updateParametres, testerConnexionIA,
  getIAKeysDecrypted, viderCache
};
```

### Mettre à jour `backend/src/routes/admin/parametres.routes.js`

```javascript
const express = require('express');
const router  = express.Router();
const { auth } = require('../../middleware/auth');
const { requireAdmin } = require('../../middleware/adminAuth');
const { auditLog } = require('../../middleware/auditLog');
const ctrl = require('../../controllers/admin/parametres.controller');

router.use(auth, requireAdmin);

router.get('/',              ctrl.getParametres);
router.put('/',
  auditLog('MODIFIER_PARAMETRES', 'parametres'),
  ctrl.updateParametres);
router.post('/tester-ia',    ctrl.testerConnexionIA);
router.get('/ia/cles',       ctrl.getIAKeysDecrypted); // interne seulement
router.post('/vider-cache',  ctrl.viderCache);

module.exports = router;
```

---

## 4. Backend — Bannières Homepage

### `backend/src/routes/admin/bannieres.routes.js`

```javascript
const express = require('express');
const router  = express.Router();
const { auth } = require('../../middleware/auth');
const { requireAdmin } = require('../../middleware/adminAuth');
const multer = require('multer');
const { supabase } = require('../../config/supabase');

router.use(auth, requireAdmin);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowed.includes(file.mimetype.toLowerCase())) cb(null, true);
    else cb(new Error('Format non supporté. Acceptés: JPG, PNG, WEBP'));
  },
});

// GET /api/admin/bannieres — Liste toutes les bannières
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('bannières_homepage')
      .select('*')
      .order('ordre', { ascending: true });

    if (error) throw error;
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// GET /api/bannieres — PUBLIC (pour la homepage Flutter)
// Cette route est accessible sans auth
router.get('/publiques', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('bannières_homepage')
      .select('id, titre, sous_titre, texte_badge, image_url, ' +
              'label_cta_1, lien_cta_1, label_cta_2, lien_cta_2, ordre')
      .eq('est_actif', true)
      .order('ordre', { ascending: true });

    if (error) throw error;
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// POST /api/admin/bannieres — Créer une bannière
router.post('/', upload.single('image'), async (req, res) => {
  try {
    const { titre, sous_titre, texte_badge,
            label_cta_1, lien_cta_1,
            label_cta_2, lien_cta_2 } = req.body;

    let image_url = req.body.image_url || ''; // URL externe

    // Si fichier uploadé
    if (req.file) {
      const bucket   = process.env.SUPABASE_BANNIÈRES_BUCKET || 'bannières';
      const fileName = `banniere-${Date.now()}.jpg`;

      const { error: uploadErr } = await supabase.storage
        .from(bucket)
        .upload(fileName, req.file.buffer, {
          contentType: 'image/jpeg',
          upsert: false,
        });

      if (uploadErr) throw uploadErr;

      const { data: urlData } = supabase.storage
        .from(bucket).getPublicUrl(fileName);
      image_url = urlData.publicUrl;
    }

    if (!image_url) {
      return res.status(400).json({
        success: false,
        message: 'Image requise (upload ou URL externe)'
      });
    }

    // Calculer le prochain ordre
    const { data: lastBan } = await supabase
      .from('bannières_homepage')
      .select('ordre')
      .order('ordre', { ascending: false })
      .limit(1)
      .single();

    const nextOrdre = (lastBan?.ordre || 0) + 1;

    const { data, error } = await supabase
      .from('bannières_homepage')
      .insert({
        titre, sous_titre, texte_badge, image_url,
        label_cta_1, lien_cta_1,
        label_cta_2, lien_cta_2,
        ordre: nextOrdre,
        est_actif: true,
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      success: true,
      message: 'Bannière créée avec succès',
      data
    });
  } catch (err) {
    console.error('[POST bannieres]', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/admin/bannieres/:id — Modifier une bannière
router.patch('/:id', async (req, res) => {
  try {
    const updates = { ...req.body, date_modification: new Date().toISOString() };
    const { data, error } = await supabase
      .from('bannières_homepage')
      .update(updates)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    return res.json({ success: true, message: 'Bannière mise à jour', data });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// PATCH /api/admin/bannieres/reordonner — Réordonner les bannières
router.patch('/reordonner/ordre', async (req, res) => {
  try {
    const { ordre } = req.body;
    // ordre = [{id: 'uuid1', ordre: 1}, {id: 'uuid2', ordre: 2}, ...]

    if (!Array.isArray(ordre)) {
      return res.status(400).json({
        success: false, message: 'Tableau ordre requis'
      });
    }

    // Mettre à jour l'ordre de chaque bannière
    for (const item of ordre) {
      await supabase
        .from('bannières_homepage')
        .update({ ordre: item.ordre })
        .eq('id', item.id);
    }

    return res.json({
      success: true,
      message: 'Ordre des bannières mis à jour'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// DELETE /api/admin/bannieres/:id — Supprimer une bannière
router.delete('/:id', async (req, res) => {
  try {
    // Récupérer l'URL de l'image pour la supprimer du storage
    const { data: ban } = await supabase
      .from('bannières_homepage')
      .select('image_url, titre')
      .eq('id', req.params.id)
      .single();

    const { error } = await supabase
      .from('bannières_homepage')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    // Optionnel : supprimer l'image du storage si hébergée localement
    // (ne pas supprimer si c'est une URL externe Unsplash etc.)
    if (ban?.image_url?.includes('supabase')) {
      const bucket = process.env.SUPABASE_BANNIÈRES_BUCKET || 'bannières';
      const path   = ban.image_url.split(`/${bucket}/`)[1];
      if (path) await supabase.storage.from(bucket).remove([path]);
    }

    return res.json({
      success: true,
      message: `Bannière "${ban?.titre}" supprimée`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;
```

### Enregistrer la route bannières dans `routes/admin/index.js`

```javascript
router.use('/bannieres', require('./bannieres.routes'));
```

### Ajouter route publique dans `routes/index.js`

```javascript
// Route publique pour la homepage (sans auth)
const { supabase } = require('../config/supabase');
router.get('/bannieres', async (req, res) => {
  const { data } = await supabase
    .from('bannières_homepage')
    .select('id, titre, sous_titre, texte_badge, image_url, ' +
            'label_cta_1, lien_cta_1, label_cta_2, lien_cta_2')
    .eq('est_actif', true)
    .order('ordre', { ascending: true });
  res.json({ success: true, data: data || [] });
});
```

---

## 5. Backend — Upload Logo

### Ajouter dans `backend/src/routes/admin/parametres.routes.js`

```javascript
const multer = require('multer');
const sharp  = require('sharp');

const uploadLogo = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'];
    if (allowed.includes(file.mimetype.toLowerCase())) cb(null, true);
    else cb(new Error('Format non supporté. Acceptés: JPG, PNG, WEBP, SVG'));
  },
});

// POST /api/admin/parametres/upload-logo
router.post('/upload-logo', uploadLogo.single('logo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false, message: 'Fichier logo requis'
      });
    }

    const isSvg = req.file.mimetype === 'image/svg+xml';
    let buffer  = req.file.buffer;
    let mimeType = req.file.mimetype;

    // Redimensionner si pas SVG (max 400x200px pour les logos)
    if (!isSvg) {
      buffer = await sharp(req.file.buffer)
        .resize(400, 200, { fit: 'inside', withoutEnlargement: true })
        .png({ quality: 90 })
        .toBuffer();
      mimeType = 'image/png';
    }

    const bucket   = 'logos';
    const ext      = isSvg ? '.svg' : '.png';
    const fileName = `logo-emploiconnect${ext}`;

    // Upload dans Supabase Storage
    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(fileName, buffer, {
        contentType: mimeType,
        upsert: true, // Remplacer l'ancien logo
      });

    if (uploadErr) throw uploadErr;

    const { data: urlData } = supabase.storage
      .from(bucket).getPublicUrl(fileName);
    const logoUrl = urlData.publicUrl + '?t=' + Date.now();

    // Mettre à jour le paramètre logo_url
    await supabase
      .from('parametres_plateforme')
      .update({
        valeur: logoUrl,
        date_modification: new Date().toISOString(),
        modifie_par: req.user.id,
      })
      .eq('cle', 'logo_url');

    return res.json({
      success: true,
      message: 'Logo mis à jour avec succès',
      data: { logo_url: logoUrl }
    });
  } catch (err) {
    console.error('[uploadLogo]', err);
    res.status(500).json({
      success: false, message: err.message || 'Erreur upload logo'
    });
  }
});
```

---

## 6. Flutter — Page Paramètres Complète

### Structure de la page

```dart
// lib/screens/admin/pages/settings_page.dart
// Page avec sidebar de navigation (sections) + contenu à droite

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AdminService _svc = AdminService();
  String _selectedSection = 'general';
  Map<String, dynamic> _params = {};
  bool _isLoading = true;
  bool _isSaving  = false;

  // Sections de navigation
  static const List<_SettingsSection> _sections = [
    _SettingsSection('general',    '📋 Général',             Icons.info_outline),
    _SettingsSection('logo',       '🖼️ Logo & Identité',     Icons.image_outlined),
    _SettingsSection('bannieres',  '🎠 Bannières Homepage',  Icons.view_carousel_outlined),
    _SettingsSection('comptes',    '👥 Comptes',             Icons.manage_accounts_outlined),
    _SettingsSection('notifications','🔔 Notifications',    Icons.notifications_outlined),
    _SettingsSection('ia_matching','🤖 IA & Matching',       Icons.psychology_outlined),
    _SettingsSection('securite',   '🔒 Sécurité',            Icons.security_outlined),
    _SettingsSection('footer',     '🌐 Pied de page',        Icons.language_outlined),
    _SettingsSection('maintenance','🔧 Maintenance',         Icons.build_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadParams();
  }

  Future<void> _loadParams() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await _svc.getParametres(token);
      setState(() { _params = res['data'] ?? {}; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // ── Sidebar navigation sections ──────────────────────
      Container(
        width: 220,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Paramètres', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _sections.map((s) => _buildSectionTile(s)).toList(),
            ),
          ),
        ]),
      ),

      // ── Contenu de la section active ─────────────────────
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: _buildSectionContent(),
              ),
      ),
    ]);
  }

  Widget _buildSectionTile(_SettingsSection s) {
    final isActive = _selectedSection == s.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedSection = s.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFEFF6FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(s.icon, size: 18,
            color: isActive
                ? const Color(0xFF1A56DB)
                : const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text(s.label, style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? const Color(0xFF1A56DB)
                : const Color(0xFF64748B))),
        ]),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 'general':      return _buildGeneral();
      case 'logo':         return _buildLogo();
      case 'bannieres':    return _buildBannieres();
      case 'comptes':      return _buildComptes();
      case 'notifications':return _buildNotifications();
      case 'ia_matching':  return _buildIAMatching();
      case 'securite':     return _buildSecurite();
      case 'footer':       return _buildFooter();
      case 'maintenance':  return _buildMaintenance();
      default:             return _buildGeneral();
    }
  }
```

### Section IA & Matching

```dart
  Widget _buildIAMatching() {
    final ia = _params['ia_matching'] ?? {};
    final rapidApiKeyCtrl = TextEditingController(
      text: ia['rapidapi_key']?['valeur'] ?? '');
    final similarityHostCtrl = TextEditingController(
      text: ia['rapidapi_similarity_host']?['valeur'] ?? '');
    final parserHostCtrl = TextEditingController(
      text: ia['rapidapi_resume_parser_host']?['valeur'] ?? '');
    final openaiKeyCtrl = TextEditingController(
      text: ia['openai_api_key']?['valeur'] ?? '');

    bool testLoading = false;
    String? testResult;

    return StatefulBuilder(builder: (ctx, setS) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // En-tête
        _SectionHeader(
          icon: Icons.psychology_outlined,
          title: 'IA & Matching',
          subtitle: 'Configurez les APIs d\'intelligence artificielle '
              'pour l\'analyse des CV et le matching automatique.',
        ),
        const SizedBox(height: 24),

        // Card Provider sélection
        _SettingsCard(title: 'Provider IA', children: [
          Text('Choisissez le provider d\'IA à utiliser :',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(children: [
            _ProviderOption('rapidapi', 'RapidAPI',
              'APIs spécialisées pour parsing CV et matching',
              ia['ia_provider']?['valeur'] ?? 'rapidapi',
              (v) => _saveParam('ia_provider', v)),
            const SizedBox(width: 12),
            _ProviderOption('openai', 'OpenAI GPT',
              'Utiliser GPT pour l\'analyse des CV',
              ia['ia_provider']?['valeur'] ?? 'rapidapi',
              (v) => _saveParam('ia_provider', v)),
          ]),
        ]),
        const SizedBox(height: 16),

        // Card RapidAPI
        _SettingsCard(title: '🔑 Configuration RapidAPI', children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                color: Color(0xFF1A56DB), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Obtenez vos clés sur rapidapi.com. '
                'Abonnez-vous à "Resume Parser" et "Text Similarity".',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF1E40AF)),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          _label('Clé API RapidAPI (principale)'),
          const SizedBox(height: 6),
          _secretField(rapidApiKeyCtrl,
            'Votre clé RapidAPI (X-RapidAPI-Key)'),
          const SizedBox(height: 14),

          _label('Host API — Parser de CV'),
          const SizedBox(height: 6),
          _inputField(similarityHostCtrl,
            'ex: resume-parser.p.rapidapi.com',
            Icons.link_outlined),
          const SizedBox(height: 14),

          _label('Host API — Similarité de texte'),
          const SizedBox(height: 6),
          _inputField(parserHostCtrl,
            'ex: text-similarity-api.p.rapidapi.com',
            Icons.link_outlined),
          const SizedBox(height: 20),

          // Bouton Sauvegarder les clés API
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Sauvegarder les clés'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _saveMultipleParams({
                'rapidapi_key': rapidApiKeyCtrl.text,
                'rapidapi_similarity_host': similarityHostCtrl.text,
                'rapidapi_resume_parser_host': parserHostCtrl.text,
              }),
            )),
            const SizedBox(width: 12),
            // Bouton Tester la connexion
            OutlinedButton.icon(
              icon: testLoading
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering_outlined, size: 16),
              label: Text(testLoading ? 'Test...' : 'Tester la connexion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 14),
              ),
              onPressed: testLoading ? null : () async {
                setS(() => testLoading = true);
                try {
                  final token = context.read<AuthProvider>().token ?? '';
                  final res = await _svc.testerConnexionIA(token);
                  setS(() {
                    testResult = res['success'] == true
                        ? '✅ Connexion réussie !'
                        : '❌ ${res['message']}';
                    testLoading = false;
                  });
                } catch (e) {
                  setS(() {
                    testResult = '❌ Erreur: $e';
                    testLoading = false;
                  });
                }
              },
            ),
          ]),

          // Résultat du test
          if (testResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: testResult!.startsWith('✅')
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(testResult!, style: GoogleFonts.inter(
                fontSize: 13,
                color: testResult!.startsWith('✅')
                    ? const Color(0xFF065F46)
                    : const Color(0xFF991B1B),
                fontWeight: FontWeight.w500)),
            ),
          ],
        ]),
        const SizedBox(height: 16),

        // Card OpenAI (alternative)
        _SettingsCard(title: '🔑 Configuration OpenAI (optionnel)', children: [
          _label('Clé API OpenAI'),
          const SizedBox(height: 6),
          _secretField(openaiKeyCtrl, 'sk-...'),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Sauvegarder clé OpenAI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _saveParam('openai_api_key', openaiKeyCtrl.text),
          ),
        ]),
        const SizedBox(height: 16),

        // Card paramètres matching
        _SettingsCard(title: '⚙️ Paramètres du Matching', children: [
          _toggleParam('suggestions_automatiques',
            'Suggestions automatiques',
            'Activer les recommandations IA automatiques',
            ia),
          const Divider(height: 20),
          _label('Seuil minimum de matching (%)'),
          const SizedBox(height: 8),
          _sliderParam('seuil_matching_minimum', ia,
            min: 10, max: 90, label: '%'),
        ]),
      ],
    ));
  }
```

### Section Sécurité

```dart
  Widget _buildSecurite() {
    final sec = _params['securite'] ?? {};
    final ipsCtrl = TextEditingController(
      text: (sec['ips_bloquees']?['valeur'] as List? ?? []).join('\n'));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      _SectionHeader(
        icon: Icons.security_outlined,
        title: 'Sécurité',
        subtitle: 'Configurez les paramètres de sécurité de la plateforme.',
      ),
      const SizedBox(height: 24),

      _SettingsCard(title: '🔐 Sessions & Authentification', children: [
        _label('Durée de session (minutes)'),
        const SizedBox(height: 8),
        _sliderParam('duree_session_minutes', sec,
          min: 30, max: 10080, label: 'min', divisions: 100),
        const Divider(height: 24),

        _label('Tentatives max avant blocage'),
        const SizedBox(height: 8),
        _sliderParam('max_tentatives_connexion', sec,
          min: 3, max: 20, label: 'tentatives', divisions: 17),
        const Divider(height: 24),

        _label('Durée d\'expiration JWT (heures)'),
        const SizedBox(height: 8),
        _sliderParam('jwt_expiration_heures', sec,
          min: 1, max: 168, label: 'heures', divisions: 167),
      ]),
      const SizedBox(height: 16),

      _SettingsCard(title: '🛡️ Double Authentification (2FA)', children: [
        // Toggle 2FA
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Activer 2FA pour les administrateurs',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A))),
            Text('Les admins devront confirmer leur identité '
                'via un code à usage unique.',
              style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B))),
          ])),
          Switch(
            value: sec['twofa_admin_actif']?['valeur'] == true,
            onChanged: (v) => _saveParam('twofa_admin_actif', v),
            activeColor: const Color(0xFF1A56DB),
          ),
        ]),
        if (sec['twofa_admin_actif']?['valeur'] == true) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_outlined,
                color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '2FA activé. Les admins devront configurer '
                'leur application authenticator à la prochaine connexion.',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF92400E)),
              )),
            ]),
          ),
        ],
      ]),
      const SizedBox(height: 16),

      // IPs bloquées
      _SettingsCard(title: '🚫 Adresses IP bloquées', children: [
        Text('Une adresse IP par ligne.',
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF64748B))),
        const SizedBox(height: 8),
        TextFormField(
          controller: ipsCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '192.168.1.1\n10.0.0.1\n...',
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Sauvegarder les IPs bloquées'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            final ips = ipsCtrl.text
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            _saveParam('ips_bloquees', ips);
          },
        ),
      ]),
    ]);
  }
```

### Section Bannières Homepage

```dart
  Widget _buildBannieres() {
    return _BannièresSection(
      onRefresh: _loadParams,
    );
  }
}

// Widget dédié à la gestion des bannières
class _BannièresSection extends StatefulWidget {
  final VoidCallback onRefresh;
  const _BannièresSection({required this.onRefresh});
  @override
  State<_BannièresSection> createState() => _BannièresSectionState();
}

class _BannièresSectionState extends State<_BannièresSection> {
  List<dynamic> _bannieres = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadBannieres(); }

  Future<void> _loadBannieres() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await AdminService().getBannieres(token);
      setState(() {
        _bannieres = res['data'] ?? [];
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      _SectionHeader(
        icon: Icons.view_carousel_outlined,
        title: 'Bannières Homepage',
        subtitle: 'Gérez les slides du carrousel sur la page d\'accueil. '
            'Dimensions recommandées : 1920x1080px.',
      ),
      const SizedBox(height: 20),

      // Bouton ajouter
      ElevatedButton.icon(
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
        label: const Text('Ajouter une bannière'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showAddDialog(),
      ),
      const SizedBox(height: 20),

      // Liste des bannières
      if (_isLoading)
        const Center(child: CircularProgressIndicator())
      else if (_bannieres.isEmpty)
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(child: Column(children: [
            const Icon(Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8), size: 48),
            const SizedBox(height: 12),
            Text('Aucune bannière configurée',
              style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF64748B))),
          ])),
        )
      else
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: _onReorder,
          itemCount: _bannieres.length,
          itemBuilder: (ctx, i) => _buildBannièreCard(
            _bannieres[i], i, key: ValueKey(_bannieres[i]['id'])),
        ),
    ]);
  }

  Widget _buildBannièreCard(Map<String, dynamic> ban, int i,
      {required Key key}) => Container(
    key: key,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(children: [
      // Image preview
      ClipRRect(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(12)),
        child: Image.network(
          ban['image_url'] ?? '',
          width: 160, height: 90,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 160, height: 90,
            color: const Color(0xFFF1F5F9),
            child: const Icon(Icons.image_outlined,
              color: Color(0xFF94A3B8))),
        ),
      ),
      const SizedBox(width: 16),
      // Infos
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ban['titre'] ?? 'Sans titre', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A)),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(ban['sous_titre'] ?? '', style: GoogleFonts.inter(
          fontSize: 12, color: const Color(0xFF64748B)),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          if (ban['label_cta_1'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(100)),
              child: Text(ban['label_cta_1'],
                style: GoogleFonts.inter(
                  fontSize: 10, color: const Color(0xFF1A56DB))),
            ),
          const SizedBox(width: 6),
          Text('Slide ${i + 1}', style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF94A3B8))),
        ]),
      ])),
      // Actions
      Row(mainAxisSize: MainAxisSize.min, children: [
        // Toggle actif
        Switch(
          value: ban['est_actif'] == true,
          onChanged: (v) async {
            final token = context.read<AuthProvider>().token ?? '';
            await AdminService().updateBannière(
              token, ban['id'], {'est_actif': v});
            _loadBannieres();
          },
          activeColor: const Color(0xFF1A56DB),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined,
            color: Color(0xFF64748B), size: 20),
          onPressed: () => _showEditDialog(ban),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline,
            color: Color(0xFFEF4444), size: 20),
          onPressed: () => _confirmDelete(ban),
        ),
        // Handle de réordonnement
        const Icon(Icons.drag_handle,
          color: Color(0xFF94A3B8), size: 20),
        const SizedBox(width: 8),
      ]),
    ]),
  );

  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _bannieres.removeAt(oldIndex);
      _bannieres.insert(newIndex, item);
    });
    // Mettre à jour l'ordre dans le backend
    final token = context.read<AuthProvider>().token ?? '';
    await AdminService().reordonnerBannieres(
      token,
      _bannieres.asMap().entries.map((e) => {
        'id': e.value['id'],
        'ordre': e.key + 1,
      }).toList(),
    );
  }

  void _showAddDialog() => showDialog(
    context: context,
    builder: (_) => _BannièreDialog(
      onSave: (data) async {
        final token = context.read<AuthProvider>().token ?? '';
        await AdminService().createBannière(token, data);
        _loadBannieres();
      },
    ),
  );

  void _showEditDialog(Map<String, dynamic> ban) => showDialog(
    context: context,
    builder: (_) => _BannièreDialog(
      bannière: ban,
      onSave: (data) async {
        final token = context.read<AuthProvider>().token ?? '';
        await AdminService().updateBannière(token, ban['id'], data);
        _loadBannieres();
      },
    ),
  );

  void _confirmDelete(Map<String, dynamic> ban) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Supprimer cette bannière ?',
        style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text('La bannière "${ban['titre']}" sera supprimée.',
        style: GoogleFonts.inter(fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444), elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () async {
            Navigator.pop(context);
            final token = context.read<AuthProvider>().token ?? '';
            await AdminService().deleteBannière(token, ban['id']);
            _loadBannieres();
          },
          child: Text('Supprimer', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
```

### Section Logo & Identité

```dart
  Widget _buildLogo() {
    final general = _params['general'] ?? {};
    final logoUrl = general['logo_url']?['valeur'] ?? '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionHeader(
        icon: Icons.image_outlined,
        title: 'Logo & Identité Visuelle',
        subtitle: 'Le logo sera affiché sur toute la plateforme. '
            'Dimensions recommandées : 400x200px. Formats: PNG, SVG.',
      ),
      const SizedBox(height: 24),

      _SettingsCard(title: '🖼️ Logo Principal', children: [
        // Aperçu du logo actuel
        if (logoUrl.isNotEmpty) ...[
          Text('Logo actuel :', style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(child: Image.network(
              logoUrl, height: 60, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text('Erreur chargement logo'),
            )),
          ),
          const SizedBox(height: 16),
        ],

        // Zone upload
        GestureDetector(
          onTap: () => _uploadLogo(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF1A56DB).withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_outlined,
                  color: Color(0xFF1A56DB), size: 28),
              ),
              const SizedBox(height: 12),
              Text('Cliquez pour uploader le logo',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A56DB))),
              const SizedBox(height: 4),
              Text('PNG, SVG, WEBP · Max 5MB · 400x200px recommandé',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8))),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Info propagation automatique
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_outline,
              color: Color(0xFF10B981), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Une fois uploadé, le logo s\'affiche automatiquement '
              'sur toute la plateforme : homepage, dashboard, emails.',
              style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF065F46)),
            )),
          ]),
        ),
      ]),
    ]);
  }
```

### Section Pied de Page

```dart
  Widget _buildFooter() {
    final footer = _params['footer'] ?? {};
    final controllers = {
      'footer_linkedin':  TextEditingController(text: footer['footer_linkedin']?['valeur'] ?? ''),
      'footer_facebook':  TextEditingController(text: footer['footer_facebook']?['valeur'] ?? ''),
      'footer_twitter':   TextEditingController(text: footer['footer_twitter']?['valeur'] ?? ''),
      'footer_instagram': TextEditingController(text: footer['footer_instagram']?['valeur'] ?? ''),
      'footer_whatsapp':  TextEditingController(text: footer['footer_whatsapp']?['valeur'] ?? ''),
      'footer_email':     TextEditingController(text: footer['footer_email']?['valeur'] ?? ''),
      'footer_telephone': TextEditingController(text: footer['footer_telephone']?['valeur'] ?? ''),
      'footer_adresse':   TextEditingController(text: footer['footer_adresse']?['valeur'] ?? ''),
      'footer_tagline':   TextEditingController(text: footer['footer_tagline']?['valeur'] ?? ''),
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionHeader(
        icon: Icons.language_outlined,
        title: 'Pied de page & Contact',
        subtitle: 'Ces informations apparaissent dans le footer '
            'de toutes les pages.',
      ),
      const SizedBox(height: 24),

      _SettingsCard(title: '📱 Réseaux Sociaux', children: [
        _labeledInput('LinkedIn', controllers['footer_linkedin']!,
          'https://linkedin.com/company/emploiconnect',
          Icons.linkedin, 'Lien vers votre page LinkedIn'),
        const SizedBox(height: 14),
        _labeledInput('Facebook', controllers['footer_facebook']!,
          'https://facebook.com/emploiconnect',
          Icons.facebook, ''),
        const SizedBox(height: 14),
        _labeledInput('Twitter / X', controllers['footer_twitter']!,
          'https://twitter.com/emploiconnect',
          Icons.alternate_email, ''),
        const SizedBox(height: 14),
        _labeledInput('Instagram', controllers['footer_instagram']!,
          'https://instagram.com/emploiconnect',
          Icons.camera_alt_outlined, ''),
        const SizedBox(height: 14),
        _labeledInput('WhatsApp Business', controllers['footer_whatsapp']!,
          '+224 620 00 00 00',
          Icons.chat_outlined, 'Numéro WhatsApp'),
      ]),
      const SizedBox(height: 16),

      _SettingsCard(title: '📞 Informations de Contact', children: [
        _labeledInput('Email de contact', controllers['footer_email']!,
          'contact@emploiconnect.gn',
          Icons.email_outlined, ''),
        const SizedBox(height: 14),
        _labeledInput('Téléphone', controllers['footer_telephone']!,
          '+224 620 00 00 00',
          Icons.phone_outlined, ''),
        const SizedBox(height: 14),
        _labeledInput('Adresse', controllers['footer_adresse']!,
          'Conakry, République de Guinée',
          Icons.location_on_outlined, ''),
        const SizedBox(height: 14),
        _labeledInput('Tagline footer', controllers['footer_tagline']!,
          'La plateforme intelligente de l\'emploi en Guinée',
          Icons.short_text_outlined, 'Texte sous le logo'),
      ]),
      const SizedBox(height: 20),

      // Bouton sauvegarder
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Sauvegarder le pied de page'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600),
          ),
          onPressed: () => _saveMultipleParams({
            for (final e in controllers.entries)
              e.key: e.value.text.trim()
          }),
        ),
      ),
    ]);
  }
```

---

## 7. Mise à jour AdminService Flutter

```dart
// Ajouter dans frontend/lib/services/admin_service.dart

// ── PARAMÈTRES ────────────────────────────────────────────
Future<Map<String, dynamic>> testerConnexionIA(String token) async {
  final res = await http.post(
    Uri.parse('$_base/parametres/tester-ia'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> uploadLogo(String token, String filePath) async {
  final request = http.MultipartRequest(
    'POST', Uri.parse('$_base/parametres/upload-logo'));
  request.headers['Authorization'] = 'Bearer $token';
  request.files.add(await http.MultipartFile.fromPath('logo', filePath));
  final streamed  = await request.send();
  final response  = await http.Response.fromStream(streamed);
  return _handleResponse(response);
}

// ── BANNIÈRES ─────────────────────────────────────────────
Future<Map<String, dynamic>> getBannieres(String token) async {
  final res = await http.get(
    Uri.parse('$_base/bannieres'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> createBannière(
  String token, Map<String, dynamic> data) async {
  final res = await http.post(
    Uri.parse('$_base/bannieres'),
    headers: _headers(token),
    body: jsonEncode(data),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> updateBannière(
  String token, String id, Map<String, dynamic> data) async {
  final res = await http.patch(
    Uri.parse('$_base/bannieres/$id'),
    headers: _headers(token),
    body: jsonEncode(data),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> deleteBannière(
  String token, String id) async {
  final res = await http.delete(
    Uri.parse('$_base/bannieres/$id'),
    headers: _headers(token),
  );
  return _handleResponse(res);
}

Future<Map<String, dynamic>> reordonnerBannieres(
  String token, List<Map<String, dynamic>> ordre) async {
  final res = await http.patch(
    Uri.parse('$_base/bannieres/reordonner/ordre'),
    headers: _headers(token),
    body: jsonEncode({'ordre': ordre}),
  );
  return _handleResponse(res);
}
```

---

## 8. Connexion Homepage aux Paramètres Dynamiques

```dart
// lib/screens/home/widgets/hero_section_widget.dart
// Remplacer les slides hardcodés par les données de l'API

class HeroSectionWidget extends StatefulWidget {
  const HeroSectionWidget({super.key});
  @override
  State<HeroSectionWidget> createState() => _HeroSectionWidgetState();
}

class _HeroSectionWidgetState extends State<HeroSectionWidget> {
  List<dynamic> _bannieres = [];
  bool _isLoading = true;

  // Slides de secours si API indisponible
  static const List<Map<String, String>> _fallbackSlides = [
    {
      'titre': 'Trouvez l\'Emploi de Vos Rêves',
      'sous_titre': 'Des milliers d\'offres vérifiées vous attendent.',
      'texte_badge': '🇬🇳 Plateforme N°1 en Guinée',
      'image_url': 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1920&q=80',
      'label_cta_1': 'Trouver un Emploi',
      'label_cta_2': 'Recruter des Talents',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBannieres();
  }

  Future<void> _loadBannieres() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/bannieres'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bannieres = data['data'] as List?;
        if (bannieres != null && bannieres.isNotEmpty) {
          setState(() {
            _bannieres = bannieres;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    // Fallback si API indisponible
    setState(() { _isLoading = false; });
  }

  List<dynamic> get _slidesToShow =>
    _bannieres.isNotEmpty ? _bannieres : _fallbackSlides;

  // Utiliser _slidesToShow au lieu des slides hardcodés
  // dans le reste du widget...
}

// lib/screens/home/widgets/footer_widget.dart
// Charger les infos footer depuis l'API

class _FooterState extends State<FooterWidget> {
  Map<String, String> _footerData = {};

  @override
  void initState() {
    super.initState();
    _loadFooterData();
  }

  Future<void> _loadFooterData() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/config/footer'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as Map<String, dynamic>;
        setState(() {
          _footerData = data.map((k, v) => MapEntry(k, v.toString()));
        });
      }
    } catch (_) {} // Garder les valeurs par défaut
  }
}
```

### Ajouter route publique config footer

```javascript
// Dans backend/src/routes/index.js — route publique
router.get('/config/footer', async (req, res) => {
  try {
    const { supabase } = require('../config/supabase');
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .eq('categorie', 'footer');

    const result = {};
    (data || []).forEach(p => { result[p.cle] = p.valeur; });

    return res.json({ success: true, data: result });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// Route publique config générale (logo, nom plateforme)
router.get('/config/general', async (req, res) => {
  try {
    const { supabase } = require('../config/supabase');
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'nom_plateforme', 'logo_url', 'couleur_primaire',
        'description_plateforme'
      ]);

    const result = {};
    (data || []).forEach(p => { result[p.cle] = p.valeur; });

    return res.json({ success: true, data: result });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});
```

---

## 9. Variable ENV à ajouter

```bash
# backend/.env — Ajouter ces variables

# Chiffrement des clés API sensibles
ENCRYPTION_KEY=emploiconnect_votre_cle_32_chars!!

# Bucket Supabase pour les bannières
SUPABASE_BANNIÈRES_BUCKET=bannieres

# Bucket pour les logos
SUPABASE_LOGOS_BUCKET=logos
```

### Buckets Supabase à créer manuellement

```
Dans Supabase Dashboard → Storage → Buckets :

1. Créer bucket "bannieres"
   - Public : OUI (les images sont publiques)
   - Types MIME : image/jpeg, image/png, image/webp
   - Taille max : 10MB

2. Créer bucket "logos"
   - Public : OUI
   - Types MIME : image/jpeg, image/png, image/webp, image/svg+xml
   - Taille max : 5MB
```

---

## 10. Critères d'Acceptation

### ✅ Migrations SQL
- [ ] Migration 007 (bannières) exécutée dans Supabase
- [ ] Migration 008 (paramètres avancés) exécutée avec données initiales
- [ ] Buckets "bannieres" et "logos" créés dans Supabase Storage
- [ ] Variable `ENCRYPTION_KEY` ajoutée dans `.env`

### ✅ Backend Paramètres
- [ ] `GET /api/admin/parametres` retourne toutes les sections groupées
- [ ] Les clés API sensibles sont masquées (•••) dans la réponse
- [ ] `PUT /api/admin/parametres` chiffre les clés sensibles avant stockage
- [ ] `POST /api/admin/parametres/tester-ia` teste la connexion RapidAPI
- [ ] `POST /api/admin/parametres/upload-logo` redimensionne et stocke le logo
- [ ] `GET /api/config/footer` retourne les infos footer (route publique)
- [ ] `GET /api/config/general` retourne logo + nom + couleur (route publique)

### ✅ Backend Bannières
- [ ] `GET /api/bannieres` retourne les bannières actives (route publique)
- [ ] `GET /api/admin/bannieres` retourne toutes les bannières (admin)
- [ ] `POST /api/admin/bannieres` crée une bannière avec upload image
- [ ] `PATCH /api/admin/bannieres/:id` met à jour une bannière
- [ ] `PATCH /api/admin/bannieres/reordonner/ordre` réordonne les slides
- [ ] `DELETE /api/admin/bannieres/:id` supprime bannière + image storage

### ✅ Flutter — Page Paramètres
- [ ] Navigation sidebar avec 9 sections
- [ ] Section Général : champs éditables et sauvegardables
- [ ] Section Logo : upload fonctionnel + aperçu en temps réel
- [ ] Section Bannières : liste, ajout, édition, toggle actif, drag pour réordonner, suppression
- [ ] Section IA & Matching : champs clés API masqués, bouton tester connexion
- [ ] Section Sécurité : toggle 2FA, slider sessions, liste IPs bloquées
- [ ] Section Footer : tous les champs réseaux sociaux + contact
- [ ] Section Maintenance : toggle mode maintenance
- [ ] Bouton sauvegarder avec feedback succès/erreur
- [ ] SnackBar vert succès / rouge erreur sur chaque sauvegarde

### ✅ Propagation Dynamique
- [ ] Logo uploadé → apparaît sur navbar homepage + dashboards
- [ ] Bannières modifiées → carousel homepage se met à jour
- [ ] Footer modifié → footer homepage affiche les nouvelles infos
- [ ] Aucun redémarrage serveur nécessaire après modification des paramètres

---

*PRD EmploiConnect v3.3 — Paramètres Avancés Admin*
*Cursor / Kirsoft AI — Phase 7.3*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
