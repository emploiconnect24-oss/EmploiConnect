# PRD — EmploiConnect · Fix & Complétion Backend Recruteur
## Product Requirements Document v5.2 — Recruteur Real Data Fix
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Objectif : Corriger TOUS les zéros et données fictives — Espace Recruteur**
**Référence : PRD_BACKEND_ADMIN.md + PRD_BACKEND_RECRUTEUR.md (déjà validés)**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> 1. Lire d'abord PRD_BACKEND_ADMIN.md pour comprendre la cohérence
> 2. Ce PRD corrige les vrais problèmes identifiés lors des tests
> 3. Toutes les valeurs à ZÉRO doivent devenir des vraies valeurs
> 4. Tout doit être cohérent : Admin ↔ Recruteur (même BDD)
> 5. Implémenter dans l'ordre EXACT des sections

---

## Table des Matières

1. [Diagnostic — Pourquoi les valeurs sont à zéro](#1-diagnostic--pourquoi-les-valeurs-sont-à-zéro)
2. [Fix Backend — Route Dashboard Recruteur](#2-fix-backend--route-dashboard-recruteur)
3. [Fix Backend — Route Mes Offres](#3-fix-backend--route-mes-offres)
4. [Fix Backend — Route Candidatures](#4-fix-backend--route-candidatures)
5. [Fix Backend — Route Talents](#5-fix-backend--route-talents)
6. [Fix Backend — Route Profil Entreprise](#6-fix-backend--route-profil-entreprise)
7. [Fix Flutter — RecruteurProvider corrigé](#7-fix-flutter--recruteurprovider-corrigé)
8. [Fix Flutter — Vue d'ensemble corrigée](#8-fix-flutter--vue-densemble-corrigée)
9. [Fix Flutter — Page Mes Offres corrigée](#9-fix-flutter--page-mes-offres-corrigée)
10. [Fix Flutter — Page Candidatures corrigée](#10-fix-flutter--page-candidatures-corrigée)
11. [Fix Flutter — Page Profil avec Upload](#11-fix-flutter--page-profil-avec-upload)
12. [Notifications Recruteur — Flux complet](#12-notifications-recruteur--flux-complet)
13. [Tests de validation](#13-tests-de-validation)
14. [Critères d'Acceptation](#14-critères-dacceptation)

---

## 1. Diagnostic — Pourquoi les valeurs sont à zéro

### Causes identifiées

```
CAUSE 1 — requireRecruteur échoue silencieusement
Le middleware cherche req.entreprise mais si l'entreprise
n'est pas trouvée en BDD, la requête retourne 403
et Flutter affiche 0 sans montrer d'erreur.

CAUSE 2 — entreprise_id incorrect
Le RecruteurProvider appelle getDashboard() mais
l'entreprise n'est pas encore dans la table 'entreprises'
si l'inscription n'a pas créé cette ligne.

CAUSE 3 — Sous-requête Supabase incorrecte
Certaines queries utilisent une sous-requête imbriquée
que Supabase JS ne supporte pas directement.

CAUSE 4 — Token expiré ou non passé
Le token n'est pas envoyé correctement depuis Flutter.

SOLUTION : Corriger chaque point, ajouter des logs précis,
vérifier la cohérence des données en BDD.
```

### Vérification rapide — Exécuter dans Supabase SQL Editor

```sql
-- Vérifier que les tables sont bien reliées
SELECT
  u.id AS user_id,
  u.nom,
  u.email,
  u.role,
  e.id AS entreprise_id,
  e.nom_entreprise,
  COUNT(DISTINCT o.id) AS nb_offres,
  COUNT(DISTINCT c.id) AS nb_candidatures
FROM utilisateurs u
LEFT JOIN entreprises e ON e.utilisateur_id = u.id
LEFT JOIN offres_emploi o ON o.entreprise_id = e.id
LEFT JOIN candidatures cand ON cand.offre_id = o.id
LEFT JOIN cv cv_t ON cv_t.chercheur_id = u.id
WHERE u.role = 'entreprise'
GROUP BY u.id, u.nom, u.email, u.role, e.id, e.nom_entreprise
ORDER BY u.date_creation DESC;

-- Résultat attendu :
-- Pour chaque compte entreprise : voir nb_offres et nb_candidatures
-- Si entreprise_id = NULL → problème d'inscription incomplète
```

---

## 2. Fix Backend — Route Dashboard Recruteur

### `backend/src/routes/recruteur/dashboard.routes.js` — VERSION CORRIGÉE

```javascript
const express  = require('express');
const router   = express.Router();
const { auth } = require('../../middleware/auth');
const { requireRecruteur } = require('../../middleware/recruteurAuth');
const { supabase } = require('../../config/supabase');

router.use(auth, requireRecruteur);

router.get('/', async (req, res) => {
  try {
    const entrepriseId = req.entreprise.id;

    console.log('[recruteur/dashboard] entreprise_id:', entrepriseId);

    // ── ÉTAPE 1 : Toutes les offres de cette entreprise ────
    const { data: toutesOffres, error: offresErr } = await supabase
      .from('offres_emploi')
      .select('id, titre, statut, nb_vues, date_publication, date_creation')
      .eq('entreprise_id', entrepriseId)
      .order('date_creation', { ascending: false });

    if (offresErr) {
      console.error('[dashboard] Erreur offres:', offresErr.message);
    }

    const offres = toutesOffres || [];
    console.log('[dashboard] Nb offres trouvées:', offres.length);

    const offresIds = offres.map(o => o.id);

    // ── ÉTAPE 2 : Toutes les candidatures pour ces offres ──
    let toutesCandidatures = [];
    if (offresIds.length > 0) {
      const { data: cands, error: candsErr } = await supabase
        .from('candidatures')
        .select(`
          id, statut, score_compatibilite,
          date_candidature, offre_id,
          chercheur:chercheur_id (
            id,
            utilisateur:utilisateur_id (
              id, nom, email, photo_url
            )
          ),
          offre:offre_id (id, titre)
        `)
        .in('offre_id', offresIds)
        .order('date_candidature', { ascending: false });

      if (candsErr) {
        console.error('[dashboard] Erreur cands:', candsErr.message);
      }
      toutesCandidatures = cands || [];
    }

    console.log('[dashboard] Nb candidatures:', toutesCandidatures.length);

    // ── ÉTAPE 3 : Messages non lus ─────────────────────────
    const { count: nbMessagesNonLus } = await supabase
      .from('messages')
      .select('id', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .eq('est_lu', false);

    // ── ÉTAPE 4 : Calculs des stats ────────────────────────
    const offresActives    = offres.filter(o => o.statut === 'publiee');
    const offresEnAttente  = offres.filter(o => o.statut === 'en_attente');
    const candsEnAttente   = toutesCandidatures.filter(c =>
      c.statut === 'en_attente');
    const candsTraitees    = toutesCandidatures.filter(c =>
      ['acceptee', 'refusee', 'entretien'].includes(c.statut));

    // Taux de réponse
    const tauxReponse = toutesCandidatures.length > 0
      ? Math.round(candsTraitees.length / toutesCandidatures.length * 100)
      : 0;

    // Vues totales ce mois
    const dateDebut30j = new Date(
      Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    let vuesMois = 0;
    if (offresIds.length > 0) {
      const { count } = await supabase
        .from('offres_vues')
        .select('id', { count: 'exact' })
        .in('offre_id', offresIds)
        .gte('date_vue', dateDebut30j);
      vuesMois = count || 0;
    }

    // Candidatures urgentes (en attente > 7 jours)
    const seuilUrgence = new Date(
      Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const candidaturesUrgentes = candsEnAttente.filter(c =>
      c.date_candidature < seuilUrgence);

    // ── ÉTAPE 5 : Ajouter stats par offre active ───────────
    const offresActivesAvecStats = offresActives
      .slice(0, 5)
      .map(o => ({
        ...o,
        nb_candidatures: toutesCandidatures.filter(
          c => c.offre_id === o.id).length,
        nb_non_lues: toutesCandidatures.filter(
          c => c.offre_id === o.id && c.statut === 'en_attente').length,
      }));

    const stats = {
      offres_actives:          offresActives.length,
      offres_en_attente_valid: offresEnAttente.length,
      total_candidatures:      toutesCandidatures.length,
      candidatures_en_attente: candsEnAttente.length,
      vues_ce_mois:            vuesMois,
      taux_reponse:            tauxReponse,
      messages_non_lus:        nbMessagesNonLus || 0,
    };

    console.log('[dashboard] Stats calculées:', stats);

    return res.json({
      success: true,
      data: {
        stats,
        offres_actives:          offresActivesAvecStats,
        candidatures_recentes:   toutesCandidatures.slice(0, 5),
        candidatures_urgentes:   candidaturesUrgentes.slice(0, 3),
        entreprise: {
          id:   req.entreprise.id,
          nom:  req.entreprise.nom_entreprise,
          logo: req.entreprise.logo_url,
        },
      }
    });

  } catch (err) {
    console.error('[recruteur/dashboard] ERREUR:', err.message, err.stack);
    res.status(500).json({
      success: false,
      message: `Erreur serveur: ${err.message}`
    });
  }
});

module.exports = router;
```

---

## 3. Fix Backend — Route Mes Offres

### `backend/src/routes/recruteur/offres.routes.js` — GET corrigé

```javascript
// GET /api/recruteur/offres — Version robuste
router.get('/', async (req, res) => {
  try {
    const {
      page = 1, limite = 20,
      statut, recherche,
      ordre = 'date_creation', direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);
    const entrepriseId = req.entreprise.id;

    console.log('[recruteur/offres] entreprise_id:', entrepriseId,
      '| statut:', statut, '| recherche:', recherche);

    // Query principale
    let query = supabase
      .from('offres_emploi')
      .select(`
        id, titre, description, localisation, type_contrat,
        statut, nombre_postes, en_vedette, raison_refus,
        salaire_min, salaire_max, devise, domaine,
        niveau_experience_requis, competences_requises,
        nb_vues, date_publication, date_limite,
        date_creation, date_modification
      `, { count: 'exact' })
      .eq('entreprise_id', entrepriseId)
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (statut && statut !== 'all') {
      query = query.eq('statut', statut);
    }
    if (recherche) {
      query = query.ilike('titre', `%${recherche}%`);
    }

    const { data: offres, count, error } = await query;

    if (error) {
      console.error('[recruteur/offres GET] Erreur query:', error.message);
      throw error;
    }

    console.log('[recruteur/offres GET] Trouvées:', count,
      '| Retournées:', offres?.length);

    // Ajouter stats candidatures
    const offresIds = (offres || []).map(o => o.id);
    const candidaturesCount = {};
    const nonLuesCount = {};

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

    // Stats globales (toutes offres de cette entreprise)
    const { data: tousStatuts } = await supabase
      .from('offres_emploi')
      .select('statut')
      .eq('entreprise_id', entrepriseId);

    const statsStatuts = {
      total:      tousStatuts?.length || 0,
      publiees:   tousStatuts?.filter(o => o.statut === 'publiee').length || 0,
      en_attente: tousStatuts?.filter(o => o.statut === 'en_attente').length || 0,
      refusees:   tousStatuts?.filter(o => o.statut === 'refusee').length || 0,
      expirees:   tousStatuts?.filter(o => o.statut === 'expiree').length || 0,
      brouillons: tousStatuts?.filter(o => o.statut === 'brouillon').length || 0,
    };

    const offresEnrichies = (offres || []).map(o => ({
      ...o,
      nb_candidatures: candidaturesCount[o.id] || 0,
      nb_non_lues:     nonLuesCount[o.id] || 0,
    }));

    return res.json({
      success: true,
      data: {
        offres:     offresEnrichies,
        stats:      statsStatuts,
        pagination: {
          total:       count || 0,
          page:        parseInt(page),
          limite:      parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });

  } catch (err) {
    console.error('[recruteur/offres GET] ERREUR:', err.message);
    res.status(500).json({
      success: false,
      message: `Erreur: ${err.message}`
    });
  }
});

// POST /api/recruteur/offres — Créer une offre
router.post('/', async (req, res) => {
  try {
    const {
      titre, description, exigences,
      competences_requises, localisation,
      type_contrat, niveau_experience_requis,
      domaine, salaire_min, salaire_max, devise,
      nombre_postes, date_limite,
      publier_maintenant = true,
    } = req.body;

    // Validations strictes
    if (!titre?.trim()) {
      return res.status(400).json({
        success: false, message: 'Le titre est obligatoire'
      });
    }
    if (!description?.trim()) {
      return res.status(400).json({
        success: false, message: 'La description est obligatoire'
      });
    }
    if (!localisation?.trim()) {
      return res.status(400).json({
        success: false, message: 'La localisation est obligatoire'
      });
    }
    if (!type_contrat) {
      return res.status(400).json({
        success: false, message: 'Le type de contrat est obligatoire'
      });
    }

    // Vérifier limite offres gratuites (seulement pour publier)
    if (publier_maintenant) {
      const { data: paramLimite } = await supabase
        .from('parametres_plateforme')
        .select('valeur')
        .eq('cle', 'max_offres_gratuit')
        .single();

      const limite = parseInt(paramLimite?.valeur || '5');

      const { count: nbActives } = await supabase
        .from('offres_emploi')
        .select('id', { count: 'exact' })
        .eq('entreprise_id', req.entreprise.id)
        .in('statut', ['publiee', 'en_attente']);

      console.log('[recruteur/POST offre] Actives:', nbActives,
        '| Limite:', limite);

      if ((nbActives || 0) >= limite) {
        return res.status(403).json({
          success: false,
          message: `Limite atteinte (${limite} offres actives max).`,
          code: 'LIMITE_OFFRES'
        });
      }
    }

    // Date limite par défaut
    const { data: paramDuree } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'duree_validite_offre_jours')
      .single();

    const dureeJours = parseInt(paramDuree?.valeur || '30');
    const dateLimiteCalculee = new Date();
    dateLimiteCalculee.setDate(dateLimiteCalculee.getDate() + dureeJours);

    // Statut selon l'action
    // en_attente = soumise pour validation admin
    // brouillon = pas encore soumise
    const statut = publier_maintenant ? 'en_attente' : 'brouillon';

    const { data: nouvelleOffre, error } = await supabase
      .from('offres_emploi')
      .insert({
        entreprise_id:            req.entreprise.id,
        titre:                    titre.trim(),
        description:              description.trim(),
        exigences:                exigences?.trim() || '',
        competences_requises:     competences_requises || [],
        localisation:             localisation.trim(),
        type_contrat,
        niveau_experience_requis: niveau_experience_requis || 'sans_experience',
        domaine:                  domaine || 'Autre',
        salaire_min:              salaire_min || null,
        salaire_max:              salaire_max || null,
        devise:                   devise || 'GNF',
        nombre_postes:            nombre_postes || 1,
        date_limite: date_limite ||
          dateLimiteCalculee.toISOString(),
        statut,
        nb_vues:       0,
        date_creation: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) {
      console.error('[POST offre] Erreur insert:', error.message);
      throw error;
    }

    console.log('[POST offre] Créée avec succès:',
      nouvelleOffre.id, '| statut:', statut);

    // Enrichissement IA + notification admin en arrière-plan
    if (statut === 'en_attente') {
      setImmediate(async () => {
        // 1. Enrichir avec IA (mots-clés)
        try {
          const { extraireMotsCles } =
            require('../../services/ia.service');
          const texte = [titre, description, exigences]
            .filter(Boolean).join(' ');
          const motsCles = await extraireMotsCles(texte);

          if (motsCles.length > 0) {
            const compsExist = Array.isArray(competences_requises)
              ? competences_requises : [];
            const compsEnrichies = [
              ...new Set([...compsExist, ...motsCles])
            ].slice(0, 20);

            await supabase
              .from('offres_emploi')
              .update({ competences_requises: compsEnrichies })
              .eq('id', nouvelleOffre.id);

            console.log('[POST offre] Mots-clés IA ajoutés:',
              motsCles.length);
          }
        } catch (e) {
          console.warn('[POST offre] IA non bloquant:', e.message);
        }

        // 2. Notifier les admins
        try {
          const { notifNouvelleOffre } =
            require('../../services/auto_notification.service');
          await notifNouvelleOffre(
            nouvelleOffre, req.entreprise.nom_entreprise);
          console.log('[POST offre] Admins notifiés');
        } catch (e) {
          console.warn('[POST offre] Notif non bloquant:', e.message);
        }
      });
    }

    return res.status(201).json({
      success: true,
      message: publier_maintenant
        ? '✅ Offre soumise pour validation. Un admin va la vérifier.'
        : '✅ Brouillon sauvegardé.',
      data: nouvelleOffre
    });

  } catch (err) {
    console.error('[recruteur/offres POST] ERREUR:', err.message);
    res.status(500).json({
      success: false,
      message: `Erreur: ${err.message}`
    });
  }
});
```

---

## 4. Fix Backend — Route Candidatures

```javascript
// GET /api/recruteur/candidatures — Version robuste et corrigée

router.get('/', async (req, res) => {
  try {
    const {
      offre_id,    // OPTIONNEL — null = toutes les candidatures
      statut,
      recherche,
      page  = 1,
      limite = 50,
      vue   = 'liste',
    } = req.query;

    const entrepriseId = req.entreprise.id;

    // Récupérer les IDs des offres de cette entreprise
    const { data: mesOffres, error: offresErr } = await supabase
      .from('offres_emploi')
      .select('id, titre')
      .eq('entreprise_id', entrepriseId);

    if (offresErr) throw offresErr;

    const mesOffresIds = (mesOffres || []).map(o => o.id);

    console.log('[recruteur/candidatures] Nb offres:',
      mesOffresIds.length, '| offre_id filtre:', offre_id);

    if (mesOffresIds.length === 0) {
      return res.json({
        success: true,
        data: {
          candidatures: [],
          stats: {
            total: 0, en_attente: 0, en_cours: 0,
            entretien: 0, acceptees: 0, refusees: 0,
          },
          kanban: null,
        }
      });
    }

    // Vérifier que offre_id appartient bien à cette entreprise
    let offresIdsFiltre = mesOffresIds;
    if (offre_id) {
      if (!mesOffresIds.includes(offre_id)) {
        return res.status(403).json({
          success: false,
          message: 'Cette offre ne vous appartient pas'
        });
      }
      offresIdsFiltre = [offre_id];
    }

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite,
        date_candidature, date_modification,
        lettre_motivation, offre_id,
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
      .in('offre_id', offresIdsFiltre)
      .order('date_candidature', { ascending: false })
      .range(offset, offset + parseInt(limite) - 1);

    if (statut) query = query.eq('statut', statut);

    const { data: allCands, count, error } = await query;

    if (error) {
      console.error('[candidatures] Erreur query:', error.message);
      throw error;
    }

    let candidatures = allCands || [];

    // Filtre recherche post-requête
    if (recherche) {
      const r = recherche.toLowerCase();
      candidatures = candidatures.filter(c =>
        c.chercheur?.utilisateur?.nom
          ?.toLowerCase().includes(r) ||
        c.chercheur?.utilisateur?.email
          ?.toLowerCase().includes(r)
      );
    }

    console.log('[candidatures] Trouvées:', count,
      '| Filtrées:', candidatures.length);

    // Stats globales pour TOUTES les offres
    const { data: tousStatuts } = await supabase
      .from('candidatures')
      .select('statut')
      .in('offre_id', mesOffresIds);

    const stats = {
      total:      tousStatuts?.length || 0,
      en_attente: tousStatuts?.filter(c =>
        c.statut === 'en_attente').length || 0,
      en_cours:   tousStatuts?.filter(c =>
        c.statut === 'en_cours').length || 0,
      entretien:  tousStatuts?.filter(c =>
        c.statut === 'entretien').length || 0,
      acceptees:  tousStatuts?.filter(c =>
        c.statut === 'acceptee').length || 0,
      refusees:   tousStatuts?.filter(c =>
        c.statut === 'refusee').length || 0,
    };

    // Format kanban
    let kanban = null;
    if (vue === 'kanban') {
      kanban = {
        en_attente: candidatures.filter(c =>
          c.statut === 'en_attente'),
        en_cours:   candidatures.filter(c =>
          c.statut === 'en_cours'),
        entretien:  candidatures.filter(c =>
          c.statut === 'entretien'),
        acceptees:  candidatures.filter(c =>
          c.statut === 'acceptee'),
        refusees:   candidatures.filter(c =>
          c.statut === 'refusee'),
      };
    }

    return res.json({
      success: true,
      data: {
        candidatures,
        stats,
        kanban,
        pagination: {
          total:       count || 0,
          page:        parseInt(page),
          limite:      parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });

  } catch (err) {
    console.error('[recruteur/candidatures GET] ERREUR:', err.message);
    res.status(500).json({
      success: false,
      message: `Erreur: ${err.message}`
    });
  }
});
```

---

## 5. Fix Backend — Route Talents

```javascript
// GET /api/recruteur/talents — Vrais talents depuis la BDD

router.get('/', async (req, res) => {
  try {
    const {
      recherche,
      niveau_etude,
      disponibilite,
      ville,
      offre_id,
      page  = 1,
      limite = 20,
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    console.log('[recruteur/talents] Recherche:', recherche,
      '| offre_id:', offre_id);

    // Récupérer les chercheurs d'emploi avec leur profil
    let query = supabase
      .from('chercheurs_emploi')
      .select(`
        id, competences, niveau_etude, disponibilite, genre,
        utilisateur:utilisateur_id (
          id, nom, email, photo_url, adresse,
          est_actif, est_valide, date_creation
        )
      `, { count: 'exact' })
      .range(offset, offset + parseInt(limite) - 1);

    if (niveau_etude)  query = query.eq('niveau_etude', niveau_etude);
    if (disponibilite) query = query.eq('disponibilite', disponibilite);

    const { data: chercheurs, count, error } = await query;

    if (error) {
      console.error('[talents] Erreur query:', error.message);
      throw error;
    }

    // Filtrer : uniquement comptes actifs et validés
    let talents = (chercheurs || []).filter(c =>
      c.utilisateur?.est_actif === true &&
      c.utilisateur?.est_valide === true
    );

    // Filtre ville
    if (ville) {
      talents = talents.filter(t =>
        t.utilisateur?.adresse?.toLowerCase()
          .includes(ville.toLowerCase())
      );
    }

    // Filtre recherche sur les compétences
    if (recherche) {
      const r = recherche.toLowerCase();
      talents = talents.filter(t => {
        const comps = Array.isArray(t.competences)
          ? t.competences
          : Object.values(t.competences || {});
        const nomMatch = t.utilisateur?.nom?.toLowerCase()
          .includes(r);
        const compMatch = comps.some(c =>
          c.toString().toLowerCase().includes(r));
        return nomMatch || compMatch;
      });
    }

    // Récupérer les CVs pour avoir les compétences extraites par IA
    const chercheurIds = talents.map(t => t.id);
    let cvMap = {};
    if (chercheurIds.length > 0) {
      const { data: cvs } = await supabase
        .from('cv')
        .select(`
          chercheur_id, fichier_url, nom_fichier,
          competences_extrait, niveau_experience
        `)
        .in('chercheur_id', chercheurIds);

      (cvs || []).forEach(cv => {
        cvMap[cv.chercheur_id] = cv;
      });
    }

    // Calculer scores IA si une offre est fournie
    let offre = null;
    if (offre_id) {
      const { data: offreData } = await supabase
        .from('offres_emploi')
        .select(`
          titre, description, exigences,
          competences_requises, localisation,
          niveau_experience_requis
        `)
        .eq('id', offre_id)
        .eq('entreprise_id', req.entreprise.id)
        .single();

      offre = offreData;
    }

    // Enrichir chaque talent avec CV et score IA
    let { calculerMatchingScore } = { calculerMatchingScore: null };
    try {
      const iaModule = require('../../services/ia.service');
      calculerMatchingScore = iaModule.calculerMatchingScore;
    } catch (e) {
      console.warn('[talents] IA service non disponible');
    }

    const talentsEnrichis = await Promise.all(
      talents.map(async (t) => {
        const cv = cvMap[t.id];
        const compsCV = cv?.competences_extrait?.competences || [];
        const compsProfil = Array.isArray(t.competences)
          ? t.competences
          : Object.values(t.competences || {});

        let scoreMatching = null;

        if (offre && calculerMatchingScore) {
          try {
            scoreMatching = await calculerMatchingScore(
              {
                competences: [...compsCV, ...compsProfil],
                texte_cv:    '',
                ville:       t.utilisateur?.adresse || '',
                annees_experience: 0,
              },
              offre
            );
          } catch (e) {
            console.warn('[talents] Score IA échoué:', e.message);
          }
        }

        return {
          ...t,
          cv: cv ? {
            fichier_url: cv.fichier_url,
            nom_fichier: cv.nom_fichier,
            niveau_experience: cv.niveau_experience,
            competences_extrait: cv.competences_extrait,
          } : null,
          score_matching: scoreMatching,
          toutes_competences: [...new Set([...compsCV, ...compsProfil])],
        };
      })
    );

    // Trier par score si disponible
    if (offre_id) {
      talentsEnrichis.sort((a, b) =>
        (b.score_matching || 0) - (a.score_matching || 0));
    }

    console.log('[talents] Retournés:', talentsEnrichis.length);

    return res.json({
      success: true,
      data: {
        talents: talentsEnrichis,
        pagination: {
          total:       count || 0,
          page:        parseInt(page),
          limite:      parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });

  } catch (err) {
    console.error('[recruteur/talents GET] ERREUR:', err.message);
    res.status(500).json({
      success: false,
      message: `Erreur: ${err.message}`
    });
  }
});
```

---

## 6. Fix Backend — Route Profil Entreprise

```javascript
// GET /api/recruteur/profil — Retourner toutes les infos

router.get('/', async (req, res) => {
  try {
    const { data: entreprise, error } = await supabase
      .from('entreprises')
      .select(`
        id, nom_entreprise, description, secteur_activite,
        taille_entreprise, site_web, logo_url, adresse_siege,
        date_creation,
        utilisateur:utilisateur_id (
          id, nom, email, telephone, adresse, photo_url,
          est_actif, est_valide, date_creation, derniere_connexion
        )
      `)
      .eq('utilisateur_id', req.user.id)
      .single();

    if (error || !entreprise) {
      console.error('[recruteur/profil GET] Non trouvé pour user:',
        req.user.id);
      return res.status(404).json({
        success: false,
        message: 'Profil entreprise non trouvé'
      });
    }

    // Stats
    const { count: nbOffres } = await supabase
      .from('offres_emploi')
      .select('id', { count: 'exact' })
      .eq('entreprise_id', entreprise.id);

    const { count: nbCandidatures } = await supabase
      .from('candidatures')
      .select('id', { count: 'exact' })
      .in('offre_id',
        (await supabase.from('offres_emploi')
          .select('id')
          .eq('entreprise_id', entreprise.id)
        ).data?.map(o => o.id) || []
      );

    return res.json({
      success: true,
      data: {
        ...entreprise,
        stats: {
          nb_offres:       nbOffres       || 0,
          nb_candidatures: nbCandidatures || 0,
        }
      }
    });

  } catch (err) {
    console.error('[recruteur/profil GET] ERREUR:', err.message);
    res.status(500).json({
      success: false,
      message: `Erreur: ${err.message}`
    });
  }
});

// POST /api/recruteur/profil/logo — Upload logo entreprise
router.post('/logo',
  uploadLogo.single('logo'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'Aucun fichier fourni'
        });
      }

      const mime = req.file.mimetype.toLowerCase();
      let buffer = req.file.buffer;
      let mimeType = 'image/png';

      // Redimensionner via sharp
      try {
        const sharp = require('sharp');
        buffer = await sharp(req.file.buffer)
          .resize(400, 400, { fit: 'cover', position: 'centre' })
          .png({ quality: 85 })
          .toBuffer();
      } catch (sharpErr) {
        console.warn('[logo] Sharp non dispo, upload direct');
        mimeType = mime;
      }

      const bucket   = process.env.SUPABASE_LOGOS_BUCKET || 'logos';
      const fileName =
        `logo-entreprise-${req.entreprise.id}-${Date.now()}.png`;

      const { error: uploadErr } = await supabase.storage
        .from(bucket)
        .upload(fileName, buffer, {
          contentType: mimeType,
          upsert: true,
        });

      if (uploadErr) {
        console.error('[logo] Supabase upload error:', uploadErr.message);
        return res.status(500).json({
          success: false,
          message: `Erreur Storage: ${uploadErr.message}. ` +
            'Vérifiez que le bucket "logos" existe et est public.'
        });
      }

      const { data: urlData } = supabase.storage
        .from(bucket).getPublicUrl(fileName);
      const logoUrl = urlData.publicUrl;

      // Mettre à jour en BDD
      await supabase
        .from('entreprises')
        .update({ logo_url: logoUrl })
        .eq('utilisateur_id', req.user.id);

      console.log('[logo] Mis à jour:', logoUrl);

      return res.json({
        success: true,
        message: 'Logo mis à jour avec succès',
        data: { logo_url: logoUrl }
      });

    } catch (err) {
      console.error('[recruteur/logo] ERREUR:', err.message);
      res.status(500).json({
        success: false,
        message: err.message || 'Erreur upload'
      });
    }
  }
);

// POST /api/recruteur/profil/banniere — Upload bannière entreprise
const uploadBanniere = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowed.includes(file.mimetype.toLowerCase())) cb(null, true);
    else cb(new Error('Format non supporté: JPG, PNG, WEBP'));
  },
});

router.post('/banniere',
  uploadBanniere.single('banniere'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false, message: 'Aucun fichier fourni'
        });
      }

      let buffer = req.file.buffer;
      try {
        const sharp = require('sharp');
        buffer = await sharp(req.file.buffer)
          .resize(1200, 400, { fit: 'cover', position: 'centre' })
          .jpeg({ quality: 85 })
          .toBuffer();
      } catch (e) {
        console.warn('[banniere] Sharp non dispo');
      }

      const bucket   = process.env.SUPABASE_BANNIERES_BUCKET || 'bannieres';
      const fileName =
        `banniere-entreprise-${req.entreprise.id}-${Date.now()}.jpg`;

      const { error: uploadErr } = await supabase.storage
        .from(bucket)
        .upload(fileName, buffer, {
          contentType: 'image/jpeg', upsert: true
        });

      if (uploadErr) {
        return res.status(500).json({
          success: false,
          message: `Erreur Storage: ${uploadErr.message}`
        });
      }

      const { data: urlData } = supabase.storage
        .from(bucket).getPublicUrl(fileName);
      const banniereUrl = urlData.publicUrl;

      // Stocker dans un champ banniere_url (ajouter si pas existe)
      await supabase
        .from('entreprises')
        .update({ banniere_url: banniereUrl })
        .eq('utilisateur_id', req.user.id);

      return res.json({
        success: true,
        message: 'Bannière mise à jour',
        data: { banniere_url: banniereUrl }
      });

    } catch (err) {
      console.error('[recruteur/banniere] ERREUR:', err.message);
      res.status(500).json({
        success: false, message: err.message
      });
    }
  }
);
```

---

## 7. Fix Flutter — RecruteurProvider corrigé

```dart
// lib/providers/recruteur_provider.dart — VERSION CORRIGÉE

class RecruteurProvider extends ChangeNotifier {
  final RecruteurService _svc = RecruteurService();

  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? profil;

  int nbOffresActives      = 0;
  int nbCandidatures       = 0;
  int nbCandidEnAttente    = 0;
  int nbMessagesNonLus     = 0;
  int nbNotificationsNonLues = 0;

  bool isLoading = false;
  bool isLoaded  = false;
  String? error;

  Future<void> loadAll(String token) async {
    if (token.isEmpty) {
      error = 'Token manquant';
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Charger dashboard et profil en parallèle
      final results = await Future.wait([
        _svc.getDashboard(token).catchError((e) {
          print('[RecruteurProvider] Dashboard erreur: $e');
          return <String, dynamic>{'success': false, 'data': {}};
        }),
        _svc.getProfil(token).catchError((e) {
          print('[RecruteurProvider] Profil erreur: $e');
          return <String, dynamic>{'success': false, 'data': {}};
        }),
        _svc.getNotifications(token).catchError((e) {
          print('[RecruteurProvider] Notifs erreur: $e');
          return <String, dynamic>{'success': false, 'data': {}};
        }),
      ]);

      final dashRes  = results[0];
      final profilRes = results[1];
      final notifRes = results[2];

      // Dashboard
      if (dashRes['success'] == true) {
        final data  = dashRes['data'] as Map<String, dynamic>? ?? {};
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        dashboardData        = data;
        nbOffresActives      = stats['offres_actives']          ?? 0;
        nbCandidatures       = stats['total_candidatures']      ?? 0;
        nbCandidEnAttente    = stats['candidatures_en_attente'] ?? 0;
        nbMessagesNonLus     = stats['messages_non_lus']        ?? 0;
        print('[RecruteurProvider] Stats: $stats');
      } else {
        print('[RecruteurProvider] Dashboard failed: ${dashRes['message']}');
      }

      // Profil
      if (profilRes['success'] == true) {
        profil = profilRes['data'] as Map<String, dynamic>?;
      }

      // Notifications
      if (notifRes['success'] == true) {
        final notifData = notifRes['data'] as Map<String, dynamic>? ?? {};
        nbNotificationsNonLues = notifData['nb_non_lues'] ?? 0;
      }

      isLoaded = true;

    } catch (e) {
      error = e.toString();
      print('[RecruteurProvider] Erreur globale: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String token) async {
    isLoaded = false;
    await loadAll(token);
  }

  void updateNbMessages(int n) {
    nbMessagesNonLus = n;
    notifyListeners();
  }

  void updateNbNotifications(int n) {
    nbNotificationsNonLues = n;
    notifyListeners();
  }

  void updateProfil(Map<String, dynamic> data) {
    profil = { ...?profil, ...data };
    notifyListeners();
  }
}
```

---

## 8. Fix Flutter — Vue d'ensemble corrigée

```dart
// Dans recruteur_shell.dart — S'assurer que loadAll est appelé
// avec le BON token

class _RecruteurShellState extends State<RecruteurShell> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Charger après le premier frame (context disponible)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token ?? '';

    print('[RecruteurShell] Initialisation avec token:',
      token.isNotEmpty ? 'PRÉSENT (${token.length} chars)' : 'ABSENT');

    if (token.isEmpty) {
      // Pas de token → rediriger vers connexion
      if (mounted) context.go('/connexion');
      return;
    }

    await context.read<RecruteurProvider>().loadAll(token);
  }
}

// Dans recruteur_dashboard_page.dart — Utiliser le Provider
// au lieu de charger manuellement

class _RecruteurDashboardPageState extends State<RecruteurDashboardPage> {

  @override
  Widget build(BuildContext context) {
    // Écouter le Provider
    final provider = context.watch<RecruteurProvider>();

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1A56DB)),
            SizedBox(height: 12),
            Text('Chargement du tableau de bord...'),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
              color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text('Erreur: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final token = context.read<AuthProvider>().token ?? '';
                context.read<RecruteurProvider>().loadAll(token);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final data      = provider.dashboardData ?? {};
    final stats     = data['stats'] as Map<String, dynamic>? ?? {};
    final offres    = List<Map<String, dynamic>>.from(
      data['offres_actives'] ?? []);
    final cands     = List<Map<String, dynamic>>.from(
      data['candidatures_recentes'] ?? []);
    final urgentes  = List<Map<String, dynamic>>.from(
      data['candidatures_urgentes'] ?? []);
    final entreprise = data['entreprise'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: () async {
        final token = context.read<AuthProvider>().token ?? '';
        await context.read<RecruteurProvider>().loadAll(token);
      },
      color: const Color(0xFF1A56DB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Bienvenue
            _buildWelcome(entreprise, urgentes),
            const SizedBox(height: 20),

            // Stat cards avec VRAIES valeurs
            _buildStatsGrid(stats),
            const SizedBox(height: 24),

            // Alerte urgente
            if (urgentes.isNotEmpty) ...[
              _buildUrgentAlert(urgentes),
              const SizedBox(height: 20),
            ],

            // Candidatures récentes avec vraies données
            _buildCandidaturesSection(cands),
            const SizedBox(height: 24),

            // Offres actives avec vraies données
            _buildOffresSection(offres),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    // Ces valeurs viennent directement de l'API
    final offrActives = stats['offres_actives'] ?? 0;
    final totalCands  = stats['total_candidatures'] ?? 0;
    final vuesMois    = stats['vues_ce_mois'] ?? 0;
    final tauxRep     = stats['taux_reponse'] ?? 0;

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth < 600 ? 2 : 4;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14, mainAxisSpacing: 14,
        childAspectRatio: c.maxWidth < 600 ? 1.5 : 2.0,
        children: [
          _StatCard(
            label: 'Offres actives',
            value: '$offrActives',
            icon:  Icons.work_rounded,
            color: const Color(0xFF1A56DB),
            bg:    const Color(0xFFEFF6FF),
          ),
          _StatCard(
            label: 'Candidatures',
            value: '$totalCands',
            icon:  Icons.people_rounded,
            color: const Color(0xFF10B981),
            bg:    const Color(0xFFECFDF5),
          ),
          _StatCard(
            label: 'Vues ce mois',
            value: '$vuesMois',
            icon:  Icons.visibility_rounded,
            color: const Color(0xFF8B5CF6),
            bg:    const Color(0xFFF5F3FF),
          ),
          _StatCard(
            label: 'Taux réponse',
            value: '$tauxRep%',
            icon:  Icons.star_rounded,
            color: const Color(0xFFF59E0B),
            bg:    const Color(0xFFFEF3C7),
          ),
        ],
      );
    });
  }
}
```

---

## 9. Fix Flutter — Page Mes Offres corrigée

```dart
// Dans mes_offres_page.dart
// S'assurer que le service est appelé correctement

class _MesOffresPageState extends State<MesOffresPage> {
  final RecruteurService _svc = RecruteurService();

  Future<void> _loadOffres() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';

      if (token.isEmpty) {
        setState(() {
          _error = 'Session expirée. Reconnectez-vous.';
          _isLoading = false;
        });
        return;
      }

      final res = await _svc.getOffres(
        token,
        statut:    _selectedStatut == 'all' ? null : _selectedStatut,
        recherche: _recherche.isNotEmpty ? _recherche : null,
        page:      _currentPage,
        limite:    20,
      );

      if (res['success'] == true) {
        setState(() {
          _offres = List<Map<String, dynamic>>.from(
            res['data']?['offres'] ?? []);
          _stats  = res['data']?['stats']
              as Map<String, dynamic>? ?? {};
          _isLoading = false;
          _error = null;
        });

        print('[MesOffres] Chargées: ${_offres.length}'
          ' | stats: $_stats');
      } else {
        setState(() {
          _error = res['message'] ?? 'Erreur inconnue';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('[MesOffres] ERREUR: $e');
    }
  }
}

// Dans la OffreCard — afficher le VRAI statut
// Remplacer tous les badges hardcodés par StatusBadge(label: offre['statut'])

Widget _buildOffreCard(Map<String, dynamic> offre) {
  return Container(
    // ...
    child: Column(children: [
      Row(children: [
        // Badge statut dynamique
        StatusBadge(label: offre['statut'] ?? 'brouillon'),

        // Badge vedette si applicable
        if (offre['en_vedette'] == true) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(100)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded,
                size: 12, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text('En vedette', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E))),
            ]),
          ),
        ],

        // Si refusée → afficher le motif
        if (offre['statut'] == 'refusee' &&
            offre['raison_refus'] != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: offre['raison_refus'],
            child: const Icon(Icons.info_outline,
              size: 16, color: Color(0xFFEF4444)),
          ),
        ],
      ]),
      // ... reste de la card
    ]),
  );
}
```

---

## 10. Fix Flutter — Page Candidatures corrigée

```dart
// Fix principal : le paramètre offre_id est OPTIONNEL
// Ne JAMAIS envoyer offre_id = 'null' comme string

class CandidaturesPage extends StatefulWidget {
  final String? offreId; // PEUT être null

  const CandidaturesPage({super.key, this.offreId});
  @override
  State<CandidaturesPage> createState() => _CandidaturesPageState();
}

// Dans RecruteurService.getCandidatures() :
Future<Map<String, dynamic>> getCandidatures(
  String token, {
  String? offreId,   // null = toutes
  String? statut,
  String? recherche,
  String vue = 'liste',
  int page = 1, int limite = 50,
}) async {
  final params = <String, String>{
    'vue':    vue,
    'page':   '$page',
    'limite': '$limite',
    // ⚠️ N'ajouter offre_id QUE si non null ET non vide
    if (offreId != null && offreId.isNotEmpty)
      'offre_id': offreId,
    if (statut != null && statut.isNotEmpty)
      'statut': statut,
    if (recherche != null && recherche.isNotEmpty)
      'recherche': recherche,
  };

  final uri = Uri.parse('$_base/candidatures')
      .replace(queryParameters: params);

  print('[RecruteurService] getCandidatures URL: $uri');

  final res = await http.get(uri, headers: _headers(token));
  return _handle(res);
}
```

---

## 11. Fix Flutter — Page Profil avec Upload

```dart
// Dans profil_entreprise_page.dart
// Upload logo ET bannière via ImageUploadWidget (pas champ URL)

class _ProfilEntreprisePageState extends State<ProfilEntreprisePage> {

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [

        // ── Section Bannière ──────────────────────────────
        _buildBanniereSection(),
        const SizedBox(height: 20),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Logo + Stats
          Expanded(flex: 35, child: Column(children: [
            _buildLogoSection(),
            const SizedBox(height: 16),
            _buildStatsCard(),
          ])),
          const SizedBox(width: 20),

          // Formulaire
          Expanded(flex: 65, child: Column(children: [
            _buildFormulaireCard(),
            const SizedBox(height: 16),
            _buildSaveButton(),
          ])),
        ]),
      ]),
    );
  }

  // Section bannière avec upload
  Widget _buildBanniereSection() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Bannière de l\'entreprise',
        style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 12),

      // Aperçu bannière actuelle
      if (_profil?['banniere_url'] != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _profil!['banniere_url'],
            height: 120, width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
              Container(height: 120, color: const Color(0xFFF1F5F9),
                child: const Center(child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFF94A3B8)))),
          ),
        ),
        const SizedBox(height: 12),
      ],

      // Widget upload bannière
      ImageUploadWidget(
        currentImageUrl: _profil?['banniere_url'],
        uploadUrl:
          '${ApiConfig.baseUrl}/api/recruteur/profil/banniere',
        fieldName: 'banniere',
        title: 'bannière d\'entreprise',
        dimensionsInfo: '1200 × 400 px (3:1)',
        acceptedFormats: 'JPG, PNG, WEBP',
        maxSizeMb: 10,
        previewHeight: 80,
        onUploaded: (url) {
          setState(() =>
            _profil = { ...?_profil, 'banniere_url': url });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bannière mise à jour !'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating));
        },
      ),
    ]),
  );

  // Section logo avec upload
  Widget _buildLogoSection() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(children: [
      Text('Logo de l\'entreprise',
        style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 16),

      // Widget upload logo
      ImageUploadWidget(
        currentImageUrl: _profil?['logo_url'],
        uploadUrl:
          '${ApiConfig.baseUrl}/api/recruteur/profil/logo',
        fieldName: 'logo',
        title: 'logo entreprise',
        dimensionsInfo: '400 × 400 px (carré)',
        acceptedFormats: 'PNG, JPG, WEBP',
        maxSizeMb: 3,
        previewHeight: 80,
        onUploaded: (url) {
          setState(() =>
            _profil = { ...?_profil, 'logo_url': url });
          // Mettre à jour le Provider (sidebar)
          context.read<RecruteurProvider>()
            .updateProfil({'logo_url': url});
        },
      ),
    ]),
  );
}
```

---

## 12. Notifications Recruteur — Flux complet

### Quand le recruteur doit recevoir une notification ?

```javascript
// backend/src/controllers/admin/offres.controller.js
// Après validation/refus d'une offre par l'admin → notifier le recruteur

// Ajouter dans updateOffre() APRÈS le UPDATE Supabase réussi :

const _notifierRecruteur = async (
  offreId, entrepriseId, action, raisonRefus, supabase
) => {
  try {
    // Récupérer l'utilisateur_id du recruteur
    const { data: entreprise } = await supabase
      .from('entreprises')
      .select('utilisateur_id, nom_entreprise')
      .eq('id', entrepriseId)
      .single();

    if (!entreprise?.utilisateur_id) return;

    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('titre')
      .eq('id', offreId)
      .single();

    let titre   = '';
    let message = '';
    let lien    = '/dashboard-recruteur/offres';

    switch (action) {
      case 'valider':
        titre   = '✅ Votre offre a été validée !';
        message = `Votre offre "${offre?.titre}" est maintenant `
          + 'publiée et visible par les candidats.';
        break;
      case 'refuser':
        titre   = '❌ Votre offre a été refusée';
        message = `Votre offre "${offre?.titre}" a été refusée.`
          + (raisonRefus ? ` Motif : ${raisonRefus}` : '');
        break;
      case 'mettre_en_vedette':
        titre   = '⭐ Votre offre est mise en vedette !';
        message = `Votre offre "${offre?.titre}" est maintenant `
          + 'mise en avant sur la plateforme.';
        break;
    }

    if (titre) {
      await supabase.from('notifications').insert({
        destinataire_id:   entreprise.utilisateur_id,
        type_destinataire: 'individuel',
        titre,
        message,
        type: 'offre',
        lien,
      });
      console.log('[notifRecruteur]', titre);
    }
  } catch (e) {
    console.warn('[notifRecruteur] Non bloquant:', e.message);
  }
};

// Dans updateOffre(), après le update Supabase :
if (['valider', 'refuser', 'mettre_en_vedette'].includes(action)) {
  setImmediate(() => _notifierRecruteur(
    id,
    offreActuelle.entreprise_id,
    action,
    raison_refus,
    supabase
  ));
}
```

### Migration SQL pour bannière entreprise

```sql
-- Ajouter la colonne banniere_url dans entreprises
-- Exécuter dans Supabase SQL Editor :

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS banniere_url TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS slogan VARCHAR(280);

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS linkedin_url TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS facebook_url TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS valeurs JSONB;
  -- ex: ["Innovation", "Intégrité", "Excellence"]
```

---

## 13. Tests de validation

### `backend/tests/recruteur_fix.test.http`

```http
### Variables
@base = http://localhost:3000/api
@token = VOTRE_JWT_RECRUTEUR

### TEST 1 — Dashboard (doit retourner de vraies stats)
GET {{base}}/recruteur/dashboard
Authorization: Bearer {{token}}
# Vérifier : stats.offres_actives > 0 si des offres existent

###

### TEST 2 — Mes offres (doit retourner les offres avec statut réel)
GET {{base}}/recruteur/offres
Authorization: Bearer {{token}}
# Vérifier : chaque offre a un statut réel (en_attente, publiee, etc.)

###

### TEST 3 — Candidatures SANS offre_id (ne doit PAS planter)
GET {{base}}/recruteur/candidatures
Authorization: Bearer {{token}}
# Avant : "offre_id est requis" ❌
# Après : liste des candidatures ✅

###

### TEST 4 — Candidatures AVEC offre_id
GET {{base}}/recruteur/candidatures?offre_id=UUID_OFFRE_ICI
Authorization: Bearer {{token}}
# Vérifier : candidatures filtrées pour cette offre

###

### TEST 5 — Talents (vrais candidats)
GET {{base}}/recruteur/talents
Authorization: Bearer {{token}}
# Vérifier : vrais noms de candidats inscrits

###

### TEST 6 — Talents avec score IA
GET {{base}}/recruteur/talents?offre_id=UUID_OFFRE_ICI
Authorization: Bearer {{token}}
# Vérifier : score_matching calculé pour chaque talent

###

### TEST 7 — Profil entreprise
GET {{base}}/recruteur/profil
Authorization: Bearer {{token}}
# Vérifier : données réelles de l'entreprise

###

### TEST 8 — Créer une offre
POST {{base}}/recruteur/offres
Authorization: Bearer {{token}}
Content-Type: application/json

{
  "titre": "Développeur Mobile Flutter",
  "description": "Nous recherchons un développeur Flutter pour rejoindre notre équipe.",
  "localisation": "Conakry",
  "type_contrat": "CDI",
  "publier_maintenant": true
}
# Vérifier : offre créée avec statut 'en_attente'
# Vérifier : notification reçue dans l'admin

###
```

---

## 14. Critères d'Acceptation

### ✅ Vue d'ensemble
- [ ] Stats cards affichent les VRAIES valeurs (pas zéro)
- [ ] `offres_actives` = nb offres avec statut 'publiee' en BDD
- [ ] `total_candidatures` = nb candidatures pour les offres de cette entreprise
- [ ] `vues_ce_mois` = vraies vues des 30 derniers jours
- [ ] `taux_reponse` = calculé depuis les candidatures traitées
- [ ] Pull-to-refresh recharge les vraies données
- [ ] Alerte jaune si candidatures urgentes (>7j sans réponse)

### ✅ Mes Offres
- [ ] Liste les offres RÉELLES de cette entreprise
- [ ] Badge statut dynamique : orange "En attente", vert "Publiée", rouge "Refusée"
- [ ] Nb candidatures et nb vues par offre : données réelles
- [ ] Tabs avec compteurs réels (Toutes/Actives/En attente/Expirées/Brouillons)
- [ ] Si offre refusée → motif visible au hover

### ✅ Candidatures
- [ ] Erreur "offre_id requis" CORRIGÉE — offre_id optionnel
- [ ] Affiche TOUTES les candidatures si pas de filtre
- [ ] Filtre par statut avec compteurs réels
- [ ] Actions (examiner/entretien/accepter/refuser) envoient notification au candidat

### ✅ Talents
- [ ] Affiche de VRAIS candidats inscrits (pas de noms fictifs)
- [ ] Score IA calculé si une offre est sélectionnée
- [ ] Filtre par compétence, disponibilité, ville fonctionnel

### ✅ Profil Entreprise
- [ ] Upload logo depuis gestionnaire de fichiers (pas champ URL)
- [ ] Upload bannière avec dimensions "1200 × 400px"
- [ ] Sauvegarde met à jour la BDD
- [ ] Logo mis à jour dans la sidebar instantanément

### ✅ Notifications Recruteur
- [ ] Notification reçue quand l'admin valide une offre
- [ ] Notification reçue quand l'admin refuse une offre (avec motif)
- [ ] Notification reçue quand une candidature change de statut
- [ ] Badge notifications mis à jour en temps réel

### ✅ Cohérence Admin ↔ Recruteur
- [ ] Offre créée par recruteur → statut 'en_attente' partout
- [ ] Offre validée par admin → statut 'publiee' partout + notif recruteur
- [ ] Offre refusée par admin → statut 'refusee' partout + notif recruteur avec motif
- [ ] Candidature acceptée → candidat notifié + recruteur voit le statut mis à jour

---

*PRD EmploiConnect v5.2 — Fix & Complétion Backend Recruteur*
*Cursor / Kirsoft AI — Phase 9.2*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
