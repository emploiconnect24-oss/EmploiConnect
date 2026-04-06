# PRD — EmploiConnect · Espace Candidat — Fix Complet & Cohérence
## Product Requirements Document v6.0 — Candidat Space Complete Fix
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Objectif : Corriger TOUS les bugs + Design + Backend espace candidat**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> Ce PRD corrige l'espace candidat de A à Z.
> Priorités dans l'ordre :
> 1. Fix upload photo + CV (formats non supportés)
> 2. Fix cohérence scores IA (0% partout ou valeurs incohérentes)
> 3. Fix complétion profil (% incohérents)
> 4. Mes candidatures + Offres sauvegardées
> 5. Alertes emploi
> 6. Messagerie temps réel
> 7. Notifications
> 8. Paramètres
> 9. Design global (espacement, cartes offres)

---

## Table des Matières

1. [Fix Upload Photo & CV](#1-fix-upload-photo--cv)
2. [Fix Cohérence Scores IA](#2-fix-cohérence-scores-ia)
3. [Fix Complétion Profil](#3-fix-complétion-profil)
4. [Backend — Mes Candidatures](#4-backend--mes-candidatures)
5. [Backend — Offres Sauvegardées](#5-backend--offres-sauvegardées)
6. [Backend — Alertes Emploi](#6-backend--alertes-emploi)
7. [Backend — Messagerie Temps Réel](#7-backend--messagerie-temps-réel)
8. [Backend — Notifications Candidat](#8-backend--notifications-candidat)
9. [Backend — Paramètres Candidat](#9-backend--paramètres-candidat)
10. [Flutter — Design Global Candidat](#10-flutter--design-global-candidat)
11. [Flutter — Cartes Offres Compactes](#11-flutter--cartes-offres-compactes)
12. [Flutter — Mes Candidatures](#12-flutter--mes-candidatures)
13. [Flutter — Messagerie Candidat](#13-flutter--messagerie-candidat)
14. [Flutter — Notifications Candidat](#14-flutter--notifications-candidat)
15. [Flutter — Paramètres Candidat](#15-flutter--paramètres-candidat)
16. [Critères d'Acceptation](#16-critères-dacceptation)

---

## 1. Fix Upload Photo & CV

### 1.1 Problème identifié
```
Erreur : "Format image non supporté" et "Format non accepté"
Cause : Le backend multer a une liste de MIME types trop restrictive
         et ne reconnaît pas correctement certains formats mobile.
```

### 1.2 Fix Backend — Upload Photo

```javascript
// Dans backend/src/routes/users.routes.js ou profil.routes.js
// Remplacer la configuration multer pour la photo de profil

const multerPhoto = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    // Normaliser le mime type en minuscules
    const mime = (file.mimetype || '').toLowerCase();

    // Accepter TOUS les formats d'image courants
    const formatsAcceptes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'image/gif',
      'image/heic',   // iPhone
      'image/heif',   // iPhone
      'image/bmp',
      // Certains appareils mobiles envoient des mimes non standard
      'application/octet-stream', // fallback générique
    ];

    // Vérifier aussi l'extension du fichier si le mime est inconnu
    const ext = (file.originalname || '').toLowerCase().split('.').pop();
    const extsAcceptees = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'];

    if (formatsAcceptes.includes(mime) ||
        extsAcceptees.includes(ext)) {
      cb(null, true);
    } else {
      console.warn('[uploadPhoto] Format rejeté:', mime, ext);
      // NE PAS rejeter — laisser passer et essayer
      cb(null, true);
    }
  },
});

// Route upload photo profil
router.post('/photo', auth, multerPhoto.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier reçu'
      });
    }

    console.log('[uploadPhoto] Fichier reçu:', {
      originalname: req.file.originalname,
      mimetype:     req.file.mimetype,
      size:         req.file.size,
    });

    let buffer   = req.file.buffer;
    let mimeType = 'image/jpeg';

    // Tenter de redimensionner avec sharp
    try {
      const sharp = require('sharp');
      buffer = await sharp(req.file.buffer)
        .resize(400, 400, { fit: 'cover', position: 'centre' })
        .jpeg({ quality: 85 })
        .toBuffer();
      mimeType = 'image/jpeg';
    } catch (sharpErr) {
      console.warn('[uploadPhoto] Sharp échoué, upload direct:', sharpErr.message);
      buffer   = req.file.buffer;
      mimeType = req.file.mimetype || 'image/jpeg';
    }

    const bucket   = 'avatars';
    const ext      = 'jpg';
    const fileName = `avatar-${req.user.id}-${Date.now()}.${ext}`;

    // Supprimer l'ancienne photo si elle existe
    try {
      const { data: user } = await supabase
        .from('utilisateurs')
        .select('photo_url')
        .eq('id', req.user.id)
        .single();
      if (user?.photo_url?.includes('supabase')) {
        const oldPath = user.photo_url.split(`/${bucket}/`)[1];
        if (oldPath) {
          await supabase.storage.from(bucket).remove([oldPath]);
        }
      }
    } catch (e) {
      // Non bloquant
    }

    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(fileName, buffer, {
        contentType: mimeType,
        upsert: true,
      });

    if (uploadErr) {
      console.error('[uploadPhoto] Supabase error:', uploadErr.message);
      return res.status(500).json({
        success: false,
        message: `Erreur storage: ${uploadErr.message}. ` +
          'Vérifiez que le bucket "avatars" existe et est public.'
      });
    }

    const { data: urlData } = supabase.storage
      .from(bucket).getPublicUrl(fileName);
    const photoUrl = urlData.publicUrl;

    await supabase
      .from('utilisateurs')
      .update({
        photo_url:         photoUrl,
        date_modification: new Date().toISOString(),
      })
      .eq('id', req.user.id);

    return res.json({
      success: true,
      message: 'Photo de profil mise à jour',
      data: { photo_url: photoUrl }
    });

  } catch (err) {
    console.error('[uploadPhoto] Exception:', err.message);
    res.status(500).json({
      success: false,
      message: err.message || 'Erreur lors de l\'upload'
    });
  }
});
```

### 1.3 Fix Backend — Upload CV

```javascript
// Dans backend/src/routes/cv.routes.js
// Remplacer la configuration multer pour le CV

const multerCV = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 }, // 20MB
  fileFilter: (req, file, cb) => {
    const mime = (file.mimetype || '').toLowerCase();
    const ext  = (file.originalname || '').toLowerCase().split('.').pop();

    // Formats acceptés pour les CVs
    const mimesAcceptes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/octet-stream', // Fallback
      'text/plain',
    ];
    const extsAcceptees = ['pdf', 'doc', 'docx', 'txt'];

    if (mimesAcceptes.includes(mime) || extsAcceptees.includes(ext)) {
      cb(null, true);
    } else {
      console.warn('[uploadCV] Format:', mime, ext, '→ accepté quand même');
      // Accepter quand même et laisser le code gérer
      cb(null, true);
    }
  },
});

// Route upload CV
router.post('/upload', auth, multerCV.single('cv'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier CV reçu'
      });
    }

    const ext = (req.file.originalname || 'cv').split('.').pop()
      .toLowerCase();
    const mimesFixes = {
      'pdf':  'application/pdf',
      'doc':  'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    const mimeType = mimesFixes[ext] || req.file.mimetype;

    console.log('[uploadCV] Fichier:', {
      name: req.file.originalname,
      mime: mimeType, ext, size: req.file.size
    });

    // Récupérer le chercheur
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.status(404).json({
        success: false,
        message: 'Profil candidat non trouvé'
      });
    }

    const bucket   = process.env.SUPABASE_STORAGE_BUCKET || 'cv-files';
    const fileName = `cv-${chercheur.id}-${Date.now()}.${ext}`;

    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(fileName, req.file.buffer, {
        contentType: mimeType,
        upsert: false,
      });

    if (uploadErr) {
      console.error('[uploadCV] Supabase error:', uploadErr.message);
      return res.status(500).json({
        success: false,
        message: `Erreur storage: ${uploadErr.message}`
      });
    }

    const { data: urlData } = supabase.storage
      .from(bucket).getPublicUrl(fileName);
    const cvUrl = urlData.publicUrl;

    // Sauvegarder en BDD
    const { data: nouveauCV, error: dbErr } = await supabase
      .from('cv')
      .upsert({
        chercheur_id:      chercheur.id,
        fichier_url:       cvUrl,
        nom_fichier:       req.file.originalname,
        taille_fichier:    req.file.size,
        type_fichier:      ext.toUpperCase(),
        date_upload:       new Date().toISOString(),
        date_modification: new Date().toISOString(),
      }, { onConflict: 'chercheur_id' })
      .select()
      .single();

    if (dbErr) {
      console.error('[uploadCV] DB error:', dbErr.message);
      throw dbErr;
    }

    // Analyser le CV avec IA en arrière-plan
    setImmediate(async () => {
      try {
        const { analyserCV } = require('../services/ia.service');
        const resultat = await analyserCV(cvUrl);
        await supabase.from('cv').update({
          competences_extrait: {
            competences: resultat.competences,
            experience:  resultat.experience,
            formation:   resultat.formation,
            langues:     resultat.langues,
            fallback:    resultat.fallback || false,
            analyse_le:  new Date().toISOString(),
          },
          date_analyse: new Date().toISOString(),
        }).eq('id', nouveauCV.id);
        console.log('[uploadCV] IA analyse OK:', resultat.competences.length, 'compétences');
      } catch (e) {
        console.warn('[uploadCV] IA non bloquant:', e.message);
      }
    });

    return res.status(201).json({
      success: true,
      message: 'CV uploadé avec succès. Analyse IA en cours...',
      data: {
        id:          nouveauCV.id,
        fichier_url: cvUrl,
        nom_fichier: req.file.originalname,
        taille:      req.file.size,
      }
    });

  } catch (err) {
    console.error('[uploadCV] Exception:', err.message);
    res.status(500).json({
      success: false,
      message: err.message || 'Erreur lors de l\'upload du CV'
    });
  }
});
```

---

## 2. Fix Cohérence Scores IA

### 2.1 Problème identifié
```
PROBLÈME :
- Page recherche offres : score 0% sur toutes les offres
- Page recommandations IA : scores différents (44%) pour les mêmes offres
- Incohérence car les 2 pages calculent les scores différemment

CAUSE :
- Page recherche : appelle GET /api/offres sans token → pas de score
- Page recommandations : appelle GET /api/offres/suggestions → avec token → score calculé
- Les scores ne sont pas mis en cache → recalculés à chaque fois → résultats différents

SOLUTION :
- Calculer le score UNE SEULE fois par offre par candidat
- Stocker le score dans la table candidatures_scores (cache)
- Retourner toujours le même score pour la même paire candidat/offre
```

### 2.2 Migration SQL — Table cache scores

```sql
-- Exécuter dans Supabase SQL Editor

CREATE TABLE IF NOT EXISTS offres_scores_cache (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id)
    ON DELETE CASCADE,
  offre_id     UUID NOT NULL REFERENCES offres_emploi(id)
    ON DELETE CASCADE,
  score        INTEGER NOT NULL DEFAULT 0,
  calcule_le   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(chercheur_id, offre_id)
);

CREATE INDEX IF NOT EXISTS idx_scores_chercheur
  ON offres_scores_cache(chercheur_id);
CREATE INDEX IF NOT EXISTS idx_scores_offre
  ON offres_scores_cache(offre_id);
```

### 2.3 Fix Backend — Route GET /api/offres avec scores cohérents

```javascript
// Dans backend/src/routes/offres.routes.js
// Modifier GET /api/offres pour inclure les scores du candidat connecté

router.get('/', async (req, res) => {
  try {
    const {
      page = 1, limite = 20,
      recherche, localisation,
      type_contrat, domaine,
      ordre = 'date_publication', direction = 'desc',
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('offres_emploi')
      .select(`
        id, titre, description, localisation, type_contrat,
        salaire_min, salaire_max, devise, domaine,
        niveau_experience_requis, competences_requises,
        nb_vues, nombre_postes, en_vedette,
        date_publication, date_limite,
        entreprise:entreprise_id (
          id, nom_entreprise, logo_url, secteur_activite
        )
      `, { count: 'exact' })
      .eq('statut', 'publiee')
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (recherche)    query = query.ilike('titre', `%${recherche}%`);
    if (localisation) query = query.ilike('localisation', `%${localisation}%`);
    if (type_contrat) query = query.eq('type_contrat', type_contrat);
    if (domaine)      query = query.eq('domaine', domaine);

    const { data: offres, count, error } = await query;
    if (error) throw error;

    // Ajouter les scores du candidat connecté si authentifié
    let scoresMap = {};
    if (req.user?.role === 'chercheur') {
      try {
        const { data: chercheur } = await supabase
          .from('chercheurs_emploi')
          .select('id')
          .eq('utilisateur_id', req.user.id)
          .single();

        if (chercheur) {
          const offresIds = (offres || []).map(o => o.id);

          // 1. Récupérer les scores déjà calculés
          const { data: scoresCache } = await supabase
            .from('offres_scores_cache')
            .select('offre_id, score')
            .eq('chercheur_id', chercheur.id)
            .in('offre_id', offresIds);

          (scoresCache || []).forEach(s => {
            scoresMap[s.offre_id] = s.score;
          });

          // 2. Calculer les scores manquants en arrière-plan
          const offresNonScorees = offresIds.filter(id =>
            scoresMap[id] === undefined);

          if (offresNonScorees.length > 0) {
            setImmediate(async () => {
              try {
                const { calculerMatchingScore } =
                  require('../services/ia.service');
                const { data: cvData } = await supabase
                  .from('cv')
                  .select('competences_extrait, texte_complet')
                  .eq('chercheur_id', chercheur.id)
                  .single();

                const { data: chercheurData } = await supabase
                  .from('chercheurs_emploi')
                  .select('competences, niveau_etude')
                  .eq('id', chercheur.id)
                  .single();

                const offresAScorer = (offres || []).filter(o =>
                  offresNonScorees.includes(o.id));

                for (const offre of offresAScorer.slice(0, 10)) {
                  const compsCV = cvData?.competences_extrait?.competences || [];
                  const compsProfil = Array.isArray(chercheurData?.competences)
                    ? chercheurData.competences
                    : Object.values(chercheurData?.competences || {});

                  const score = await calculerMatchingScore(
                    { competences: [...compsCV, ...compsProfil], texte_cv: '' },
                    offre
                  );

                  await supabase.from('offres_scores_cache').upsert({
                    chercheur_id: chercheur.id,
                    offre_id:     offre.id,
                    score,
                    calcule_le:   new Date().toISOString(),
                  }, { onConflict: 'chercheur_id,offre_id' });
                }
              } catch (e) {
                console.warn('[scores background]', e.message);
              }
            });
          }
        }
      } catch (e) {
        console.warn('[scores candidat]', e.message);
      }
    }

    // Vérifier offres sauvegardées si candidat
    let sauvegardesSet = new Set();
    if (req.user?.role === 'chercheur') {
      try {
        const { data: chercheur } = await supabase
          .from('chercheurs_emploi')
          .select('id')
          .eq('utilisateur_id', req.user.id)
          .single();
        if (chercheur) {
          const offresIds = (offres || []).map(o => o.id);
          const { data: sauv } = await supabase
            .from('offres_sauvegardees')
            .select('offre_id')
            .eq('chercheur_id', chercheur.id)
            .in('offre_id', offresIds);
          (sauv || []).forEach(s => sauvegardesSet.add(s.offre_id));
        }
      } catch (e) {}
    }

    const offresAvecScores = (offres || []).map(o => ({
      ...o,
      score_compatibilite: scoresMap[o.id] ?? null,
      est_sauvegardee:     sauvegardesSet.has(o.id),
    }));

    return res.json({
      success: true,
      data: {
        offres: offresAvecScores,
        pagination: {
          total:       count || 0,
          page:        parseInt(page),
          limite:      parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });

  } catch (err) {
    console.error('[GET /offres]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 3. Fix Complétion Profil

### 3.1 Logique unifiée de calcul du %

```javascript
// backend/src/services/profil_completion.service.js
// UN SEUL endroit qui calcule le % de complétion
// À utiliser partout dans l'app

const calculerCompletionProfil = (utilisateur, chercheur, cv) => {
  const points = [
    // Photo (15 pts)
    { label: 'Photo de profil',   pts: 15, ok: !!utilisateur?.photo_url },
    // Infos de base (20 pts)
    { label: 'Nom complet',       pts: 5,  ok: !!utilisateur?.nom?.trim() },
    { label: 'Téléphone',         pts: 5,  ok: !!utilisateur?.telephone?.trim() },
    { label: 'Adresse / Ville',   pts: 5,  ok: !!utilisateur?.adresse?.trim() },
    { label: 'Email',             pts: 5,  ok: !!utilisateur?.email },
    // Profil candidat (30 pts)
    { label: 'Titre professionnel', pts: 10, ok: !!chercheur?.titre_poste?.trim() },
    { label: 'Présentation',       pts: 10, ok: !!chercheur?.about?.trim() },
    { label: 'Compétences',        pts: 10, ok:
        Array.isArray(chercheur?.competences)
          ? chercheur.competences.length > 0
          : Object.values(chercheur?.competences || {}).length > 0
    },
    // CV (25 pts)
    { label: 'CV uploadé',         pts: 15, ok: !!cv?.fichier_url },
    { label: 'CV analysé par IA',  pts: 10, ok:
        (cv?.competences_extrait?.competences?.length || 0) > 0 },
    // Disponibilité (10 pts)
    { label: 'Disponibilité',      pts: 5,  ok: !!chercheur?.disponibilite },
    { label: 'Niveau d\'étude',    pts: 5,  ok: !!chercheur?.niveau_etude },
  ];

  const totalPts = points.reduce((sum, p) => sum + p.pts, 0); // = 100
  const obtenusPts = points
    .filter(p => p.ok)
    .reduce((sum, p) => sum + p.pts, 0);

  const pourcentage = Math.round((obtenusPts / totalPts) * 100);

  const manquants = points
    .filter(p => !p.ok)
    .map(p => ({ label: p.label, pts: p.pts }))
    .sort((a, b) => b.pts - a.pts); // Priorité aux plus importants

  return {
    pourcentage,
    points_obtenus: obtenusPts,
    points_total:   totalPts,
    manquants,
    sections: {
      identite:   Math.round(
        (points.slice(0, 4).filter(p => p.ok).reduce((s, p) => s + p.pts, 0)
        / points.slice(0, 4).reduce((s, p) => s + p.pts, 0)) * 100
      ),
      profil:     Math.round(
        (points.slice(4, 7).filter(p => p.ok).reduce((s, p) => s + p.pts, 0)
        / points.slice(4, 7).reduce((s, p) => s + p.pts, 0)) * 100
      ),
      cv:         Math.round(
        (points.slice(7, 9).filter(p => p.ok).reduce((s, p) => s + p.pts, 0)
        / points.slice(7, 9).reduce((s, p) => s + p.pts, 0)) * 100
      ),
    }
  };
};

module.exports = { calculerCompletionProfil };
```

### 3.2 Utiliser dans toutes les routes candidat

```javascript
// Dans CHAQUE route qui retourne des données profil candidat :
// GET /api/users/me, GET /api/candidat/profil, GET /api/candidat/dashboard

const { calculerCompletionProfil } = require('../services/profil_completion.service');

// Ajouter à la réponse :
const completion = calculerCompletionProfil(utilisateur, chercheur, cv);

return res.json({
  success: true,
  data: {
    ...autresDonnees,
    completion_profil: completion, // MÊME valeur partout
  }
});
```

---

## 4. Backend — Mes Candidatures

```javascript
// GET /api/candidat/candidatures
// Toutes les candidatures du candidat connecté

router.get('/candidatures', auth, async (req, res) => {
  try {
    const {
      statut, page = 1, limite = 20,
      ordre = 'date_candidature', direction = 'desc',
    } = req.query;

    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.json({ success: true, data: { candidatures: [], stats: {} } });
    }

    const offset = (parseInt(page) - 1) * parseInt(limite);

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite,
        date_candidature, date_modification,
        lettre_motivation,
        offre:offre_id (
          id, titre, localisation, type_contrat,
          salaire_min, salaire_max, devise,
          date_limite, en_vedette,
          entreprise:entreprise_id (
            id, nom_entreprise, logo_url, secteur_activite
          )
        )
      `, { count: 'exact' })
      .eq('chercheur_id', chercheur.id)
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite) - 1);

    if (statut && statut !== 'all') query = query.eq('statut', statut);

    const { data: candidatures, count, error } = await query;
    if (error) throw error;

    // Stats
    const { data: tousStatuts } = await supabase
      .from('candidatures')
      .select('statut')
      .eq('chercheur_id', chercheur.id);

    const stats = {
      total:      tousStatuts?.length || 0,
      en_attente: tousStatuts?.filter(c => c.statut === 'en_attente').length || 0,
      en_cours:   tousStatuts?.filter(c => c.statut === 'en_cours').length || 0,
      entretien:  tousStatuts?.filter(c => c.statut === 'entretien').length || 0,
      acceptees:  tousStatuts?.filter(c => c.statut === 'acceptee').length || 0,
      refusees:   tousStatuts?.filter(c => c.statut === 'refusee').length || 0,
    };

    return res.json({
      success: true,
      data: {
        candidatures: candidatures || [],
        stats,
        pagination: {
          total:       count || 0,
          page:        parseInt(page),
          limite:      parseInt(limite),
          total_pages: Math.ceil((count || 0) / parseInt(limite)),
        }
      }
    });

  } catch (err) {
    console.error('[candidat/candidatures]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 5. Backend — Offres Sauvegardées

```javascript
// GET /api/candidat/offres-sauvegardees
router.get('/offres-sauvegardees', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.json({ success: true, data: [] });
    }

    const { data, error } = await supabase
      .from('offres_sauvegardees')
      .select(`
        id, date_sauvegarde,
        offre:offre_id (
          id, titre, localisation, type_contrat,
          salaire_min, salaire_max, devise,
          date_limite, statut,
          entreprise:entreprise_id (
            id, nom_entreprise, logo_url
          )
        )
      `)
      .eq('chercheur_id', chercheur.id)
      .order('date_sauvegarde', { ascending: false });

    if (error) throw error;

    // Filtrer les offres encore publiées
    const offresSauvegardees = (data || []).filter(s =>
      s.offre?.statut === 'publiee'
    );

    return res.json({ success: true, data: offresSauvegardees });

  } catch (err) {
    console.error('[offres-sauvegardees GET]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/candidat/offres-sauvegardees/:offreId
router.post('/offres-sauvegardees/:offreId', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.status(404).json({
        success: false, message: 'Profil candidat non trouvé'
      });
    }

    const { error } = await supabase
      .from('offres_sauvegardees')
      .upsert({
        chercheur_id:    chercheur.id,
        offre_id:        req.params.offreId,
        date_sauvegarde: new Date().toISOString(),
      }, { onConflict: 'chercheur_id,offre_id' });

    if (error) throw error;

    return res.json({ success: true, message: 'Offre sauvegardée' });

  } catch (err) {
    console.error('[offres-sauvegardees POST]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/candidat/offres-sauvegardees/:offreId
router.delete('/offres-sauvegardees/:offreId', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.status(404).json({
        success: false, message: 'Profil candidat non trouvé'
      });
    }

    await supabase
      .from('offres_sauvegardees')
      .delete()
      .eq('chercheur_id', chercheur.id)
      .eq('offre_id', req.params.offreId);

    return res.json({ success: true, message: 'Offre retirée des favoris' });

  } catch (err) {
    console.error('[offres-sauvegardees DELETE]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 6. Backend — Alertes Emploi

```sql
-- Migration SQL pour les alertes emploi
CREATE TABLE IF NOT EXISTS alertes_emploi (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id)
    ON DELETE CASCADE,
  nom          VARCHAR(100) NOT NULL,
  mots_cles    TEXT,
  localisation VARCHAR(100),
  type_contrat VARCHAR(50),
  domaine      VARCHAR(100),
  salaire_min  INTEGER,
  frequence    VARCHAR(20) DEFAULT 'quotidien',
  est_active   BOOLEAN DEFAULT TRUE,
  derniere_notif TIMESTAMP WITH TIME ZONE,
  date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

```javascript
// Routes alertes emploi
router.get('/alertes', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    const { data, error } = await supabase
      .from('alertes_emploi')
      .select('*')
      .eq('chercheur_id', chercheur?.id)
      .order('date_creation', { ascending: false });

    if (error) throw error;

    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/alertes', auth, async (req, res) => {
  try {
    const { nom, mots_cles, localisation, type_contrat, domaine,
            salaire_min, frequence } = req.body;

    if (!nom?.trim()) {
      return res.status(400).json({
        success: false, message: 'Nom de l\'alerte requis'
      });
    }

    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    const { data, error } = await supabase
      .from('alertes_emploi')
      .insert({
        chercheur_id:  chercheur.id,
        nom:           nom.trim(),
        mots_cles:     mots_cles || '',
        localisation:  localisation || '',
        type_contrat:  type_contrat || null,
        domaine:       domaine || null,
        salaire_min:   salaire_min || null,
        frequence:     frequence || 'quotidien',
        est_active:    true,
        date_creation: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      success: true,
      message: 'Alerte créée avec succès',
      data
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/alertes/:id', auth, async (req, res) => {
  try {
    const { est_active, ...updates } = req.body;
    const { data, error } = await supabase
      .from('alertes_emploi')
      .update({ ...updates, est_active, date_modification: new Date().toISOString() })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    return res.json({ success: true, message: 'Alerte mise à jour', data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/alertes/:id', auth, async (req, res) => {
  try {
    await supabase.from('alertes_emploi')
      .delete().eq('id', req.params.id);
    return res.json({ success: true, message: 'Alerte supprimée' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 7. Backend — Messagerie Temps Réel

```javascript
// La messagerie temps réel utilise le POLLING toutes les 5 secondes
// (alternative à WebSocket plus simple à maintenir)
// Les routes de messagerie sont partagées entre candidat et recruteur

// GET /api/messages/:destinataireId — Messages d'une conversation
router.get('/:destinataireId', auth, async (req, res) => {
  try {
    const { since } = req.query; // Timestamp pour ne récupérer que les nouveaux
    const crypto = require('crypto');
    const conversationId = crypto.createHash('md5')
      .update([req.user.id, req.params.destinataireId].sort().join('-'))
      .digest('hex');

    let query = supabase
      .from('messages')
      .select(`
        id, contenu, date_envoi, est_lu,
        expediteur_id, destinataire_id,
        offre:offre_id (id, titre)
      `)
      .eq('conversation_id', conversationId)
      .order('date_envoi', { ascending: true });

    if (since) {
      query = query.gt('date_envoi', since);
    }

    const { data: messages, error } = await query;
    if (error) throw error;

    // Marquer comme lus
    await supabase.from('messages')
      .update({ est_lu: true, date_lecture: new Date().toISOString() })
      .eq('conversation_id', conversationId)
      .eq('destinataire_id', req.user.id)
      .eq('est_lu', false);

    // Infos interlocuteur
    const { data: interlocuteur } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, photo_url, role')
      .eq('id', req.params.destinataireId)
      .single();

    return res.json({
      success: true,
      data: {
        messages:        messages || [],
        interlocuteur,
        conversation_id: conversationId,
        timestamp:       new Date().toISOString(),
      }
    });

  } catch (err) {
    console.error('[messages/:id GET]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 8. Backend — Notifications Candidat

```javascript
// GET /api/notifications/mes — DÉJÀ EXISTANT, vérifier qu'il est enregistré

// POST /api/notifications/parametres — Sauvegarder les préférences
router.post('/parametres', auth, async (req, res) => {
  try {
    const { email_candidature, email_message, notif_in_app } = req.body;

    // Stocker dans les paramètres utilisateur
    // (utiliser une table user_preferences ou les paramètres)
    // Pour simplifier : stocker dans utilisateurs comme JSON
    await supabase.from('utilisateurs')
      .update({
        preferences_notif: {
          email_candidature: email_candidature ?? true,
          email_message:     email_message     ?? true,
          notif_in_app:      notif_in_app      ?? true,
        }
      })
      .eq('id', req.user.id);

    return res.json({
      success: true,
      message: 'Préférences de notification sauvegardées'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 9. Backend — Paramètres Candidat

```javascript
// GET /api/candidat/parametres
router.get('/parametres', auth, async (req, res) => {
  try {
    const { data: user } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, telephone, adresse, preferences_notif')
      .eq('id', req.user.id)
      .single();

    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('profil_visible, recevoir_propositions')
      .eq('utilisateur_id', req.user.id)
      .single();

    return res.json({
      success: true,
      data: {
        compte: {
          nom:       user?.nom       || '',
          email:     user?.email     || '',
          telephone: user?.telephone || '',
          adresse:   user?.adresse   || '',
        },
        confidentialite: {
          profil_visible:       chercheur?.profil_visible ?? true,
          recevoir_propositions: chercheur?.recevoir_propositions ?? true,
        },
        notifications: user?.preferences_notif || {
          email_candidature: true,
          email_message:     true,
          notif_in_app:      true,
        }
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/candidat/parametres/confidentialite
router.patch('/parametres/confidentialite', auth, async (req, res) => {
  try {
    const { profil_visible, recevoir_propositions } = req.body;

    const updates = {};
    if (profil_visible !== undefined)
      updates.profil_visible = profil_visible;
    if (recevoir_propositions !== undefined)
      updates.recevoir_propositions = recevoir_propositions;

    if (Object.keys(updates).length > 0) {
      await supabase.from('chercheurs_emploi')
        .update(updates)
        .eq('utilisateur_id', req.user.id);
    }

    return res.json({
      success: true,
      message: 'Paramètres de confidentialité mis à jour'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/candidat/parametres/mot-de-passe
router.patch('/parametres/mot-de-passe', auth, async (req, res) => {
  try {
    const { ancien_mot_de_passe, nouveau_mot_de_passe } = req.body;
    const bcrypt = require('bcryptjs');

    if (!ancien_mot_de_passe || !nouveau_mot_de_passe) {
      return res.status(400).json({
        success: false, message: 'Les deux mots de passe sont requis'
      });
    }

    if (nouveau_mot_de_passe.length < 8) {
      return res.status(400).json({
        success: false, message: 'Minimum 8 caractères'
      });
    }

    const { data: user } = await supabase
      .from('utilisateurs')
      .select('mot_de_passe')
      .eq('id', req.user.id)
      .single();

    const valide = await bcrypt.compare(
      ancien_mot_de_passe, user?.mot_de_passe || '');
    if (!valide) {
      return res.status(400).json({
        success: false, message: 'Mot de passe actuel incorrect'
      });
    }

    const hash = await bcrypt.hash(nouveau_mot_de_passe, 10);
    await supabase.from('utilisateurs')
      .update({ mot_de_passe: hash })
      .eq('id', req.user.id);

    return res.json({ success: true, message: 'Mot de passe modifié' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 10. Flutter — Design Global Candidat

### Règle d'espacement à appliquer sur TOUTES les pages candidat

```dart
// Dans CHAQUE page de l'espace candidat :
// Remplacer padding: const EdgeInsets.all(16)
// par :
// padding: const EdgeInsets.fromLTRB(20, 16, 20, 16)
// pour les SingleChildScrollView
//
// Pour les listes avec ListView :
// padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
//
// Pour les Cards :
// margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6)
//
// SIDEBAR : laisser 16px entre le menu vertical et le contenu
// Dans CandidatShell ou le layout principal :
// Expanded(child: Padding(
//   padding: const EdgeInsets.only(left: 16), // espace après sidebar
//   child: child,
// ))
```

### CandidatShell — Espacement sidebar

```dart
// Dans frontend/lib/screens/candidat/candidat_shell.dart
// Ajouter un padding gauche pour le contenu principal

class CandidatShell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        // Sidebar
        CandidatSidebar(),

        // Diviseur
        const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

        // Contenu avec padding
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: child, // page actuelle
          ),
        ),
      ]),
    );
  }
}
```

---

## 11. Flutter — Cartes Offres Compactes

```dart
// lib/shared/widgets/offre_card_compact.dart
// Carte offre compacte pour la page recherche et recommandations

class OffreCardCompact extends StatelessWidget {
  final Map<String, dynamic> offre;
  final VoidCallback? onPostuler;
  final VoidCallback? onSauvegarder;
  final VoidCallback? onIgnorer;
  final bool estSauvegardee;

  const OffreCardCompact({
    super.key, required this.offre,
    this.onPostuler, this.onSauvegarder, this.onIgnorer,
    this.estSauvegardee = false,
  });

  @override
  Widget build(BuildContext context) {
    final titre    = offre['titre']       as String? ?? '';
    final nomEnt   = offre['entreprise']?['nom_entreprise'] as String? ?? '';
    final logoUrl  = offre['entreprise']?['logo_url']       as String?;
    final location = offre['localisation'] as String? ?? '';
    final contrat  = offre['type_contrat'] as String? ?? '';
    final sMin     = offre['salaire_min']  as int?;
    final sMax     = offre['salaire_max']  as int?;
    final devise   = offre['devise']       as String? ?? 'GNF';
    final score    = offre['score_compatibilite'] as int?;
    final vedette  = offre['en_vedette']   as bool? ?? false;
    final dateLim  = offre['date_limite']  as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: vedette
              ? const Color(0xFFF59E0B).withOpacity(0.5)
              : const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(
          color: Color(0x05000000), blurRadius: 8,
          offset: Offset(0, 2))]),
      child: Column(children: [
        // ── Ligne principale ──────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Logo entreprise
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0))),
              child: logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                          _initiale(nomEnt)))
                  : _initiale(nomEnt),
            ),
            const SizedBox(width: 12),

            // Infos offre
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Titre + Badge vedette
              Row(children: [
                if (vedette)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(100)),
                    child: const Icon(Icons.star_rounded,
                      size: 10, color: Color(0xFFF59E0B))),
                Flexible(child: Text(titre, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 3),
              Text(nomEnt, style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              // Tags
              Wrap(spacing: 6, children: [
                _Tag(Icons.location_on_outlined, location,
                  const Color(0xFF64748B)),
                _Tag(Icons.work_outline_rounded, contrat,
                  const Color(0xFF64748B)),
                if (sMin != null)
                  _Tag(Icons.payments_outlined,
                    '${_formatSalaire(sMin)} $devise',
                    const Color(0xFF10B981)),
              ]),
            ])),

            // Score IA (compact)
            if (score != null && score > 0)
              Column(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _scoreColor(score).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _scoreColor(score).withOpacity(0.3))),
                  child: Center(child: Text('$score%',
                    style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: _scoreColor(score)))),
                ),
                const SizedBox(height: 2),
                Text('IA', style: GoogleFonts.inter(
                  fontSize: 9, color: const Color(0xFF94A3B8))),
              ]),
          ]),
        ),

        // ── Barre d'actions ───────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            // Date limite
            if (dateLim != null)
              Text(_dateLimite(dateLim), style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF94A3B8))),
            const Spacer(),
            // Actions
            if (onIgnorer != null)
              _SmallBtn(
                icon: Icons.close_rounded,
                color: const Color(0xFF94A3B8),
                bg:    const Color(0xFFF1F5F9),
                onTap: onIgnorer!),
            const SizedBox(width: 6),
            if (onSauvegarder != null)
              _SmallBtn(
                icon: estSauvegardee
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: estSauvegardee
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF64748B),
                bg:    estSauvegardee
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFF1F5F9),
                onTap: onSauvegarder!),
            const SizedBox(width: 6),
            if (onPostuler != null)
              GestureDetector(
                onTap: onPostuler,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('Postuler', style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Colors.white)),
                )),
          ]),
        ),
      ]),
    );
  }

  Widget _initiale(String nom) => Center(child: Text(
    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
    style: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w700,
      color: const Color(0xFF1A56DB))));

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFF1A56DB);
    if (s >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatSalaire(int s) {
    if (s >= 1000000) return '${(s / 1000000).toStringAsFixed(1)}M';
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(0)}K';
    return '$s';
  }

  String _dateLimite(String d) {
    try {
      final dt   = DateTime.parse(d);
      final diff = dt.difference(DateTime.now());
      if (diff.inDays < 0) return 'Expirée';
      if (diff.inDays == 0) return 'Expire aujourd\'hui';
      if (diff.inDays <= 7) return 'Expire dans ${diff.inDays}j';
      return 'Expire le ${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }
}

class _Tag extends StatelessWidget {
  final IconData icon; final String text; final Color color;
  const _Tag(this.icon, this.text, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: color),
    const SizedBox(width: 3),
    Text(text, style: GoogleFonts.inter(
      fontSize: 11, color: color)),
  ]);
}

class _SmallBtn extends StatelessWidget {
  final IconData icon; final Color color, bg; final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.color,
    required this.bg, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color)),
  );
}
```

---

## 12. Flutter — Mes Candidatures

```dart
// lib/screens/candidat/pages/mes_candidatures_page.dart

class MesCandidaturesPage extends StatefulWidget {
  const MesCandidaturesPage({super.key});
  @override
  State<MesCandidaturesPage> createState() => _MesCandidaturesPageState();
}

class _MesCandidaturesPageState extends State<MesCandidaturesPage> {

  List<Map<String, dynamic>> _candidatures = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _filtreStatut;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/candidatures'
          '${_filtreStatut != null ? '?statut=$_filtreStatut' : ''}'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          _candidatures = List<Map<String, dynamic>>.from(
            data['data']['candidatures'] ?? []);
          _stats = data['data']['stats'] as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mes candidatures', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          Text('${_stats['total'] ?? 0} candidature(s) envoyée(s)',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          // Filtres chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _Chip('Toutes', null, _filtreStatut, _setFiltre),
              _Chip('En attente', 'en_attente', _filtreStatut, _setFiltre),
              _Chip('En examen', 'en_cours', _filtreStatut, _setFiltre),
              _Chip('Entretien', 'entretien', _filtreStatut, _setFiltre),
              _Chip('Acceptées', 'acceptee', _filtreStatut, _setFiltre),
              _Chip('Refusées', 'refusee', _filtreStatut, _setFiltre),
            ]),
          ),
        ]),
      ),

      // Liste
      Expanded(child: _isLoading
        ? const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        : _candidatures.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFF1A56DB),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                  itemCount: _candidatures.length,
                  itemBuilder: (ctx, i) =>
                    _CandidatureCard(cand: _candidatures[i]),
                ),
              )),
    ]);
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF), shape: BoxShape.circle),
          child: const Icon(Icons.assignment_outlined,
            color: Color(0xFF1A56DB), size: 48)),
        const SizedBox(height: 20),
        Text('Aucune candidature', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text(
          _filtreStatut == null
            ? 'Vous n\'avez pas encore postulé à une offre.'
            : 'Aucune candidature avec ce statut.',
          style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.search_rounded, size: 16),
          label: const Text('Explorer les offres'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () =>
            context.push('/dashboard-candidat/offres')),
      ]),
    ),
  );

  void _setFiltre(String? v) { setState(() => _filtreStatut = v); _load(); }
}

class _CandidatureCard extends StatelessWidget {
  final Map<String, dynamic> cand;
  const _CandidatureCard({required this.cand});

  @override
  Widget build(BuildContext context) {
    final offre  = cand['offre'] as Map<String, dynamic>? ?? {};
    final ent    = offre['entreprise'] as Map<String, dynamic>? ?? {};
    final titre  = offre['titre']         as String? ?? '';
    final nomEnt = ent['nom_entreprise']  as String? ?? '';
    final logo   = ent['logo_url']        as String?;
    final loc    = offre['localisation']  as String? ?? '';
    final statut = cand['statut']         as String? ?? '';
    final score  = cand['score_compatibilite'] as int?;
    final date   = cand['date_candidature'] as String?;

    Color statusColor; String statusLabel; IconData statusIcon;
    switch (statut) {
      case 'en_attente':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'En attente de réponse';
        statusIcon  = Icons.hourglass_empty_rounded;
        break;
      case 'en_cours':
        statusColor = const Color(0xFF1A56DB);
        statusLabel = 'Candidature en examen';
        statusIcon  = Icons.search_rounded;
        break;
      case 'entretien':
        statusColor = const Color(0xFF8B5CF6);
        statusLabel = 'Entretien planifié 🎉';
        statusIcon  = Icons.event_available_rounded;
        break;
      case 'acceptee':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Candidature acceptée 🎊';
        statusIcon  = Icons.check_circle_rounded;
        break;
      case 'refusee':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Candidature refusée';
        statusIcon  = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
        statusLabel = statut;
        statusIcon  = Icons.circle_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(
          color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Column(children: [
        // ── Entreprise + Offre ──────────────────────────
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8)),
            child: logo != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: Image.network(logo, fit: BoxFit.cover))
                : Center(child: Text(
                    nomEnt.isNotEmpty ? nomEnt[0] : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB)))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(nomEnt, style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
          ])),
          if (score != null && score > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(100)),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                  size: 11, color: Color(0xFF1A56DB)),
                const SizedBox(width: 3),
                Text('$score%', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB))),
              ])),
        ]),
        const SizedBox(height: 12),

        // ── Statut ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: statusColor.withOpacity(0.2))),
          child: Row(children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Expanded(child: Text(statusLabel, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: statusColor))),
            if (date != null)
              Text(_fmtDate(date), style: GoogleFonts.inter(
                fontSize: 11, color: statusColor.withOpacity(0.7))),
          ]),
        ),
        // Localisation
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on_outlined,
            size: 13, color: Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(loc, style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF94A3B8))),
        ]),
      ]),
    );
  }

  String _fmtDate(String d) {
    try {
      final dt   = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Aujourd\'hui';
      if (diff.inDays == 1) return 'Hier';
      return 'Il y a ${diff.inDays}j';
    } catch (_) { return ''; }
  }
}

class _Chip extends StatelessWidget {
  final String label; final String? value, selected;
  final void Function(String?) onTap;
  const _Chip(this.label, this.value, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A56DB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0))),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }
}
```

---

## 13. Flutter — Messagerie Candidat (Polling temps réel)

```dart
// lib/screens/candidat/pages/messagerie_candidat_page.dart
// Utilise polling toutes les 5s pour simuler le temps réel

class _MessagerieCandidatState extends State<MessagerieCandidatPage> {
  Timer? _pollTimer;
  String? _lastTimestamp;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Polling toutes les 5 secondes
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5), (_) {
      if (_convActiveId != null) {
        _pollNouveauxMessages();
      } else {
        _loadConversations();
      }
    });
  }

  Future<void> _pollNouveauxMessages() async {
    if (_convActiveId == null || _isLoading) return;
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final url = '${ApiConfig.baseUrl}/api/messages/$_convActiveId'
        '${_lastTimestamp != null ? '?since=$_lastTimestamp' : ''}';
      final res = await http.get(Uri.parse(url),
        headers: { 'Authorization': 'Bearer $token' });
      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        final nouveaux = List<Map<String, dynamic>>.from(
          data['data']['messages'] ?? []);
        _lastTimestamp = data['data']['timestamp'];

        if (nouveaux.isNotEmpty && mounted) {
          setState(() => _messages.addAll(nouveaux));
          // Scroll vers le bas
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.animateTo(
                _scrollCtrl.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut);
            }
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
```

---

## 14. Flutter — Notifications Candidat

```dart
// lib/screens/candidat/pages/notifications_candidat_page.dart

class NotificationsCandidatPage extends StatefulWidget {
  const NotificationsCandidatPage({super.key});
  @override
  State<NotificationsCandidatPage> createState() =>
    _NotificationsCandidatPageState();
}

class _NotificationsCandidatPageState
    extends State<NotificationsCandidatPage> {

  List<Map<String, dynamic>> _notifs = [];
  int _nbNonLues = 0;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/mes'),
        headers: { 'Authorization': 'Bearer $token' });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final d = data['data'] as Map<String, dynamic>;
        setState(() {
          _notifs    = List<Map<String, dynamic>>.from(
            d['notifications'] ?? []);
          _nbNonLues = d['nb_non_lues'] as int? ?? 0;
          _isLoading = false;
        });
      }
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _marquerToutLu() async {
    final token = context.read<AuthProvider>().token ?? '';
    await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications/tout-lire/action'),
      headers: { 'Authorization': 'Bearer $token' });
    _load();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    // Header
    Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notifications', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          if (_nbNonLues > 0)
            Text('$_nbNonLues non lue(s)',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF1A56DB))),
        ])),
        if (_nbNonLues > 0)
          TextButton.icon(
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('Tout lire'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A56DB),
              textStyle: GoogleFonts.inter(fontSize: 13)),
            onPressed: _marquerToutLu),
      ]),
    ),
    const Divider(height: 1, color: Color(0xFFE2E8F0)),

    Expanded(child: _isLoading
      ? const Center(child: CircularProgressIndicator(
          color: Color(0xFF1A56DB)))
      : _notifs.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF1A56DB),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
                itemCount: _notifs.length,
                itemBuilder: (ctx, i) => _NotifCard(
                  notif: _notifs[i],
                  onMarkRead: () async {
                    final token = context.read<AuthProvider>().token ?? '';
                    await http.patch(
                      Uri.parse('${ApiConfig.baseUrl}/api/notifications/${_notifs[i]['id']}'),
                      headers: { 'Authorization': 'Bearer $token' });
                    _load();
                  }),
              ),
            )),
  ]);

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFFEFF6FF), shape: BoxShape.circle),
        child: const Icon(Icons.notifications_none_rounded,
          color: Color(0xFF1A56DB), size: 40)),
      const SizedBox(height: 16),
      Text('Vous êtes à jour !', style: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text('Aucune notification pour le moment',
        style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
    ]),
  );
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onMarkRead;
  const _NotifCard({required this.notif, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final estLue = notif['est_lue'] == true;
    final type   = notif['type'] as String? ?? 'systeme';
    final titre  = notif['titre'] as String? ?? '';
    final msg    = notif['message'] as String? ?? '';
    final date   = notif['date_creation'] as String?;

    Color ic; IconData ii;
    switch (type) {
      case 'candidature':
        ic = const Color(0xFF10B981); ii = Icons.assignment_turned_in_rounded; break;
      case 'offre':
        ic = const Color(0xFF1A56DB); ii = Icons.work_rounded; break;
      case 'message':
        ic = const Color(0xFF8B5CF6); ii = Icons.chat_bubble_rounded; break;
      default:
        ic = const Color(0xFFF59E0B); ii = Icons.notifications_rounded;
    }

    return GestureDetector(
      onTap: () {
        if (!estLue) onMarkRead();
        if (notif['lien'] != null) context.push(notif['lien']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: estLue ? Colors.white : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: estLue
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF1A56DB).withOpacity(0.2))),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: ic.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(ii, color: ic, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: estLue ? FontWeight.w400 : FontWeight.w600,
              color: const Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(msg, style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(_fmtDate(date), style: GoogleFonts.inter(
              fontSize: 10, color: const Color(0xFF94A3B8))),
          ])),
          if (!estLue)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF1A56DB), shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  String _fmtDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays}j';
    } catch (_) { return ''; }
  }
}
```

---

## 15. Flutter — Paramètres Candidat

```dart
// lib/screens/candidat/pages/parametres_candidat_page.dart

class ParametresCandidatPage extends StatefulWidget {
  const ParametresCandidatPage({super.key});
  @override
  State<ParametresCandidatPage> createState() =>
    _ParametresCandidatPageState();
}

class _ParametresCandidatPageState extends State<ParametresCandidatPage> {
  String _section = 'compte';

  static const _sections = [
    ('compte',         '👤 Informations du compte', Icons.person_outline_rounded),
    ('confidentialite','🔒 Confidentialité',         Icons.shield_outlined),
    ('notifications',  '🔔 Notifications',           Icons.notifications_outlined),
    ('apparence',      '🎨 Apparence',               Icons.palette_outlined),
    ('securite',       '🔑 Sécurité',                Icons.lock_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) => Row(children: [
    // Sidebar
    Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16),
          child: Text('Paramètres', style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A)))),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 8),
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: _sections.map((s) {
            final isActive = _section == s.$1;
            return GestureDetector(
              onTap: () => setState(() => _section = s.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFEFF6FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(s.$3, size: 18,
                    color: isActive
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFF94A3B8)),
                  const SizedBox(width: 10),
                  Text(s.$2, style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive
                        ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFF64748B))),
                ]),
              ),
            );
          }).toList(),
        )),
      ]),
    ),

    // Contenu
    Expanded(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildSection(),
    )),
  ]);

  Widget _buildSection() {
    switch (_section) {
      case 'compte':          return _SectionCompteCandidат();
      case 'confidentialite': return _SectionConfidentialite();
      case 'notifications':   return _SectionNotifCandidат();
      case 'apparence':       return _SectionApparenceCandidат();
      case 'securite':        return _SectionSecuriteCandidат();
      default:                return _SectionCompteCandidат();
    }
  }
}

// Section Compte
class _SectionCompteCandidат extends StatefulWidget {
  @override
  State<_SectionCompteCandidат> createState() =>
    _SectionCompteCandidatState();
}
class _SectionCompteCandidatState extends State<_SectionCompteCandidат> {
  final _nomCtrl  = TextEditingController();
  final _telCtrl  = TextEditingController();
  final _adrCtrl  = TextEditingController();
  bool _isLoading = true, _isSaving = false;
  String _email   = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/parametres'),
        headers: { 'Authorization': 'Bearer $token' });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final compte = data['data']['compte'] as Map<String, dynamic>? ?? {};
        setState(() {
          _nomCtrl.text = compte['nom']       ?? '';
          _telCtrl.text = compte['telephone'] ?? '';
          _adrCtrl.text = compte['adresse']   ?? '';
          _email        = compte['email']     ?? '';
          _isLoading    = false;
        });
      }
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nom':       _nomCtrl.text.trim(),
          'telephone': _telCtrl.text.trim(),
          'adresse':   _adrCtrl.text.trim(),
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Compte mis à jour !'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A56DB)));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ParamSectionHeader(
        icon: Icons.person_outline_rounded,
        title: 'Informations du compte',
        subtitle: 'Modifiez vos informations personnelles'),
      const SizedBox(height: 24),

      _ParamBoxCard(title: 'Informations de base', children: [
        _PF('Nom complet',  _nomCtrl, 'Votre nom', Icons.person_outline_rounded),
        const SizedBox(height: 14),
        _PF('Téléphone',    _telCtrl, '+224...', Icons.phone_outlined),
        const SizedBox(height: 14),
        _PF('Ville / Adresse', _adrCtrl, 'Conakry', Icons.location_on_outlined),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            onPressed: _isSaving ? null : _save)),
      ]),
      const SizedBox(height: 16),

      _ParamBoxCard(title: 'Email', children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(children: [
            const Icon(Icons.email_outlined,
              color: Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 10),
            Text(_email, style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF64748B))),
          ])),
        const SizedBox(height: 8),
        Text('L\'email ne peut pas être modifié.',
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF94A3B8))),
      ]),
    ]);
  }

  Widget _PF(String label, TextEditingController ctrl,
    String hint, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w500,
      color: const Color(0xFF374151))),
    const SizedBox(height: 6),
    TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18,
          color: const Color(0xFF94A3B8)),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1A56DB), width: 1.5))),
    ),
  ]);
}

// Section Confidentialité
class _SectionConfidentialite extends StatefulWidget {
  @override
  State<_SectionConfidentialite> createState() =>
    _SectionConfidentialiteState();
}
class _SectionConfidentialiteState extends State<_SectionConfidentialite> {
  bool _profilVisible = true;
  bool _recevoirProp  = true;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/parametres'),
        headers: { 'Authorization': 'Bearer $token' });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final conf = data['data']['confidentialite']
            as Map<String, dynamic>? ?? {};
        setState(() {
          _profilVisible = conf['profil_visible'] ?? true;
          _recevoirProp  = conf['recevoir_propositions'] ?? true;
          _isLoading     = false;
        });
      }
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _save(String key, bool val) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/parametres/confidentialite'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({ key: val }),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A56DB)));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ParamSectionHeader(
        icon: Icons.shield_outlined,
        title: 'Confidentialité',
        subtitle: 'Gérez la visibilité de votre profil'),
      const SizedBox(height: 24),

      _ParamBoxCard(title: 'Visibilité & Propositions', children: [
        _Toggle(
          title: 'Mon profil est visible par les recruteurs',
          subtitle: 'Les entreprises peuvent trouver votre profil '
              'dans leur recherche de talents',
          value: _profilVisible,
          onChanged: (v) {
            setState(() => _profilVisible = v);
            _save('profil_visible', v);
          }),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _Toggle(
          title: 'Recevoir des propositions de contact',
          subtitle: 'Permettre aux entreprises de vous contacter '
              'directement via la messagerie',
          value: _recevoirProp,
          onChanged: (v) {
            setState(() => _recevoirProp = v);
            _save('recevoir_propositions', v);
          }),
      ]),
    ]);
  }
}

// ── Helpers widgets paramètres ─────────────────────────────

class _ParamSectionHeader extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _ParamSectionHeader({
    required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: const Color(0xFF1A56DB), size: 22)),
    const SizedBox(width: 12),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A))),
      Text(subtitle, style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF64748B))),
    ])),
  ]);
}

class _ParamBoxCard extends StatelessWidget {
  final String title; final List<Widget> children;
  const _ParamBoxCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A))),
      const SizedBox(height: 14),
      const Divider(height: 1, color: Color(0xFFF1F5F9)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );
}

class _Toggle extends StatelessWidget {
  final String title, subtitle; final bool value;
  final void Function(bool) onChanged;
  const _Toggle({required this.title, required this.subtitle,
    required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: const Color(0xFF0F172A))),
      Text(subtitle, style: GoogleFonts.inter(
        fontSize: 12, color: const Color(0xFF64748B))),
    ])),
    Switch(value: value, onChanged: onChanged,
      activeColor: const Color(0xFF1A56DB)),
  ]);
}

// Section sécurité candidat (même logique que recruteur)
class _SectionSecuriteCandidат extends StatefulWidget {
  @override
  State<_SectionSecuriteCandidат> createState() =>
    _SectionSecuriteCandidatState();
}
class _SectionSecuriteCandidatState extends State<_SectionSecuriteCandidат> {
  final _ancCtrl = TextEditingController();
  final _nvCtrl  = TextEditingController();
  final _cfCtrl  = TextEditingController();
  bool _saving = false;
  bool _showAnc = false, _showNv = false, _showCf = false;

  Future<void> _save() async {
    if (_nvCtrl.text != _cfCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mots de passe non identiques'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/parametres/mot-de-passe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ancien_mot_de_passe':  _ancCtrl.text,
          'nouveau_mot_de_passe': _nvCtrl.text,
        }),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && mounted) {
        _ancCtrl.clear(); _nvCtrl.clear(); _cfCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mot de passe modifié'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      } else {
        throw Exception(data['message'] ?? 'Erreur');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
      }
    } finally { setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _ParamSectionHeader(
      icon: Icons.lock_outline_rounded,
      title: 'Sécurité', subtitle: 'Changez votre mot de passe'),
    const SizedBox(height: 24),
    _ParamBoxCard(title: 'Nouveau mot de passe', children: [
      _PwdF(_ancCtrl, 'Mot de passe actuel', _showAnc,
        () => setState(() => _showAnc = !_showAnc)),
      const SizedBox(height: 14),
      _PwdF(_nvCtrl, 'Nouveau mot de passe', _showNv,
        () => setState(() => _showNv = !_showNv)),
      const SizedBox(height: 14),
      _PwdF(_cfCtrl, 'Confirmer', _showCf,
        () => setState(() => _showCf = !_showCf)),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          icon: _saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_reset_outlined, size: 16),
          label: Text(_saving ? 'Modification...' : 'Modifier le mot de passe',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: _saving ? null : _save)),
    ]),
  ]);

  Widget _PwdF(TextEditingController c, String h, bool show, VoidCallback t) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(h, style: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w500,
      color: const Color(0xFF374151))),
    const SizedBox(height: 6),
    TextFormField(
      controller: c, obscureText: !show,
      decoration: InputDecoration(
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline_rounded,
          size: 18, color: Color(0xFF94A3B8)),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
            size: 18, color: const Color(0xFF94A3B8)),
          onPressed: t),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1A56DB), width: 1.5))),
    ),
  ]);
}

class _SectionNotifCandidат extends StatefulWidget {
  @override
  State<_SectionNotifCandidат> createState() =>
    _SectionNotifCandidatState();
}
class _SectionNotifCandidatState extends State<_SectionNotifCandidат> {
  bool _emailCand = true, _emailMsg = true, _inApp = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _ParamSectionHeader(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      subtitle: 'Choisissez comment être notifié'),
    const SizedBox(height: 24),
    _ParamBoxCard(title: 'Notifications', children: [
      _Toggle(
        title: 'Email à chaque candidature',
        subtitle: 'Recevoir un email quand une candidature change de statut',
        value: _emailCand,
        onChanged: (v) => setState(() => _emailCand = v)),
      const Divider(height: 20, color: Color(0xFFF1F5F9)),
      _Toggle(
        title: 'Email pour les messages',
        subtitle: 'Recevoir un email quand vous avez un nouveau message',
        value: _emailMsg,
        onChanged: (v) => setState(() => _emailMsg = v)),
      const Divider(height: 20, color: Color(0xFFF1F5F9)),
      _Toggle(
        title: 'Notifications dans l\'app',
        subtitle: 'Voir les notifications dans la cloche',
        value: _inApp,
        onChanged: (v) => setState(() => _inApp = v)),
    ]),
    const SizedBox(height: 16),
    SizedBox(width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save_outlined, size: 16),
        label: const Text('Sauvegarder'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10))),
        onPressed: () async {
          final token = context.read<AuthProvider>().token ?? '';
          await http.post(
            Uri.parse('${ApiConfig.baseUrl}/api/notifications/parametres'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'email_candidature': _emailCand,
              'email_message':     _emailMsg,
              'notif_in_app':      _inApp,
            }),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Préférences sauvegardées'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating));
          }
        })),
  ]);
}

class _SectionApparenceCandidат extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    _ParamSectionHeader(
      icon: Icons.palette_outlined,
      title: 'Apparence',
      subtitle: 'Personnalisez votre interface'),
    const SizedBox(height: 24),
    _ParamBoxCard(title: 'Thème', children: [
      Consumer<ThemeProvider>(builder: (ctx, tp, _) => Row(children: [
        _ThBtn(Icons.light_mode_rounded, 'Clair', !tp.isDark,
          () => tp.setTheme(false)),
        const SizedBox(width: 12),
        _ThBtn(Icons.dark_mode_rounded, 'Sombre', tp.isDark,
          () => tp.setTheme(true)),
      ])),
    ]),
    const SizedBox(height: 16),
    _ParamBoxCard(title: 'À propos', children: [
      _AboutRow('Version', 'EmploiConnect v1.0.0'),
      _AboutRow('Projet', 'Licence Pro GL 2026'),
      _AboutRow('Étudiants', 'BARRY Y. · DIALLO I.'),
    ]),
  ]);
}

class _ThBtn extends StatelessWidget {
  final IconData icon; final String label;
  final bool selected; final VoidCallback onTap;
  const _ThBtn(this.icon, this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1A56DB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16,
          color: selected ? Colors.white : const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF64748B))),
      ])));
}

class _AboutRow extends StatelessWidget {
  final String l, v;
  const _AboutRow(this.l, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(l, style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF64748B))),
      const Spacer(),
      Text(v, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: const Color(0xFF0F172A))),
    ]));
}
```

---

## 16. Critères d'Acceptation

### ✅ Upload Photo & CV
- [ ] Upload photo accepte JPG, PNG, WEBP, HEIC (iPhone)
- [ ] Upload CV accepte PDF, DOCX, DOC
- [ ] Erreur "format non supporté" disparue
- [ ] Photo mise à jour visible partout (sidebar, topbar)

### ✅ Scores IA cohérents
- [ ] Table `offres_scores_cache` créée
- [ ] Score identique pour la même offre sur toutes les pages
- [ ] Score calculé en arrière-plan (non bloquant)
- [ ] `score_compatibilite: null` si score pas encore calculé (afficher — au lieu de 0%)

### ✅ Complétion profil
- [ ] UN SEUL service `calculerCompletionProfil` utilisé partout
- [ ] % identique dans la sidebar, la vue d'ensemble et la page profil
- [ ] Sections détaillées : identité/profil/CV

### ✅ Mes Candidatures
- [ ] Liste toutes les candidatures du candidat
- [ ] Filtres par statut avec chips colorés
- [ ] Cards avec statut coloré + icône + score IA
- [ ] État vide avec CTA "Explorer les offres"

### ✅ Offres Sauvegardées
- [ ] Sauvegarder une offre → persisté en BDD
- [ ] Icône bookmark change instantanément
- [ ] Page offres sauvegardées montre les vraies offres
- [ ] Supprimer une sauvegarde fonctionnel

### ✅ Alertes Emploi
- [ ] Table `alertes_emploi` créée
- [ ] CRUD complet (créer/modifier/activer-désactiver/supprimer)
- [ ] Page alertes design propre

### ✅ Messagerie temps réel
- [ ] Polling toutes les 5 secondes sur la conversation active
- [ ] Nouveaux messages apparaissent sans rafraîchir
- [ ] Photo de l'interlocuteur mise à jour dynamiquement

### ✅ Notifications
- [ ] Vraies notifications depuis la BDD
- [ ] Marquer comme lu + badge diminue
- [ ] Tout lire en un clic
- [ ] Paramètres notifications sauvegardés

### ✅ Paramètres
- [ ] Section Compte : modifier nom/tel/adresse
- [ ] Section Confidentialité : profil_visible + recevoir_propositions
- [ ] Section Sécurité : changer mot de passe avec vérification
- [ ] Section Notifications : toggles sauvegardés
- [ ] Section Apparence : thème clair/sombre

### ✅ Design Global
- [ ] Espacement 20px des bords sur toutes les pages
- [ ] Cartes offres compactes avec boutons Postuler/Sauvegarder
- [ ] Scores IA cohérents (pas de 0% si score non calculé → afficher —)

---

*PRD EmploiConnect v6.0 — Espace Candidat Complet*
*Cursor / Kirsoft AI — Phase 10*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
