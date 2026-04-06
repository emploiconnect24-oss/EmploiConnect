# PRD — EmploiConnect · Backend Complet — Module Recruteur/Entreprise
## Product Requirements Document v5.0 — Backend Recruteur
**Stack : Node.js + Express · PostgreSQL/Supabase · JWT · Flutter**
**Outil : Cursor / Kirsoft AI**
**Module : Backend Recruteur/Entreprise — API complètes**
**Statut : Phase 9 — Suite Backend Admin validé**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> 1. Backend Admin ✅ · Frontend Recruteur ✅ — NE PAS TOUCHER
> 2. Ce PRD implémente TOUT le backend pour le rôle `entreprise`
> 3. Toutes les routes sous `/api/recruteur/` sauf quelques routes
>    partagées sous `/api/offres/` et `/api/candidatures/`
> 4. Middleware `requireRecruteur` à créer (comme `requireAdmin`)
> 5. Cohérence totale avec le frontend PRD_RECRUTEUR.md déjà validé
> 6. Intégration IA (scores matching) sur les candidatures
> 7. Implémenter dans l'ordre exact des sections

---

## Table des Matières

1. [État des Lieux — Routes existantes](#1-état-des-lieux--routes-existantes)
2. [Nouvelles Migrations SQL](#2-nouvelles-migrations-sql)
3. [Middleware Recruteur](#3-middleware-recruteur)
4. [Routes Recruteur — Dashboard & Stats](#4-routes-recruteur--dashboard--stats)
5. [Routes Recruteur — Gestion Offres](#5-routes-recruteur--gestion-offres)
6. [Routes Recruteur — Gestion Candidatures](#6-routes-recruteur--gestion-candidatures)
7. [Routes Recruteur — Profil Entreprise](#7-routes-recruteur--profil-entreprise)
8. [Routes Recruteur — Messagerie](#8-routes-recruteur--messagerie)
9. [Routes Recruteur — Notifications](#9-routes-recruteur--notifications)
10. [Routes Recruteur — Recherche Talents IA](#10-routes-recruteur--recherche-talents-ia)
11. [Routes Recruteur — Statistiques](#11-routes-recruteur--statistiques)
12. [Mise à jour des routes partagées](#12-mise-à-jour-des-routes-partagées)
13. [Flutter — RecruteurService complet](#13-flutter--recruteurservice-complet)
14. [Tests des endpoints](#14-tests-des-endpoints)
15. [Critères d'Acceptation](#15-critères-dacceptation)

---

## 1. État des Lieux — Routes existantes

### Routes déjà en place (à conserver)
```
✅ POST /api/auth/register     → Inscription entreprise
✅ POST /api/auth/login        → Connexion
✅ GET  /api/offres            → Liste offres publiques
✅ GET  /api/offres/:id        → Détail offre
✅ POST /api/offres            → Créer une offre (entreprise)
✅ PATCH /api/offres/:id       → Modifier une offre
✅ DELETE /api/offres/:id      → Supprimer une offre
✅ GET  /api/candidatures      → Liste candidatures (selon rôle)
✅ GET  /api/candidatures/:id  → Détail candidature
✅ PATCH /api/candidatures/:id → Modifier statut candidature
✅ GET  /api/users/me          → Profil connecté
✅ PATCH /api/users/me         → Mise à jour profil
```

### Ce qui manque — À créer
```
❌ GET  /api/recruteur/dashboard      → Données dashboard recruteur
❌ GET  /api/recruteur/stats          → Statistiques recruteur
❌ GET  /api/recruteur/offres         → Mes offres avec stats complètes
❌ POST /api/recruteur/offres         → Créer offre (version complète)
❌ PATCH /api/recruteur/offres/:id    → Modifier offre
❌ POST /api/recruteur/offres/:id/dupliquer → Dupliquer une offre
❌ PATCH /api/recruteur/offres/:id/cloturer → Clôturer une offre
❌ GET  /api/recruteur/candidatures   → Vue kanban/liste candidatures
❌ PATCH /api/recruteur/candidatures/:id → Actions recruteur sur candidature
❌ GET  /api/recruteur/profil         → Profil entreprise complet
❌ PATCH /api/recruteur/profil        → Mettre à jour profil entreprise
❌ POST /api/recruteur/profil/logo    → Upload logo entreprise
❌ GET  /api/recruteur/messages       → Conversations messagerie
❌ POST /api/recruteur/messages       → Envoyer un message
❌ GET  /api/recruteur/messages/:id   → Messages d'une conversation
❌ GET  /api/recruteur/notifications  → Notifications recruteur
❌ GET  /api/recruteur/talents        → Recherche talents avec IA
❌ POST /api/recruteur/talents/contacter → Contacter un talent
```

---

## 2. Nouvelles Migrations SQL

### `database/migrations/010_add_messages.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 010 : Table messages (messagerie interne)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  -- Identifiant de conversation = hash(expediteur_id + destinataire_id)
  -- Pour grouper les messages entre 2 personnes

  expediteur_id   UUID NOT NULL REFERENCES utilisateurs(id)
    ON DELETE CASCADE,
  destinataire_id UUID NOT NULL REFERENCES utilisateurs(id)
    ON DELETE CASCADE,

  contenu         TEXT NOT NULL,
  est_lu          BOOLEAN DEFAULT FALSE,

  -- Lien optionnel vers une offre (contexte du message)
  offre_id        UUID REFERENCES offres_emploi(id)
    ON DELETE SET NULL,

  -- Lien optionnel vers une candidature
  candidature_id  UUID REFERENCES candidatures(id)
    ON DELETE SET NULL,

  date_envoi      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  date_lecture    TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation
  ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_expediteur
  ON messages(expediteur_id);
CREATE INDEX IF NOT EXISTS idx_messages_destinataire
  ON messages(destinataire_id);
CREATE INDEX IF NOT EXISTS idx_messages_non_lus
  ON messages(est_lu, destinataire_id);

-- Vue conversations (derniers messages par paire d'utilisateurs)
CREATE OR REPLACE VIEW v_conversations AS
SELECT DISTINCT ON (conversation_id)
  conversation_id,
  expediteur_id,
  destinataire_id,
  contenu AS dernier_message,
  date_envoi AS date_dernier_message,
  est_lu,
  offre_id
FROM messages
ORDER BY conversation_id, date_envoi DESC;
```

### `database/migrations/011_add_offres_vues.sql`
```sql
-- ═══════════════════════════════════════════════════════════
-- MIGRATION 011 : Compteur de vues des offres
-- ═══════════════════════════════════════════════════════════

-- Ajouter colonne vues si pas déjà présente
ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS nb_vues INTEGER DEFAULT 0;

-- Table pour stocker les vues uniques (éviter les doublons)
CREATE TABLE IF NOT EXISTS offres_vues (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offre_id   UUID NOT NULL REFERENCES offres_emploi(id)
    ON DELETE CASCADE,
  user_id    UUID REFERENCES utilisateurs(id) ON DELETE SET NULL,
  ip_address VARCHAR(45),
  date_vue   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_offres_vues_offre
  ON offres_vues(offre_id);
CREATE INDEX IF NOT EXISTS idx_offres_vues_date
  ON offres_vues(date_vue DESC);

-- Ajouter colonne offre sauvegardées
CREATE TABLE IF NOT EXISTS offres_sauvegardees (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id)
    ON DELETE CASCADE,
  offre_id     UUID NOT NULL REFERENCES offres_emploi(id)
    ON DELETE CASCADE,
  date_sauvegarde TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(chercheur_id, offre_id)
);

CREATE INDEX IF NOT EXISTS idx_offres_sauv_chercheur
  ON offres_sauvegardees(chercheur_id);
```

---

## 3. Middleware Recruteur

### `backend/src/middleware/recruteurAuth.js`
```javascript
// Middleware vérification rôle recruteur/entreprise
// S'utilise APRÈS le middleware auth.js

const { supabase } = require('../config/supabase');

const requireRecruteur = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentification requise'
      });
    }

    if (req.user.role !== 'entreprise') {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Compte entreprise requis.'
      });
    }

    // Récupérer l'entreprise liée à cet utilisateur
    const { data: entreprise, error } = await supabase
      .from('entreprises')
      .select('id, nom_entreprise, logo_url')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (error || !entreprise) {
      return res.status(403).json({
        success: false,
        message: 'Profil entreprise non trouvé. '
          + 'Complétez votre inscription.'
      });
    }

    // Attacher les infos entreprise à la requête
    req.entreprise = entreprise;
    next();

  } catch (err) {
    console.error('[requireRecruteur]', err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la vérification'
    });
  }
};

module.exports = { requireRecruteur };
```

---

## 4. Routes Recruteur — Dashboard & Stats

### `backend/src/routes/recruteur/dashboard.routes.js`
```javascript
const express = require('express');
const router  = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');

router.use(auth, requireRecruteur);

// ══════════════════════════════════════════════════════════════
// GET /api/recruteur/dashboard
// Données complètes du dashboard recruteur
// ══════════════════════════════════════════════════════════════
router.get('/', async (req, res) => {
  try {
    const entrepriseId = req.entreprise.id;

    // Requêtes en parallèle
    const [offresRes, candidaturesRes, messagesRes] = await Promise.all([

      // Offres actives
      supabase.from('offres_emploi')
        .select('id, titre, statut, nb_vues, date_publication')
        .eq('entreprise_id', entrepriseId)
        .eq('statut', 'publiee')
        .order('date_publication', { ascending: false }),

      // Candidatures récentes (30 derniers jours)
      supabase.from('candidatures')
        .select(`
          id, statut, score_compatibilite,
          date_candidature,
          chercheur:chercheur_id (
            utilisateur:utilisateur_id (
              nom, email, photo_url
            )
          ),
          offre:offre_id (id, titre)
        `)
        .in('offre_id',
          supabase.from('offres_emploi')
            .select('id')
            .eq('entreprise_id', entrepriseId)
        )
        .order('date_candidature', { ascending: false })
        .limit(10),

      // Messages non lus
      supabase.from('messages')
        .select('id', { count: 'exact' })
        .eq('destinataire_id', req.user.id)
        .eq('est_lu', false),
    ]);

    const offres       = offresRes.data || [];
    const candidatures = candidaturesRes.data || [];
    const nbMessagesNonLus = messagesRes.count || 0;

    // Stats globales
    const { data: toutesOffres } = await supabase
      .from('offres_emploi')
      .select('id, statut')
      .eq('entreprise_id', entrepriseId);

    const { data: toutesCandidatures } = await supabase
      .from('candidatures')
      .select('id, statut')
      .in('offre_id',
        (toutesOffres || []).map(o => o.id));

    // Taux de réponse (candidatures traitées / total)
    const nbTraitees = (toutesCandidatures || []).filter(c =>
      ['acceptee', 'refusee', 'entretien'].includes(c.statut)
    ).length;
    const tauxReponse = toutesCandidatures?.length > 0
      ? Math.round(nbTraitees / toutesCandidatures.length * 100)
      : 0;

    // Vues totales ce mois
    const dateDebut30j = new Date(
      Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const { count: vuesMois } = await supabase
      .from('offres_vues')
      .select('id', { count: 'exact' })
      .in('offre_id', (toutesOffres || []).map(o => o.id))
      .gte('date_vue', dateDebut30j);

    const stats = {
      offres_actives:      offres.length,
      total_candidatures:  toutesCandidatures?.length || 0,
      candidatures_en_attente: (toutesCandidatures || [])
        .filter(c => c.statut === 'en_attente').length,
      vues_ce_mois:        vuesMois || 0,
      taux_reponse:        tauxReponse,
      messages_non_lus:    nbMessagesNonLus,
    };

    // Candidatures urgentes (en attente depuis > 7 jours)
    const seuilUrgence = new Date(
      Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const candidaturesUrgentes = candidatures.filter(c =>
      c.statut === 'en_attente' &&
      c.date_candidature < seuilUrgence
    );

    return res.json({
      success: true,
      data: {
        stats,
        offres_actives:          offres.slice(0, 5),
        candidatures_recentes:   candidatures.slice(0, 5),
        candidatures_urgentes:   candidaturesUrgentes.slice(0, 3),
        entreprise: {
          nom:     req.entreprise.nom_entreprise,
          logo:    req.entreprise.logo_url,
        },
      }
    });

  } catch (err) {
    console.error('[recruteur/dashboard]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;
```

---

## 5. Routes Recruteur — Gestion Offres

### `backend/src/routes/recruteur/offres.routes.js`
```javascript
const express = require('express');
const router  = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');
const { extraireMotsCles } = require('../../services/ia.service');
const { notifNouvelleOffre } =
  require('../../services/auto_notification.service');

router.use(auth, requireRecruteur);

// ══════════════════════════════════════════════════════════════
// GET /api/recruteur/offres
// Mes offres avec stats complètes
// ══════════════════════════════════════════════════════════════
router.get('/', async (req, res) => {
  try {
    const {
      page = 1, limite = 20,
      statut, recherche,
      ordre = 'date_creation', direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('offres_emploi')
      .select('*', { count: 'exact' })
      .eq('entreprise_id', req.entreprise.id)
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (statut)   query = query.eq('statut', statut);
    if (recherche) query = query.ilike('titre', `%${recherche}%`);

    const { data: offres, count, error } = await query;
    if (error) throw error;

    // Ajouter stats candidatures pour chaque offre
    const offresIds = (offres || []).map(o => o.id);
    let candidaturesCount = {};
    let nonLuesCount = {};

    if (offresIds.length > 0) {
      const { data: cands } = await supabase
        .from('candidatures')
        .select('offre_id, statut')
        .in('offre_id', offresIds);

      (cands || []).forEach(c => {
        candidaturesCount[c.offre_id] =
          (candidaturesCount[c.offre_id] || 0) + 1;
        if (c.statut === 'en_attente') {
          nonLuesCount[c.offre_id] =
            (nonLuesCount[c.offre_id] || 0) + 1;
        }
      });
    }

    // Stats globales par statut
    const { data: tousStatuts } = await supabase
      .from('offres_emploi')
      .select('statut')
      .eq('entreprise_id', req.entreprise.id);

    const statsStatuts = {
      total:        count || 0,
      publiees:     tousStatuts?.filter(o => o.statut === 'publiee').length || 0,
      en_attente:   tousStatuts?.filter(o => o.statut === 'en_attente').length || 0,
      refusees:     tousStatuts?.filter(o => o.statut === 'refusee').length || 0,
      expirees:     tousStatuts?.filter(o => o.statut === 'expiree').length || 0,
      brouillons:   tousStatuts?.filter(o => o.statut === 'brouillon').length || 0,
    };

    const offresAvecStats = (offres || []).map(o => ({
      ...o,
      nb_candidatures: candidaturesCount[o.id] || 0,
      nb_non_lues:     nonLuesCount[o.id] || 0,
    }));

    return res.json({
      success: true,
      data: {
        offres: offresAvecStats,
        stats:  statsStatuts,
        pagination: {
          total: count || 0,
          page:  parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });

  } catch (err) {
    console.error('[recruteur/offres GET]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ══════════════════════════════════════════════════════════════
// POST /api/recruteur/offres
// Créer une nouvelle offre (soumise pour validation admin)
// ══════════════════════════════════════════════════════════════
router.post('/', async (req, res) => {
  try {
    const {
      titre, description, exigences,
      competences_requises, localisation,
      type_contrat, niveau_experience_requis,
      domaine, salaire_min, salaire_max, devise,
      nombre_postes, date_limite,
      mode_travail,
      publier_maintenant = true, // true = soumettre, false = brouillon
    } = req.body;

    // Validations
    if (!titre || !description || !localisation || !type_contrat) {
      return res.status(400).json({
        success: false,
        message: 'Titre, description, localisation et type_contrat sont requis'
      });
    }

    // Vérifier la limite d'offres gratuites
    const { data: paramLimite } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'max_offres_gratuit')
      .single();

    const limite = parseInt(paramLimite?.valeur || '5');

    const { count: nbOffresActives } = await supabase
      .from('offres_emploi')
      .select('id', { count: 'exact' })
      .eq('entreprise_id', req.entreprise.id)
      .eq('statut', 'publiee');

    if (publier_maintenant && nbOffresActives >= limite) {
      return res.status(403).json({
        success: false,
        message: `Limite atteinte. Votre plan permet ${limite} offres actives simultanément.`,
        code: 'LIMITE_OFFRES'
      });
    }

    // Calculer la date limite par défaut
    const { data: paramDuree } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'duree_validite_offre_jours')
      .single();

    const dureeJours = parseInt(paramDuree?.valeur || '30');
    const dateLimiteDefaut = new Date();
    dateLimiteDefaut.setDate(dateLimiteDefaut.getDate() + dureeJours);

    const statut = publier_maintenant ? 'en_attente' : 'brouillon';
    // 'en_attente' = soumise, attend validation admin
    // 'brouillon' = non soumise, visible seulement par le recruteur

    const { data: nouvelleOffre, error } = await supabase
      .from('offres_emploi')
      .insert({
        entreprise_id:            req.entreprise.id,
        titre,
        description,
        exigences:                exigences || '',
        competences_requises:     competences_requises || [],
        localisation,
        type_contrat,
        niveau_experience_requis: niveau_experience_requis || 'sans_experience',
        domaine:                  domaine || 'Autre',
        salaire_min:              salaire_min || null,
        salaire_max:              salaire_max || null,
        devise:                   devise || 'GNF',
        nombre_postes:            nombre_postes || 1,
        date_limite:              date_limite || dateLimiteDefaut.toISOString(),
        statut,
        date_creation:            new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;

    // Enrichissement IA en arrière-plan
    if (statut === 'en_attente') {
      setImmediate(async () => {
        try {
          const texteOffre = [titre, description, exigences].join(' ');
          const motsCles = await extraireMotsCles(texteOffre);

          if (motsCles.length > 0) {
            const compsExistantes = Array.isArray(competences_requises)
              ? competences_requises : [];
            const compsEnrichies = [
              ...new Set([...compsExistantes, ...motsCles])
            ].slice(0, 20);

            await supabase
              .from('offres_emploi')
              .update({ competences_requises: compsEnrichies })
              .eq('id', nouvelleOffre.id);
          }
        } catch (e) {
          console.warn('[offre/IA] Enrichissement non bloquant:', e.message);
        }

        // Notifier les admins
        try {
          await notifNouvelleOffre(nouvelleOffre, req.entreprise.nom_entreprise);
        } catch (e) {
          console.warn('[offre/notif] Non bloquant:', e.message);
        }
      });
    }

    return res.status(201).json({
      success: true,
      message: publier_maintenant
        ? 'Offre soumise pour validation. L\'admin va la vérifier.'
        : 'Brouillon sauvegardé.',
      data: nouvelleOffre
    });

  } catch (err) {
    console.error('[recruteur/offres POST]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ══════════════════════════════════════════════════════════════
// PATCH /api/recruteur/offres/:id
// Modifier une offre (seulement ses propres offres)
// ══════════════════════════════════════════════════════════════
router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Vérifier que l'offre appartient à cette entreprise
    const { data: offreActuelle } = await supabase
      .from('offres_emploi')
      .select('id, statut, entreprise_id')
      .eq('id', id)
      .single();

    if (!offreActuelle) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    if (offreActuelle.entreprise_id !== req.entreprise.id) {
      return res.status(403).json({
        success: false,
        message: 'Vous ne pouvez modifier que vos propres offres'
      });
    }

    const updateData = {
      ...req.body,
      date_modification: new Date().toISOString(),
    };

    // Supprimer les champs non modifiables
    delete updateData.entreprise_id;
    delete updateData.statut;      // Statut géré par actions séparées
    delete updateData.valide_par;
    delete updateData.en_vedette;

    const { data, error } = await supabase
      .from('offres_emploi')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: 'Offre mise à jour avec succès',
      data
    });

  } catch (err) {
    console.error('[recruteur/offres PATCH]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ══════════════════════════════════════════════════════════════
// POST /api/recruteur/offres/:id/dupliquer
// Dupliquer une offre existante
// ══════════════════════════════════════════════════════════════
router.post('/:id/dupliquer', async (req, res) => {
  try {
    const { data: offreSource } = await supabase
      .from('offres_emploi')
      .select('*')
      .eq('id', req.params.id)
      .eq('entreprise_id', req.entreprise.id)
      .single();

    if (!offreSource) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    // Calculer nouvelle date limite
    const dateLimite = new Date();
    dateLimite.setDate(dateLimite.getDate() + 30);

    const { data: copie, error } = await supabase
      .from('offres_emploi')
      .insert({
        entreprise_id:            offreSource.entreprise_id,
        titre:                    `${offreSource.titre} (copie)`,
        description:              offreSource.description,
        exigences:                offreSource.exigences,
        competences_requises:     offreSource.competences_requises,
        localisation:             offreSource.localisation,
        type_contrat:             offreSource.type_contrat,
        niveau_experience_requis: offreSource.niveau_experience_requis,
        domaine:                  offreSource.domaine,
        salaire_min:              offreSource.salaire_min,
        salaire_max:              offreSource.salaire_max,
        devise:                   offreSource.devise,
        nombre_postes:            offreSource.nombre_postes,
        date_limite:              dateLimite.toISOString(),
        statut:                   'brouillon', // La copie est un brouillon
        date_creation:            new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      success: true,
      message: 'Offre dupliquée en brouillon. Modifiez-la avant de la soumettre.',
      data: copie
    });

  } catch (err) {
    console.error('[recruteur/offres/dupliquer]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ══════════════════════════════════════════════════════════════
// PATCH /api/recruteur/offres/:id/cloturer
// Clôturer une offre avant son expiration
// ══════════════════════════════════════════════════════════════
router.patch('/:id/cloturer', async (req, res) => {
  try {
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('id, titre, entreprise_id')
      .eq('id', req.params.id)
      .eq('entreprise_id', req.entreprise.id)
      .single();

    if (!offre) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    await supabase
      .from('offres_emploi')
      .update({
        statut:            'expiree',
        date_modification: new Date().toISOString(),
      })
      .eq('id', req.params.id);

    return res.json({
      success: true,
      message: `Offre "${offre.titre}" clôturée avec succès`
    });

  } catch (err) {
    console.error('[recruteur/offres/cloturer]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// DELETE /api/recruteur/offres/:id
router.delete('/:id', async (req, res) => {
  try {
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('id, titre, entreprise_id')
      .eq('id', req.params.id)
      .eq('entreprise_id', req.entreprise.id)
      .single();

    if (!offre) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    await supabase.from('offres_emploi')
      .delete().eq('id', req.params.id);

    return res.json({
      success: true,
      message: `Offre "${offre.titre}" supprimée`
    });

  } catch (err) {
    console.error('[recruteur/offres DELETE]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;
```

---

## 6. Routes Recruteur — Gestion Candidatures

### `backend/src/routes/recruteur/candidatures.routes.js`
```javascript
const express = require('express');
const router  = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');

router.use(auth, requireRecruteur);

// ══════════════════════════════════════════════════════════════
// GET /api/recruteur/candidatures
// Toutes les candidatures reçues (avec filtres et kanban)
// ══════════════════════════════════════════════════════════════
router.get('/', async (req, res) => {
  try {
    const {
      offre_id,
      statut,
      recherche,
      page = 1, limite = 50,
      vue = 'liste', // 'liste' | 'kanban'
      ordre = 'date_candidature', direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    // Récupérer les IDs des offres de cette entreprise
    const { data: mesOffres } = await supabase
      .from('offres_emploi')
      .select('id')
      .eq('entreprise_id', req.entreprise.id);

    const mesOffresIds = (mesOffres || []).map(o => o.id);

    if (mesOffresIds.length === 0) {
      return res.json({
        success: true,
        data: { candidatures: [], stats: _statsVides(), kanban: null }
      });
    }

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite, date_candidature,
        date_modification, lettre_motivation,
        chercheur:chercheur_id (
          id,
          utilisateur:utilisateur_id (
            id, nom, email, photo_url, telephone
          ),
          competences, niveau_etude, disponibilite
        ),
        offre:offre_id (
          id, titre, localisation, type_contrat
        ),
        cv:cv_id (
          id, fichier_url, nom_fichier,
          competences_extrait
        )
      `, { count: 'exact' })
      .in('offre_id', mesOffresIds)
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (offre_id) query = query.eq('offre_id', offre_id);
    if (statut)   query = query.eq('statut', statut);

    const { data, count, error } = await query;
    if (error) throw error;

    // Filtrer par recherche sur le nom du candidat
    let candidatures = data || [];
    if (recherche) {
      candidatures = candidatures.filter(c =>
        c.chercheur?.utilisateur?.nom?.toLowerCase()
          .includes(recherche.toLowerCase()) ||
        c.chercheur?.utilisateur?.email?.toLowerCase()
          .includes(recherche.toLowerCase())
      );
    }

    // Stats globales
    const { data: tousStatuts } = await supabase
      .from('candidatures')
      .select('statut')
      .in('offre_id', mesOffresIds);

    const stats = {
      total:       tousStatuts?.length || 0,
      en_attente:  tousStatuts?.filter(c => c.statut === 'en_attente').length || 0,
      en_cours:    tousStatuts?.filter(c => c.statut === 'en_cours').length || 0,
      entretien:   tousStatuts?.filter(c => c.statut === 'entretien').length || 0,
      acceptees:   tousStatuts?.filter(c => c.statut === 'acceptee').length || 0,
      refusees:    tousStatuts?.filter(c => c.statut === 'refusee').length || 0,
    };

    // Format kanban si demandé
    let kanban = null;
    if (vue === 'kanban') {
      kanban = {
        en_attente: candidatures.filter(c => c.statut === 'en_attente'),
        en_cours:   candidatures.filter(c => c.statut === 'en_cours'),
        entretien:  candidatures.filter(c => c.statut === 'entretien'),
        acceptees:  candidatures.filter(c => c.statut === 'acceptee'),
        refusees:   candidatures.filter(c => c.statut === 'refusee'),
      };
    }

    return res.json({
      success: true,
      data: {
        candidatures,
        stats,
        kanban,
        pagination: {
          total: count || 0,
          page:  parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });

  } catch (err) {
    console.error('[recruteur/candidatures GET]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ══════════════════════════════════════════════════════════════
// GET /api/recruteur/candidatures/:id
// Détail d'une candidature avec profil complet du candidat
// ══════════════════════════════════════════════════════════════
router.get('/:id', async (req, res) => {
  try {
    const { data: candidature, error } = await supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite,
        date_candidature, date_modification,
        lettre_motivation,
        chercheur:chercheur_id (
          id, competences, niveau_etude, disponibilite,
          date_naissance, genre,
          utilisateur:utilisateur_id (
            id, nom, email, photo_url, telephone, adresse
          )
        ),
        offre:offre_id (
          id, titre, localisation, type_contrat,
          competences_requises, niveau_experience_requis
        ),
        cv:cv_id (
          id, fichier_url, nom_fichier, taille_fichier,
          competences_extrait, niveau_experience,
          date_upload
        )
      `)
      .eq('id', req.params.id)
      .single();

    if (error || !candidature) {
      return res.status(404).json({
        success: false, message: 'Candidature non trouvée'
      });
    }

    // Vérifier que cette candidature est pour une de ses offres
    const { data: offreCheck } = await supabase
      .from('offres_emploi')
      .select('id')
      .eq('id', candidature.offre.id)
      .eq('entreprise_id', req.entreprise.id)
      .single();

    if (!offreCheck) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé à cette candidature'
      });
    }

    // URL signée pour le CV (valable 1 heure)
    let cvSignedUrl = null;
    if (candidature.cv?.fichier_url) {
      try {
        const bucket = process.env.SUPABASE_STORAGE_BUCKET || 'cv-files';
        const path   = candidature.cv.fichier_url
          .split(`/${bucket}/`)[1];
        if (path) {
          const { data: signed } = await supabase.storage
            .from(bucket)
            .createSignedUrl(path, 3600);
          cvSignedUrl = signed?.signedUrl;
        }
      } catch (e) {
        console.warn('[candidature/cv] URL signée échouée:', e.message);
      }
    }

    return res.json({
      success: true,
      data: {
        ...candidature,
        cv: candidature.cv
          ? { ...candidature.cv, signed_url: cvSignedUrl }
          : null,
      }
    });

  } catch (err) {
    console.error('[recruteur/candidatures/:id]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ══════════════════════════════════════════════════════════════
// PATCH /api/recruteur/candidatures/:id
// Actions sur une candidature :
// changer statut, ajouter notes, planifier entretien
// ══════════════════════════════════════════════════════════════
router.patch('/:id', async (req, res) => {
  try {
    const { action, note, date_entretien, lien_visio, raison_refus } = req.body;

    // Vérifier accès
    const { data: candidature } = await supabase
      .from('candidatures')
      .select(`
        id, statut, chercheur_id,
        offre:offre_id (
          titre,
          entreprise_id,
          chercheur:chercheur_id (
            utilisateur_id
          )
        )
      `)
      .eq('id', req.params.id)
      .single();

    if (!candidature ||
        candidature.offre?.entreprise_id !== req.entreprise.id) {
      return res.status(404).json({
        success: false, message: 'Candidature non trouvée'
      });
    }

    let updateData = {
      date_modification: new Date().toISOString()
    };
    let messageReponse = '';
    let notifTitre = '';
    let notifMessage = '';

    switch (action) {
      case 'mettre_en_examen':
        updateData.statut = 'en_cours';
        messageReponse = 'Candidature mise en examen';
        notifTitre   = 'Votre candidature est en cours d\'examen';
        notifMessage = `${req.entreprise.nom_entreprise} examine votre candidature pour "${candidature.offre?.titre}"`;
        break;

      case 'planifier_entretien':
        if (!date_entretien) {
          return res.status(400).json({
            success: false, message: 'date_entretien requis'
          });
        }
        updateData.statut = 'entretien';
        messageReponse = 'Entretien planifié';
        notifTitre   = '🎉 Entretien planifié !';
        notifMessage = `Vous avez un entretien pour "${candidature.offre?.titre}" le ${new Date(date_entretien).toLocaleDateString('fr-FR')}`;
        if (lien_visio) {
          notifMessage += `. Lien visio: ${lien_visio}`;
        }
        break;

      case 'accepter':
        updateData.statut = 'acceptee';
        messageReponse = 'Candidature acceptée ! 🎉';
        notifTitre   = '🎊 Félicitations ! Candidature acceptée';
        notifMessage = `${req.entreprise.nom_entreprise} a accepté votre candidature pour "${candidature.offre?.titre}"`;
        break;

      case 'refuser':
        updateData.statut = 'refusee';
        messageReponse = 'Candidature refusée';
        notifTitre   = 'Résultat de votre candidature';
        notifMessage = `${req.entreprise.nom_entreprise} n'a pas retenu votre candidature pour "${candidature.offre?.titre}"`;
        if (raison_refus) {
          notifMessage += `. Motif: ${raison_refus}`;
        }
        break;

      default:
        return res.status(400).json({
          success: false,
          message: 'Action invalide. Valeurs: mettre_en_examen, planifier_entretien, accepter, refuser'
        });
    }

    const { data, error } = await supabase
      .from('candidatures')
      .update(updateData)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    // Notifier le candidat
    if (notifTitre && candidature.chercheur_id) {
      setImmediate(async () => {
        try {
          // Récupérer l'utilisateur_id du chercheur
          const { data: chercheur } = await supabase
            .from('chercheurs_emploi')
            .select('utilisateur_id')
            .eq('id', candidature.chercheur_id)
            .single();

          if (chercheur?.utilisateur_id) {
            await supabase.from('notifications').insert({
              destinataire_id:   chercheur.utilisateur_id,
              type_destinataire: 'individuel',
              titre:             notifTitre,
              message:           notifMessage,
              type:              'candidature',
              lien:              '/dashboard/candidatures',
              envoye_par:        req.user.id,
            });
          }
        } catch (e) {
          console.warn('[candidature/notif] Non bloquant:', e.message);
        }
      });
    }

    return res.json({
      success: true,
      message: messageReponse,
      data
    });

  } catch (err) {
    console.error('[recruteur/candidatures PATCH]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// GET /api/recruteur/candidatures/export
router.get('/export/csv', async (req, res) => {
  try {
    const { offre_id } = req.query;

    const { data: mesOffres } = await supabase
      .from('offres_emploi')
      .select('id, titre')
      .eq('entreprise_id', req.entreprise.id);

    const mesOffresIds = (mesOffres || []).map(o => o.id);

    let query = supabase
      .from('candidatures')
      .select(`
        statut, score_compatibilite, date_candidature,
        chercheur:chercheur_id (
          utilisateur:utilisateur_id (nom, email, telephone)
        ),
        offre:offre_id (titre)
      `)
      .in('offre_id', mesOffresIds)
      .order('date_candidature', { ascending: false });

    if (offre_id) query = query.eq('offre_id', offre_id);

    const { data } = await query;

    const lines = ['Candidat,Email,Téléphone,Poste,Statut,Score IA,Date'];
    (data || []).forEach(c => {
      lines.push([
        `"${c.chercheur?.utilisateur?.nom || ''}"`,
        `"${c.chercheur?.utilisateur?.email || ''}"`,
        `"${c.chercheur?.utilisateur?.telephone || ''}"`,
        `"${c.offre?.titre || ''}"`,
        c.statut || '',
        c.score_compatibilite || '',
        c.date_candidature?.split('T')[0] || '',
      ].join(','));
    });

    const csv = lines.join('\n');
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition',
      `attachment; filename="candidatures_${req.entreprise.nom_entreprise}.csv"`);
    return res.send('\uFEFF' + csv);

  } catch (err) {
    console.error('[recruteur/candidatures/export]', err);
    res.status(500).json({ success: false, message: 'Erreur export' });
  }
});

const _statsVides = () => ({
  total: 0, en_attente: 0, en_cours: 0,
  entretien: 0, acceptees: 0, refusees: 0,
});

module.exports = router;
```

---

## 7. Routes Recruteur — Profil Entreprise

### `backend/src/routes/recruteur/profil.routes.js`
```javascript
const express  = require('express');
const router   = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');
const multer  = require('multer');
const sharp   = require('sharp');

router.use(auth, requireRecruteur);

const uploadLogo = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowed.includes(file.mimetype.toLowerCase())) cb(null, true);
    else cb(new Error('Format non supporté'));
  },
});

// GET /api/recruteur/profil
router.get('/', async (req, res) => {
  try {
    const { data: entreprise, error } = await supabase
      .from('entreprises')
      .select(`
        id, nom_entreprise, description, secteur_activite,
        taille_entreprise, site_web, logo_url, adresse_siege,
        utilisateur:utilisateur_id (
          id, nom, email, telephone, adresse, photo_url,
          est_actif, est_valide, date_creation, derniere_connexion
        )
      `)
      .eq('utilisateur_id', req.user.id)
      .single();

    if (error || !entreprise) {
      return res.status(404).json({
        success: false, message: 'Profil entreprise non trouvé'
      });
    }

    // Stats rapides
    const { count: nbOffres } = await supabase
      .from('offres_emploi')
      .select('id', { count: 'exact' })
      .eq('entreprise_id', req.entreprise.id);

    const { count: nbCandidatures } = await supabase
      .from('candidatures')
      .select('id', { count: 'exact' })
      .in('offre_id',
        supabase.from('offres_emploi')
          .select('id').eq('entreprise_id', req.entreprise.id)
      );

    return res.json({
      success: true,
      data: {
        ...entreprise,
        stats: {
          nb_offres:       nbOffres || 0,
          nb_candidatures: nbCandidatures || 0,
        }
      }
    });

  } catch (err) {
    console.error('[recruteur/profil GET]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// PATCH /api/recruteur/profil
router.patch('/', async (req, res) => {
  try {
    const {
      nom_entreprise, description, secteur_activite,
      taille_entreprise, site_web, adresse_siege,
      // Champs utilisateur
      nom, telephone,
    } = req.body;

    // Mettre à jour l'entreprise
    const entrepriseUpdate = {};
    if (nom_entreprise)  entrepriseUpdate.nom_entreprise  = nom_entreprise;
    if (description)     entrepriseUpdate.description     = description;
    if (secteur_activite) entrepriseUpdate.secteur_activite = secteur_activite;
    if (taille_entreprise) entrepriseUpdate.taille_entreprise = taille_entreprise;
    if (site_web !== undefined) entrepriseUpdate.site_web  = site_web;
    if (adresse_siege)   entrepriseUpdate.adresse_siege   = adresse_siege;

    if (Object.keys(entrepriseUpdate).length > 0) {
      entrepriseUpdate.date_modification = new Date().toISOString();
      await supabase.from('entreprises')
        .update(entrepriseUpdate)
        .eq('utilisateur_id', req.user.id);
    }

    // Mettre à jour l'utilisateur
    const userUpdate = {};
    if (nom)       userUpdate.nom       = nom;
    if (telephone) userUpdate.telephone = telephone;

    if (Object.keys(userUpdate).length > 0) {
      userUpdate.date_modification = new Date().toISOString();
      await supabase.from('utilisateurs')
        .update(userUpdate)
        .eq('id', req.user.id);
    }

    return res.json({
      success: true,
      message: 'Profil entreprise mis à jour avec succès'
    });

  } catch (err) {
    console.error('[recruteur/profil PATCH]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// POST /api/recruteur/profil/logo
router.post('/logo', uploadLogo.single('logo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false, message: 'Aucun fichier fourni'
      });
    }

    const buffer = await sharp(req.file.buffer)
      .resize(200, 200, { fit: 'cover' })
      .png({ quality: 85 })
      .toBuffer();

    const bucket   = 'logos';
    const fileName = `logo-entreprise-${req.entreprise.id}-${Date.now()}.png`;

    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(fileName, buffer, {
        contentType: 'image/png', upsert: true
      });

    if (uploadErr) throw uploadErr;

    const { data: urlData } = supabase.storage
      .from(bucket).getPublicUrl(fileName);
    const logoUrl = urlData.publicUrl;

    await supabase.from('entreprises')
      .update({ logo_url: logoUrl })
      .eq('utilisateur_id', req.user.id);

    return res.json({
      success: true,
      message: 'Logo mis à jour avec succès',
      data: { logo_url: logoUrl }
    });

  } catch (err) {
    console.error('[recruteur/profil/logo]', err);
    res.status(500).json({
      success: false, message: err.message || 'Erreur upload'
    });
  }
});

module.exports = router;
```

---

## 8. Routes Recruteur — Messagerie

### `backend/src/routes/recruteur/messages.routes.js`
```javascript
const express  = require('express');
const router   = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');
const crypto = require('crypto');

router.use(auth, requireRecruteur);

// Générer un ID de conversation unique entre 2 utilisateurs
const getConversationId = (userId1, userId2) => {
  const sorted = [userId1, userId2].sort().join('-');
  return crypto.createHash('md5').update(sorted).digest('hex');
};

// GET /api/recruteur/messages
// Liste toutes les conversations du recruteur
router.get('/', async (req, res) => {
  try {
    // Récupérer tous les messages impliquant ce recruteur
    const { data: messages } = await supabase
      .from('messages')
      .select(`
        conversation_id, contenu, date_envoi, est_lu,
        expediteur:expediteur_id (id, nom, photo_url, role),
        destinataire:destinataire_id (id, nom, photo_url, role),
        offre:offre_id (id, titre)
      `)
      .or(`expediteur_id.eq.${req.user.id},destinataire_id.eq.${req.user.id}`)
      .order('date_envoi', { ascending: false });

    if (!messages) {
      return res.json({ success: true, data: [] });
    }

    // Grouper par conversation (garder le dernier message)
    const conversationsMap = {};
    messages.forEach(msg => {
      if (!conversationsMap[msg.conversation_id]) {
        conversationsMap[msg.conversation_id] = msg;
      }
    });

    // Compter les non lus par conversation
    const { data: nonLus } = await supabase
      .from('messages')
      .select('conversation_id')
      .eq('destinataire_id', req.user.id)
      .eq('est_lu', false);

    const nonLusCount = {};
    (nonLus || []).forEach(m => {
      nonLusCount[m.conversation_id] =
        (nonLusCount[m.conversation_id] || 0) + 1;
    });

    const conversations = Object.values(conversationsMap).map(c => ({
      ...c,
      nb_non_lus: nonLusCount[c.conversation_id] || 0,
    }));

    return res.json({ success: true, data: conversations });

  } catch (err) {
    console.error('[recruteur/messages GET]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// GET /api/recruteur/messages/:destinataireId
// Messages d'une conversation spécifique
router.get('/:destinataireId', async (req, res) => {
  try {
    const { destinataireId } = req.params;
    const conversationId = getConversationId(req.user.id, destinataireId);

    const { data: messages, error } = await supabase
      .from('messages')
      .select(`
        id, contenu, date_envoi, est_lu,
        expediteur_id, destinataire_id,
        offre:offre_id (id, titre)
      `)
      .eq('conversation_id', conversationId)
      .order('date_envoi', { ascending: true });

    if (error) throw error;

    // Marquer comme lus les messages reçus
    await supabase
      .from('messages')
      .update({
        est_lu:       true,
        date_lecture: new Date().toISOString()
      })
      .eq('conversation_id', conversationId)
      .eq('destinataire_id', req.user.id)
      .eq('est_lu', false);

    // Infos de l'interlocuteur
    const { data: interlocuteur } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, photo_url, role')
      .eq('id', destinataireId)
      .single();

    return res.json({
      success: true,
      data: {
        messages:      messages || [],
        interlocuteur,
        conversation_id: conversationId,
      }
    });

  } catch (err) {
    console.error('[recruteur/messages/:id GET]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// POST /api/recruteur/messages
// Envoyer un message
router.post('/', async (req, res) => {
  try {
    const { destinataire_id, contenu, offre_id } = req.body;

    if (!destinataire_id || !contenu) {
      return res.status(400).json({
        success: false,
        message: 'destinataire_id et contenu requis'
      });
    }

    if (contenu.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Le message ne peut pas être vide'
      });
    }

    const conversationId = getConversationId(
      req.user.id, destinataire_id);

    const { data: message, error } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        expediteur_id:   req.user.id,
        destinataire_id,
        contenu:         contenu.trim(),
        offre_id:        offre_id || null,
        date_envoi:      new Date().toISOString(),
        est_lu:          false,
      })
      .select()
      .single();

    if (error) throw error;

    // Notifier le destinataire
    setImmediate(async () => {
      try {
        await supabase.from('notifications').insert({
          destinataire_id,
          type_destinataire: 'individuel',
          titre:   `💬 Nouveau message de ${req.entreprise.nom_entreprise}`,
          message: contenu.trim().slice(0, 100),
          type:    'message',
          lien:    '/dashboard/messages',
        });
      } catch (e) {
        console.warn('[message/notif] Non bloquant:', e.message);
      }
    });

    return res.status(201).json({
      success: true,
      message: 'Message envoyé',
      data: message
    });

  } catch (err) {
    console.error('[recruteur/messages POST]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;
```

---

## 9. Routes Recruteur — Notifications

### `backend/src/routes/recruteur/notifications.routes.js`
```javascript
const express  = require('express');
const router   = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');

router.use(auth, requireRecruteur);

// GET /api/recruteur/notifications
router.get('/', async (req, res) => {
  try {
    const { page = 1, limite = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limite);

    const { data, count } = await supabase
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .order('date_creation', { ascending: false })
      .range(offset, offset + parseInt(limite) - 1);

    const { count: nbNonLues } = await supabase
      .from('notifications')
      .select('id', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .eq('est_lue', false);

    return res.json({
      success: true,
      data: {
        notifications: data || [],
        nb_non_lues: nbNonLues || 0,
        pagination: {
          total: count || 0,
          page: parseInt(page),
          limite: parseInt(limite),
        }
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// PATCH /api/recruteur/notifications/:id/lire
router.patch('/:id/lire', async (req, res) => {
  try {
    await supabase.from('notifications')
      .update({ est_lue: true })
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id);
    return res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// PATCH /api/recruteur/notifications/tout-lire
router.patch('/tout-lire/action', async (req, res) => {
  try {
    await supabase.from('notifications')
      .update({ est_lue: true })
      .eq('destinataire_id', req.user.id)
      .eq('est_lue', false);
    return res.json({
      success: true,
      message: 'Toutes les notifications marquées comme lues'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;
```

---

## 10. Routes Recruteur — Recherche Talents IA

### `backend/src/routes/recruteur/talents.routes.js`
```javascript
const express  = require('express');
const router   = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');
const { calculerMatchingScore } = require('../../services/ia.service');

router.use(auth, requireRecruteur);

// ══════════════════════════════════════════════════════════════
// GET /api/recruteur/talents
// Recherche de talents avec score IA
// ══════════════════════════════════════════════════════════════
router.get('/', async (req, res) => {
  try {
    const {
      recherche,
      niveau_etude,
      disponibilite,
      ville,
      experience,
      page = 1, limite = 20,
      offre_id, // Si fourni, calculer le score vs cette offre
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    // Récupérer les candidats dont le profil est visible
    let query = supabase
      .from('chercheurs_emploi')
      .select(`
        id, competences, niveau_etude, disponibilite,
        utilisateur:utilisateur_id (
          id, nom, photo_url, adresse, est_actif
        ),
        cv:cv (
          competences_extrait, niveau_experience
        )
      `, { count: 'exact' })
      .range(offset, offset + parseInt(limite) - 1);

    if (niveau_etude)  query = query.eq('niveau_etude', niveau_etude);
    if (disponibilite) query = query.eq('disponibilite', disponibilite);

    const { data: talents, count, error } = await query;
    if (error) throw error;

    // Filtres post-requête
    let resultats = (talents || []).filter(t =>
      t.utilisateur?.est_actif === true
    );

    if (ville) {
      resultats = resultats.filter(t =>
        t.utilisateur?.adresse?.toLowerCase()
          .includes(ville.toLowerCase())
      );
    }

    if (recherche) {
      const r = recherche.toLowerCase();
      resultats = resultats.filter(t => {
        const comps = Array.isArray(t.competences)
          ? t.competences : Object.values(t.competences || {});
        return comps.some(c =>
          c.toString().toLowerCase().includes(r));
      });
    }

    // Calculer les scores IA si une offre est fournie
    if (offre_id) {
      const { data: offre } = await supabase
        .from('offres_emploi')
        .select('titre, description, competences_requises, localisation, niveau_experience_requis')
        .eq('id', offre_id)
        .eq('entreprise_id', req.entreprise.id)
        .single();

      if (offre) {
        resultats = await Promise.all(
          resultats.map(async (talent) => {
            const compsCV   = talent.cv?.[0]?.competences_extrait?.competences || [];
            const compsProfil = Array.isArray(talent.competences)
              ? talent.competences
              : Object.values(talent.competences || {});

            const score = await calculerMatchingScore(
              {
                competences: [...compsCV, ...compsProfil],
                texte_cv:    '',
                ville:       talent.utilisateur?.adresse || '',
                annees_experience: 0,
              },
              offre
            );

            return { ...talent, score_matching: score };
          })
        );

        // Trier par score décroissant
        resultats.sort((a, b) =>
          (b.score_matching || 0) - (a.score_matching || 0));
      }
    }

    return res.json({
      success: true,
      data: {
        talents: resultats,
        pagination: {
          total: count || 0,
          page:  parseInt(page),
          limite: parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });

  } catch (err) {
    console.error('[recruteur/talents]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// POST /api/recruteur/talents/contacter
// Envoyer un message à un talent depuis la recherche
router.post('/contacter', async (req, res) => {
  try {
    const { talent_utilisateur_id, message, offre_id } = req.body;

    if (!talent_utilisateur_id || !message) {
      return res.status(400).json({
        success: false,
        message: 'talent_utilisateur_id et message requis'
      });
    }

    // Vérifier que le talent existe
    const { data: talent } = await supabase
      .from('utilisateurs')
      .select('id, nom')
      .eq('id', talent_utilisateur_id)
      .single();

    if (!talent) {
      return res.status(404).json({
        success: false, message: 'Talent non trouvé'
      });
    }

    const crypto         = require('crypto');
    const conversationId = crypto.createHash('md5')
      .update([req.user.id, talent_utilisateur_id].sort().join('-'))
      .digest('hex');

    // Créer le message
    const { data: newMsg } = await supabase.from('messages').insert({
      conversation_id: conversationId,
      expediteur_id:   req.user.id,
      destinataire_id: talent_utilisateur_id,
      contenu:         message.trim(),
      offre_id:        offre_id || null,
      date_envoi:      new Date().toISOString(),
    }).select().single();

    // Notification
    await supabase.from('notifications').insert({
      destinataire_id:   talent_utilisateur_id,
      type_destinataire: 'individuel',
      titre:   `💼 ${req.entreprise.nom_entreprise} vous a contacté`,
      message: message.trim().slice(0, 100),
      type:    'message',
      lien:    '/dashboard/messages',
    });

    return res.status(201).json({
      success: true,
      message: `Message envoyé à ${talent.nom}`,
      data: newMsg
    });

  } catch (err) {
    console.error('[recruteur/talents/contacter]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;
```

---

## 11. Routes Recruteur — Statistiques

### `backend/src/routes/recruteur/stats.routes.js`
```javascript
const express  = require('express');
const router   = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');

router.use(auth, requireRecruteur);

// GET /api/recruteur/stats?periode=30d
router.get('/', async (req, res) => {
  try {
    const { periode = '30d' } = req.query;
    const periodeJours = { '7d': 7, '30d': 30, '3m': 90 }[periode] || 30;
    const dateDebut = new Date(
      Date.now() - periodeJours * 24 * 60 * 60 * 1000).toISOString();
    const datePrecedente = new Date(
      Date.now() - 2 * periodeJours * 24 * 60 * 60 * 1000).toISOString();

    const { data: mesOffres } = await supabase
      .from('offres_emploi')
      .select('id, titre, statut, nb_vues')
      .eq('entreprise_id', req.entreprise.id);

    const mesOffresIds = (mesOffres || []).map(o => o.id);

    if (mesOffresIds.length === 0) {
      return res.json({
        success: true,
        data: _statsVides(periode)
      });
    }

    // Candidatures période actuelle
    const { data: cands } = await supabase
      .from('candidatures')
      .select('id, statut, score_compatibilite, date_candidature')
      .in('offre_id', mesOffresIds)
      .gte('date_candidature', dateDebut);

    // Candidatures période précédente (tendance)
    const { count: candsPrecedents } = await supabase
      .from('candidatures')
      .select('id', { count: 'exact' })
      .in('offre_id', mesOffresIds)
      .gte('date_candidature', datePrecedente)
      .lt('date_candidature', dateDebut);

    // Vues période actuelle
    const { count: vuesActuelles } = await supabase
      .from('offres_vues')
      .select('id', { count: 'exact' })
      .in('offre_id', mesOffresIds)
      .gte('date_vue', dateDebut);

    // Taux de réponse
    const { data: toutesC } = await supabase
      .from('candidatures')
      .select('statut')
      .in('offre_id', mesOffresIds);

    const nbTraitees = (toutesC || []).filter(c =>
      ['acceptee', 'refusee', 'entretien'].includes(c.statut)
    ).length;
    const tauxReponse = toutesC?.length > 0
      ? Math.round(nbTraitees / toutesC.length * 100)
      : 0;

    // Évolution par jour
    const evolutionParJour = await _evolutionParJour(
      mesOffresIds, periodeJours);

    // Score IA moyen des candidatures
    const candsAvecScore = (cands || []).filter(
      c => c.score_compatibilite > 0);
    const scoreMoyen = candsAvecScore.length > 0
      ? Math.round(candsAvecScore.reduce(
          (sum, c) => sum + c.score_compatibilite, 0
        ) / candsAvecScore.length)
      : 0;

    // Performance par offre
    const perfParOffre = await _perfParOffre(mesOffres, mesOffresIds);

    // Tendance candidatures
    const nbCands = cands?.length || 0;
    const tendance = candsPrecedents > 0
      ? Math.round((nbCands - candsPrecedents) / candsPrecedents * 100)
      : nbCands > 0 ? 100 : 0;

    return res.json({
      success: true,
      data: {
        periode,
        kpis: {
          candidatures: {
            valeur: nbCands,
            tendance,
          },
          vues: {
            valeur: vuesActuelles || 0,
          },
          taux_reponse: {
            valeur: tauxReponse,
          },
          score_ia_moyen: {
            valeur: scoreMoyen,
          },
        },
        evolution_par_jour: evolutionParJour,
        performance_par_offre: perfParOffre,
        repartition_statuts: {
          en_attente: (toutesC || []).filter(c => c.statut === 'en_attente').length,
          en_cours:   (toutesC || []).filter(c => c.statut === 'en_cours').length,
          entretien:  (toutesC || []).filter(c => c.statut === 'entretien').length,
          acceptees:  (toutesC || []).filter(c => c.statut === 'acceptee').length,
          refusees:   (toutesC || []).filter(c => c.statut === 'refusee').length,
        },
      }
    });

  } catch (err) {
    console.error('[recruteur/stats]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

const _evolutionParJour = async (offresIds, nbJours) => {
  const { data: cands } = await supabase
    .from('candidatures')
    .select('date_candidature')
    .in('offre_id', offresIds)
    .gte('date_candidature',
      new Date(Date.now() - nbJours * 24 * 60 * 60 * 1000).toISOString());

  const parJour = {};
  for (let i = nbJours - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const key = d.toISOString().split('T')[0];
    parJour[key] = { date: key, candidatures: 0 };
  }

  (cands || []).forEach(c => {
    const key = c.date_candidature?.split('T')[0];
    if (key && parJour[key]) parJour[key].candidatures++;
  });

  return Object.values(parJour);
};

const _perfParOffre = async (offres, offresIds) => {
  const { data: cands } = await supabase
    .from('candidatures')
    .select('offre_id, statut, score_compatibilite')
    .in('offre_id', offresIds);

  return offres.map(o => {
    const c = (cands || []).filter(c => c.offre_id === o.id);
    const scores = c.filter(x => x.score_compatibilite > 0)
      .map(x => x.score_compatibilite);
    return {
      id:             o.id,
      titre:          o.titre,
      statut:         o.statut,
      nb_vues:        o.nb_vues || 0,
      nb_candidatures: c.length,
      score_ia_moyen: scores.length > 0
        ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length)
        : 0,
      taux_reponse:   c.length > 0
        ? Math.round(c.filter(x =>
            ['acceptee', 'refusee', 'entretien'].includes(x.statut)
          ).length / c.length * 100)
        : 0,
    };
  });
};

const _statsVides = (periode) => ({
  periode,
  kpis: {
    candidatures:   { valeur: 0, tendance: 0 },
    vues:           { valeur: 0 },
    taux_reponse:   { valeur: 0 },
    score_ia_moyen: { valeur: 0 },
  },
  evolution_par_jour:     [],
  performance_par_offre:  [],
  repartition_statuts:    {
    en_attente: 0, en_cours: 0, entretien: 0,
    acceptees: 0, refusees: 0,
  },
});

module.exports = router;
```

---

## 12. Mise à jour des routes partagées

### Incrémenter le compteur de vues

```javascript
// Dans backend/src/routes/offres.routes.js
// Modifier GET /api/offres/:id pour incrémenter les vues

router.get('/:id', async (req, res) => {
  // ... code existant pour récupérer l'offre ...

  // Incrémenter le compteur de vues (non bloquant)
  setImmediate(async () => {
    try {
      const userId = req.user?.id || null;
      const ip     = req.ip || '';

      // Vérifier si déjà vue dans les dernières 24h
      const hier = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
      let query = supabase
        .from('offres_vues')
        .select('id')
        .eq('offre_id', req.params.id)
        .gte('date_vue', hier);

      if (userId) {
        query = query.eq('user_id', userId);
      } else {
        query = query.eq('ip_address', ip);
      }

      const { data: vueExistante } = await query.single();

      if (!vueExistante) {
        await supabase.from('offres_vues').insert({
          offre_id:   req.params.id,
          user_id:    userId,
          ip_address: ip,
        });
        await supabase
          .from('offres_emploi')
          .update({
            nb_vues: supabase.rpc('increment', { row_id: req.params.id })
          })
          .eq('id', req.params.id);
      }
    } catch (e) {
      // Non bloquant
    }
  });
});
```

### Registrer toutes les routes recruteur

```javascript
// backend/src/routes/index.js — AJOUTER

// Routes recruteur
router.use('/recruteur/dashboard',     require('./recruteur/dashboard.routes'));
router.use('/recruteur/offres',        require('./recruteur/offres.routes'));
router.use('/recruteur/candidatures',  require('./recruteur/candidatures.routes'));
router.use('/recruteur/profil',        require('./recruteur/profil.routes'));
router.use('/recruteur/messages',      require('./recruteur/messages.routes'));
router.use('/recruteur/notifications', require('./recruteur/notifications.routes'));
router.use('/recruteur/talents',       require('./recruteur/talents.routes'));
router.use('/recruteur/stats',         require('./recruteur/stats.routes'));
```

---

## 13. Flutter — RecruteurService complet

```dart
// lib/services/recruteur_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RecruteurService {
  final String _base = '${ApiConfig.baseUrl}/api/recruteur';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ── DASHBOARD ──────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard(String token) async {
    final res = await http.get(
      Uri.parse('$_base/dashboard'), headers: _headers(token));
    return _handle(res);
  }

  // ── OFFRES ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getOffres(String token, {
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
    return _handle(res);
  }

  Future<Map<String, dynamic>> createOffre(
    String token, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_base/offres'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> updateOffre(
    String token, String id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_base/offres/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> dupliquerOffre(
    String token, String id) async {
    final res = await http.post(
      Uri.parse('$_base/offres/$id/dupliquer'),
      headers: _headers(token),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> cloturerOffre(
    String token, String id) async {
    final res = await http.patch(
      Uri.parse('$_base/offres/$id/cloturer'),
      headers: _headers(token),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> deleteOffre(
    String token, String id) async {
    final res = await http.delete(
      Uri.parse('$_base/offres/$id'),
      headers: _headers(token),
    );
    return _handle(res);
  }

  // ── CANDIDATURES ───────────────────────────────────────────
  Future<Map<String, dynamic>> getCandidatures(String token, {
    String? offreId, String? statut,
    String? recherche, String vue = 'liste',
    int page = 1, int limite = 50,
  }) async {
    final params = {
      'vue': vue, 'page': '$page', 'limite': '$limite',
      if (offreId != null) 'offre_id': offreId,
      if (statut != null) 'statut': statut,
      if (recherche != null) 'recherche': recherche,
    };
    final uri = Uri.parse('$_base/candidatures')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    return _handle(res);
  }

  Future<Map<String, dynamic>> getCandidature(
    String token, String id) async {
    final res = await http.get(
      Uri.parse('$_base/candidatures/$id'),
      headers: _headers(token),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> actionCandidature(
    String token, String id, String action, {
    String? dateEntretien, String? lienVisio,
    String? raisonRefus,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/candidatures/$id'),
      headers: _headers(token),
      body: jsonEncode({
        'action': action,
        if (dateEntretien != null) 'date_entretien': dateEntretien,
        if (lienVisio != null) 'lien_visio': lienVisio,
        if (raisonRefus != null) 'raison_refus': raisonRefus,
      }),
    );
    return _handle(res);
  }

  // ── PROFIL ENTREPRISE ──────────────────────────────────────
  Future<Map<String, dynamic>> getProfil(String token) async {
    final res = await http.get(
      Uri.parse('$_base/profil'), headers: _headers(token));
    return _handle(res);
  }

  Future<Map<String, dynamic>> updateProfil(
    String token, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_base/profil'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    return _handle(res);
  }

  // ── MESSAGERIE ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getConversations(String token) async {
    final res = await http.get(
      Uri.parse('$_base/messages'), headers: _headers(token));
    return _handle(res);
  }

  Future<Map<String, dynamic>> getMessages(
    String token, String destinataireId) async {
    final res = await http.get(
      Uri.parse('$_base/messages/$destinataireId'),
      headers: _headers(token),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> envoyerMessage(
    String token, String destinataireId,
    String contenu, {String? offreId}
  ) async {
    final res = await http.post(
      Uri.parse('$_base/messages'),
      headers: _headers(token),
      body: jsonEncode({
        'destinataire_id': destinataireId,
        'contenu': contenu,
        if (offreId != null) 'offre_id': offreId,
      }),
    );
    return _handle(res);
  }

  // ── TALENTS ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTalents(String token, {
    String? recherche, String? niveauEtude,
    String? disponibilite, String? ville,
    String? offreId, int page = 1, int limite = 20,
  }) async {
    final params = {
      'page': '$page', 'limite': '$limite',
      if (recherche != null) 'recherche': recherche,
      if (niveauEtude != null) 'niveau_etude': niveauEtude,
      if (disponibilite != null) 'disponibilite': disponibilite,
      if (ville != null) 'ville': ville,
      if (offreId != null) 'offre_id': offreId,
    };
    final uri = Uri.parse('$_base/talents')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers(token));
    return _handle(res);
  }

  Future<Map<String, dynamic>> contacterTalent(
    String token, String talentId,
    String message, {String? offreId}
  ) async {
    final res = await http.post(
      Uri.parse('$_base/talents/contacter'),
      headers: _headers(token),
      body: jsonEncode({
        'talent_utilisateur_id': talentId,
        'message': message,
        if (offreId != null) 'offre_id': offreId,
      }),
    );
    return _handle(res);
  }

  // ── STATISTIQUES ───────────────────────────────────────────
  Future<Map<String, dynamic>> getStats(
    String token, {String periode = '30d'}) async {
    final res = await http.get(
      Uri.parse('$_base/stats?periode=$periode'),
      headers: _headers(token),
    );
    return _handle(res);
  }

  // ── NOTIFICATIONS ──────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications(
    String token, {int page = 1}) async {
    final res = await http.get(
      Uri.parse('$_base/notifications?page=$page'),
      headers: _headers(token),
    );
    return _handle(res);
  }

  Future<void> marquerNotifLue(String token, String id) async {
    await http.patch(
      Uri.parse('$_base/notifications/$id/lire'),
      headers: _headers(token),
    );
  }

  Future<void> marquerToutesLues(String token) async {
    await http.patch(
      Uri.parse('$_base/notifications/tout-lire/action'),
      headers: _headers(token),
    );
  }

  // ── HELPER ─────────────────────────────────────────────────
  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Erreur ${res.statusCode}');
  }
}
```

---

## 14. Tests des endpoints

### `backend/tests/recruteur.test.http`
```http
### Variables
@base = http://localhost:3000/api
@tokenRecruteur = VOTRE_JWT_RECRUTEUR
@offreId = UUID_OFFRE
@candidatureId = UUID_CANDIDATURE

### ── DASHBOARD ──────────────────────────────────────────────
GET {{base}}/recruteur/dashboard
Authorization: Bearer {{tokenRecruteur}}

###

### ── OFFRES ──────────────────────────────────────────────────
# Mes offres
GET {{base}}/recruteur/offres
Authorization: Bearer {{tokenRecruteur}}

###

# Créer une offre
POST {{base}}/recruteur/offres
Authorization: Bearer {{tokenRecruteur}}
Content-Type: application/json

{
  "titre": "Développeur Flutter Senior",
  "description": "Nous recherchons un développeur Flutter expérimenté...",
  "exigences": "3 ans d'expérience minimum avec Flutter et Dart",
  "competences_requises": ["Flutter", "Dart", "Firebase"],
  "localisation": "Conakry",
  "type_contrat": "CDI",
  "niveau_experience_requis": "3_5_ans",
  "domaine": "Technologie",
  "publier_maintenant": true
}

###

# Dupliquer une offre
POST {{base}}/recruteur/offres/{{offreId}}/dupliquer
Authorization: Bearer {{tokenRecruteur}}

###

# Clôturer une offre
PATCH {{base}}/recruteur/offres/{{offreId}}/cloturer
Authorization: Bearer {{tokenRecruteur}}

###

### ── CANDIDATURES ─────────────────────────────────────────────
# Liste (vue liste)
GET {{base}}/recruteur/candidatures?vue=liste
Authorization: Bearer {{tokenRecruteur}}

###

# Vue kanban
GET {{base}}/recruteur/candidatures?vue=kanban
Authorization: Bearer {{tokenRecruteur}}

###

# Filtrer par offre
GET {{base}}/recruteur/candidatures?offre_id={{offreId}}
Authorization: Bearer {{tokenRecruteur}}

###

# Mettre en examen
PATCH {{base}}/recruteur/candidatures/{{candidatureId}}
Authorization: Bearer {{tokenRecruteur}}
Content-Type: application/json

{"action": "mettre_en_examen"}

###

# Planifier entretien
PATCH {{base}}/recruteur/candidatures/{{candidatureId}}
Authorization: Bearer {{tokenRecruteur}}
Content-Type: application/json

{
  "action": "planifier_entretien",
  "date_entretien": "2026-04-01T14:00:00Z",
  "lien_visio": "https://meet.google.com/abc-def-ghi"
}

###

# Accepter
PATCH {{base}}/recruteur/candidatures/{{candidatureId}}
Authorization: Bearer {{tokenRecruteur}}
Content-Type: application/json

{"action": "accepter"}

###

# Refuser
PATCH {{base}}/recruteur/candidatures/{{candidatureId}}
Authorization: Bearer {{tokenRecruteur}}
Content-Type: application/json

{"action": "refuser", "raison_refus": "Profil ne correspond pas"}

###

### ── PROFIL ───────────────────────────────────────────────────
GET {{base}}/recruteur/profil
Authorization: Bearer {{tokenRecruteur}}

###

PATCH {{base}}/recruteur/profil
Authorization: Bearer {{tokenRecruteur}}
Content-Type: application/json

{
  "nom_entreprise": "Orange Guinée",
  "description": "Leader des télécommunications en Guinée",
  "secteur_activite": "Télécommunications",
  "taille_entreprise": "200-500"
}

###

### ── TALENTS ─────────────────────────────────────────────────
# Recherche générale
GET {{base}}/recruteur/talents?recherche=flutter
Authorization: Bearer {{tokenRecruteur}}

###

# Recherche avec matching IA sur une offre
GET {{base}}/recruteur/talents?offre_id={{offreId}}
Authorization: Bearer {{tokenRecruteur}}

###

# Contacter un talent
POST {{base}}/recruteur/talents/contacter
Authorization: Bearer {{tokenRecruteur}}
Content-Type: application/json

{
  "talent_utilisateur_id": "UUID_TALENT",
  "message": "Bonjour, votre profil correspond à notre offre Flutter Senior.",
  "offre_id": "{{offreId}}"
}

###

### ── STATS ───────────────────────────────────────────────────
GET {{base}}/recruteur/stats?periode=30d
Authorization: Bearer {{tokenRecruteur}}

###

GET {{base}}/recruteur/stats?periode=7d
Authorization: Bearer {{tokenRecruteur}}

###
```

---

## 15. Critères d'Acceptation

### ✅ Migrations SQL
- [ ] `010_add_messages.sql` exécuté (table messages + vue v_conversations)
- [ ] `011_add_offres_vues.sql` exécuté (table vues + offres_sauvegardees)

### ✅ Middleware
- [ ] `requireRecruteur` créé et fonctionne (403 si non entreprise)
- [ ] `req.entreprise` disponible dans toutes les routes recruteur

### ✅ Dashboard
- [ ] `GET /api/recruteur/dashboard` → stats + offres actives + candidatures récentes
- [ ] Stats correctes : offres_actives, candidatures_en_attente, vues_mois, taux_reponse

### ✅ Offres
- [ ] `GET /api/recruteur/offres` → mes offres avec nb_candidatures et nb_non_lues
- [ ] `POST /api/recruteur/offres` → crée offre, vérifie limite, enrichit IA
- [ ] `PATCH /api/recruteur/offres/:id` → modifie (seulement ses offres)
- [ ] `POST /api/recruteur/offres/:id/dupliquer` → copie en brouillon
- [ ] `PATCH /api/recruteur/offres/:id/cloturer` → change statut expiree
- [ ] `DELETE /api/recruteur/offres/:id` → supprime

### ✅ Candidatures
- [ ] `GET /api/recruteur/candidatures` → liste + vue kanban (groupée par statut)
- [ ] `GET /api/recruteur/candidatures/:id` → détail + URL signée CV
- [ ] `PATCH /api/recruteur/candidatures/:id` → actions : mettre_en_examen, planifier_entretien, accepter, refuser
- [ ] Notification envoyée au candidat à chaque changement de statut
- [ ] Export CSV fonctionnel

### ✅ Profil Entreprise
- [ ] `GET /api/recruteur/profil` → données complètes + stats
- [ ] `PATCH /api/recruteur/profil` → mise à jour entreprise + utilisateur
- [ ] `POST /api/recruteur/profil/logo` → upload logo bucket "logos"

### ✅ Messagerie
- [ ] `GET /api/recruteur/messages` → liste conversations groupées
- [ ] `GET /api/recruteur/messages/:id` → messages d'une conversation + marque comme lus
- [ ] `POST /api/recruteur/messages` → envoyer message + notifier destinataire

### ✅ Talents IA
- [ ] `GET /api/recruteur/talents` → liste avec filtres
- [ ] `GET /api/recruteur/talents?offre_id=X` → liste triée par score IA
- [ ] `POST /api/recruteur/talents/contacter` → message + notification

### ✅ Statistiques
- [ ] `GET /api/recruteur/stats` → KPIs + évolution + performance par offre
- [ ] Sélecteur période (7d/30d/3m) fonctionnel
- [ ] Score IA moyen des candidatures calculé

### ✅ Flutter RecruteurService
- [ ] Toutes les méthodes créées dans `recruteur_service.dart`
- [ ] Pages recruteur remplacent les données mock par appels API
- [ ] Dashboard recruteur : données temps réel
- [ ] Kanban candidatures : drag-and-drop appelle `actionCandidature`

---

*PRD EmploiConnect v5.0 — Backend Recruteur/Entreprise Complet*
*Cursor / Kirsoft AI — Phase 9*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
