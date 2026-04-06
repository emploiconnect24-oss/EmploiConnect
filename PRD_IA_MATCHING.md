# PRD — EmploiConnect · Intégration IA & Matching Intelligent
## Product Requirements Document v4.0 — AI/NLP Integration
**Stack : Node.js + Express · PostgreSQL/Supabase · Flutter**
**APIs : RapidAPI — Twinword Text Similarity + Resume Parser + Topic Tagging**
**Outil : Cursor / Kirsoft AI**
**Statut : Phase 8 — Intégration IA après Backend Admin validé**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> **APIs disponibles :**
> - ✅ Clé RapidAPI principale → déjà dans les paramètres admin
> - ✅ Twinword Text Similarity → souscrit
> - ⏳ Resume Parser → à souscrire sur RapidAPI (plan gratuit)
> - ⏳ Twinword Topic Tagging → à souscrire sur RapidAPI (plan gratuit)
>
> **Priorité :** Implémenter TOUT en même temps :
> 1. Score matching visible par le candidat sur chaque offre
> 2. Suggestions automatiques d'offres pour le candidat
> 3. Analyse du CV uploadé (extraction compétences)
>
> **Règle importante :** Si une API n'est pas encore souscrite,
> le système doit fonctionner en MODE DÉGRADÉ (score basé sur
> correspondance textuelle simple) sans planter.
>
> Implémenter dans l'ordre exact des sections.

---

## Table des Matières

1. [Architecture IA — Vue d'ensemble](#1-architecture-ia--vue-densemble)
2. [Configuration des APIs RapidAPI](#2-configuration-des-apis-rapidapi)
3. [Service IA Backend — ia.service.js](#3-service-ia-backend--iaservicejs)
4. [Route Analyse CV — POST /api/cv/analyser](#4-route-analyse-cv--post-apicvanalyser)
5. [Route Matching — POST /api/matching/score](#5-route-matching--post-apimatchingscore)
6. [Route Suggestions — GET /api/offres/suggestions](#6-route-suggestions--get-apiofffressuggestions)
7. [Automatisation — Déclencher l'IA automatiquement](#7-automatisation--déclencher-lia-automatiquement)
8. [Flutter — Afficher les scores IA partout](#8-flutter--afficher-les-scores-ia-partout)
9. [Tests des endpoints IA](#9-tests-des-endpoints-ia)
10. [Critères d'Acceptation](#10-critères-dacceptation)

---

## 1. Architecture IA — Vue d'ensemble

### Ce que l'IA fait concrètement
```
CANDIDAT uploade son CV
        ↓
[Resume Parser API] → Extrait : compétences, expérience, formation, langues
        ↓
Stocké dans cv.competences_extrait (JSONB)
        ↓
CANDIDAT consulte une offre d'emploi
        ↓
[Text Similarity API] → Compare profil candidat ↔ description offre
        ↓
Score de matching 0-100% → affiché sur la card de l'offre
        ↓
[Topic Tagging API] → Extrait les mots-clés de l'offre
        ↓
Offres triées par score décroissant = Suggestions personnalisées
```

### Mode dégradé (si API non disponible)
```
Si l'API est indisponible ou clé non configurée :
→ Utiliser un algorithme de scoring simple basé sur :
   - Correspondance des mots-clés dans titre/description
   - Niveau d'expérience requis vs disponible
   - Localisation (même ville = bonus)
→ Score approximatif mais fonctionnel
→ Jamais de crash — toujours un résultat
```

### Flux complet
```
                    ┌─────────────────────────────────────┐
                    │          RAPIDAPI                    │
                    │  ┌─────────────────────────────┐    │
CV texte ──────────▶│  │ Resume Parser               │    │
                    │  │ resume-parser3.p.rapidapi.com│    │
                    │  └──────────────┬──────────────┘    │
                    │                 │ compétences[]      │
                    │  ┌──────────────▼──────────────┐    │
Profil + Offre ────▶│  │ Text Similarity             │    │
                    │  │ twinword-text-similarity-v1  │    │
                    │  └──────────────┬──────────────┘    │
                    │                 │ score 0.0-1.0      │
                    │  ┌──────────────▼──────────────┐    │
Texte offre ───────▶│  │ Topic Tagging               │    │
                    │  │ twinword-topic-tagging1      │    │
                    │  └──────────────┬──────────────┘    │
                    │                 │ keywords[]         │
                    └─────────────────┼─────────────────  ┘
                                      │
                              ┌───────▼────────┐
                              │   SUPABASE DB   │
                              │ cv.competences  │
                              │ candidatures    │
                              │ .score_compat.  │
                              └────────────────┘
```

---

## 2. Configuration des APIs RapidAPI

### 2.1 APIs à souscrire sur RapidAPI

```
URL : https://rapidapi.com

API 1 — Twinword Text Similarity (DÉJÀ SOUSCRIT ✅)
  Host    : twinword-text-similarity-v1.p.rapidapi.com
  Endpoint: GET /similarity/
  Params  : text1=..., text2=...
  Réponse : { "similarity": 0.87 }
  Plan    : Gratuit (jusqu'à 2500 req/mois)

API 2 — Resume Parser (À SOUSCRIRE)
  Rechercher : "Resume Parser" sur RapidAPI
  Host    : resume-parser3.p.rapidapi.com
  Endpoint: POST /resume/parse
  Body    : { "url": "URL_DU_CV" } OU FormData avec le fichier
  Réponse : { "skills": [...], "experience": [...], ... }
  Plan    : Gratuit disponible

API 3 — Twinword Topic Tagging (À SOUSCRIRE)
  Rechercher : "Twinword Topic Tagging" sur RapidAPI
  Host    : twinword-topic-tagging1.p.rapidapi.com
  Endpoint: GET /classify/
  Params  : text=...
  Réponse : { "topic": [...], "keyword": {...} }
  Plan    : Gratuit disponible

UNE SEULE CLÉ X-RapidAPI-Key pour les 3 APIs !
```

### 2.2 Variables ENV à ajouter dans `backend/.env`

```bash
# IA & Matching — RapidAPI
RAPIDAPI_KEY=votre_cle_rapidapi_ici
RAPIDAPI_SIMILARITY_HOST=twinword-text-similarity-v1.p.rapidapi.com
RAPIDAPI_RESUME_PARSER_HOST=resume-parser3.p.rapidapi.com
RAPIDAPI_TOPIC_TAGGING_HOST=twinword-topic-tagging1.p.rapidapi.com

# Score minimum pour suggérer une offre (%)
IA_SEUIL_MATCHING=40
```

### 2.3 Lire les clés depuis la BDD (paramètres admin)

```javascript
// backend/src/config/rapidApi.js — METTRE À JOUR

const { supabase } = require('./supabase');

// Cache des clés (éviter appels BDD répétés)
let keysCache = null;
let keysCacheTime = 0;

const getRapidApiKeys = async () => {
  const now = Date.now();
  // Rafraîchir le cache toutes les 5 minutes
  if (keysCache && (now - keysCacheTime) < 5 * 60 * 1000) {
    return keysCache;
  }

  try {
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'rapidapi_key',
        'rapidapi_similarity_host',
        'rapidapi_resume_parser_host',
        'rapidapi_topic_tagging_host',
        'seuil_matching_minimum',
      ]);

    const params = {};
    (data || []).forEach(p => { params[p.cle] = p.valeur; });

    // Déchiffrer la clé API (elle est chiffrée en BDD)
    const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY ||
      'emploiconnect_votre_cle_32_chars!!';

    let apiKey = params['rapidapi_key'] || '';
    if (apiKey.includes(':')) {
      // Déchiffrer
      try {
        const crypto = require('crypto');
        const [ivHex, encrypted] = apiKey.split(':');
        const iv  = Buffer.from(ivHex, 'hex');
        const key = crypto.scryptSync(ENCRYPTION_KEY, 'salt', 32);
        const dec = crypto.createDecipheriv('aes-256-cbc', key, iv);
        let dec_text = dec.update(encrypted, 'hex', 'utf8');
        dec_text += dec.final('utf8');
        apiKey = dec_text;
      } catch (e) {
        console.warn('[getRapidApiKeys] Déchiffrement échoué, utiliser .env');
        apiKey = process.env.RAPIDAPI_KEY || '';
      }
    }

    // Fallback sur les variables d'environnement
    keysCache = {
      apiKey: apiKey || process.env.RAPIDAPI_KEY || '',
      similarityHost: params['rapidapi_similarity_host'] ||
        process.env.RAPIDAPI_SIMILARITY_HOST ||
        'twinword-text-similarity-v1.p.rapidapi.com',
      parserHost: params['rapidapi_resume_parser_host'] ||
        process.env.RAPIDAPI_RESUME_PARSER_HOST ||
        'resume-parser3.p.rapidapi.com',
      taggingHost: params['rapidapi_topic_tagging_host'] ||
        process.env.RAPIDAPI_TOPIC_TAGGING_HOST ||
        'twinword-topic-tagging1.p.rapidapi.com',
      seuilMatching: parseInt(
        params['seuil_matching_minimum'] || '40'),
    };

    keysCacheTime = now;
    return keysCache;
  } catch (err) {
    console.error('[getRapidApiKeys]', err.message);
    // Fallback total sur .env
    return {
      apiKey:          process.env.RAPIDAPI_KEY || '',
      similarityHost:  process.env.RAPIDAPI_SIMILARITY_HOST || '',
      parserHost:      process.env.RAPIDAPI_RESUME_PARSER_HOST || '',
      taggingHost:     process.env.RAPIDAPI_TOPIC_TAGGING_HOST || '',
      seuilMatching:   40,
    };
  }
};

// Invalider le cache quand les paramètres changent
const invalidateKeysCache = () => {
  keysCache = null;
  keysCacheTime = 0;
};

module.exports = { getRapidApiKeys, invalidateKeysCache };
```

---

## 3. Service IA Backend — ia.service.js

```javascript
// backend/src/services/ia.service.js
// Service principal IA — gère tous les appels aux APIs RapidAPI
// avec fallback automatique si API indisponible

const axios = require('axios');
const { getRapidApiKeys } = require('../config/rapidApi');

// ══════════════════════════════════════════════════════════════
// FONCTION 1 : Calculer le score de similarité entre 2 textes
// Utilise : Twinword Text Similarity API
// ══════════════════════════════════════════════════════════════
const calculerSimilarite = async (texte1, texte2) => {
  try {
    const keys = await getRapidApiKeys();

    if (!keys.apiKey || !keys.similarityHost) {
      console.warn('[IA] Clé API ou host non configuré → fallback');
      return _fallbackSimilarite(texte1, texte2);
    }

    // Limiter la longueur des textes (l'API a des limites)
    const t1 = texte1.slice(0, 2000);
    const t2 = texte2.slice(0, 2000);

    const response = await axios.request({
      method: 'GET',
      url: `https://${keys.similarityHost}/similarity/`,
      params: { text1: t1, text2: t2 },
      headers: {
        'X-RapidAPI-Key':  keys.apiKey,
        'X-RapidAPI-Host': keys.similarityHost,
      },
      timeout: 8000, // 8 secondes max
    });

    const similarity = response.data?.similarity ?? 0;

    // Convertir 0.0-1.0 en 0-100
    return Math.round(similarity * 100);

  } catch (err) {
    console.warn('[IA/similarity] API indisponible:', err.message);
    // Fallback : score approximatif
    return _fallbackSimilarite(texte1, texte2);
  }
};

// ══════════════════════════════════════════════════════════════
// FONCTION 2 : Analyser un CV (parser)
// Utilise : Resume Parser API
// ══════════════════════════════════════════════════════════════
const analyserCV = async (cvUrl) => {
  try {
    const keys = await getRapidApiKeys();

    if (!keys.apiKey || !keys.parserHost) {
      console.warn('[IA] Parser CV non configuré → extraction basique');
      return _fallbackParserCV(cvUrl);
    }

    const response = await axios.request({
      method: 'POST',
      url: `https://${keys.parserHost}/resume/parse`,
      headers: {
        'Content-Type':    'application/json',
        'X-RapidAPI-Key':  keys.apiKey,
        'X-RapidAPI-Host': keys.parserHost,
      },
      data: { url: cvUrl },
      timeout: 15000, // 15 secondes pour le parsing
    });

    const data = response.data;

    // Normaliser la réponse du parser
    return {
      competences:  _extractCompetences(data),
      experience:   _extractExperience(data),
      formation:    _extractFormation(data),
      langues:      _extractLangues(data),
      email:        data.email || data.Email || null,
      telephone:    data.phone || data.Phone || null,
      score_ia:     data.score || null,
      raw:          data, // Données brutes pour debug
    };

  } catch (err) {
    console.warn('[IA/parser] API indisponible:', err.message);
    return _fallbackParserCV(cvUrl);
  }
};

// ══════════════════════════════════════════════════════════════
// FONCTION 3 : Extraire les mots-clés d'une offre
// Utilise : Twinword Topic Tagging API
// ══════════════════════════════════════════════════════════════
const extraireMotsCles = async (texteOffre) => {
  try {
    const keys = await getRapidApiKeys();

    if (!keys.apiKey || !keys.taggingHost) {
      return _fallbackMotsCles(texteOffre);
    }

    const texte = texteOffre.slice(0, 3000);

    const response = await axios.request({
      method: 'GET',
      url: `https://${keys.taggingHost}/classify/`,
      params: { text: texte },
      headers: {
        'X-RapidAPI-Key':  keys.apiKey,
        'X-RapidAPI-Host': keys.taggingHost,
      },
      timeout: 8000,
    });

    const data = response.data;

    // Extraire les mots-clés depuis la réponse
    const keywords = [];
    if (data.keyword) {
      Object.keys(data.keyword).forEach(kw => {
        keywords.push({
          mot:   kw,
          score: data.keyword[kw],
        });
      });
    }

    // Trier par score décroissant, garder les 15 premiers
    return keywords
      .sort((a, b) => b.score - a.score)
      .slice(0, 15)
      .map(k => k.mot);

  } catch (err) {
    console.warn('[IA/tagging] API indisponible:', err.message);
    return _fallbackMotsCles(texteOffre);
  }
};

// ══════════════════════════════════════════════════════════════
// FONCTION 4 : Calculer le score de matching complet
// Combine similarité texte + correspondance compétences + bonus
// ══════════════════════════════════════════════════════════════
const calculerMatchingScore = async (profilCandidat, offre) => {
  try {
    // Construire le texte du profil candidat
    const texteProfilCandidat = _buildProfilText(profilCandidat);

    // Construire le texte de l'offre
    const texteOffre = _buildOffreText(offre);

    // Si pas de texte → score 0
    if (!texteProfilCandidat || !texteOffre) return 0;

    // 1. Score de similarité globale (poids 60%)
    const scoreSimilarite = await calculerSimilarite(
      texteProfilCandidat, texteOffre);

    // 2. Score de correspondance compétences (poids 25%)
    const scoreCompetences = _scoreCompetences(
      profilCandidat.competences || [],
      offre.competences_requises || []
    );

    // 3. Bonus localisation même ville (poids 10%)
    const bonusLocalisation = _bonusLocalisation(
      profilCandidat.ville, offre.localisation);

    // 4. Bonus expérience adaptée (poids 5%)
    const bonusExperience = _bonusExperience(
      profilCandidat.annees_experience,
      offre.niveau_experience_requis
    );

    // Score final pondéré
    const scoreFinal = Math.round(
      scoreSimilarite     * 0.60 +
      scoreCompetences    * 0.25 +
      bonusLocalisation   * 0.10 +
      bonusExperience     * 0.05
    );

    // Clamp entre 0 et 100
    return Math.min(100, Math.max(0, scoreFinal));

  } catch (err) {
    console.error('[IA/matching]', err.message);
    return 0;
  }
};

// ══════════════════════════════════════════════════════════════
// ALGORITHMES FALLBACK (si API indisponible)
// ══════════════════════════════════════════════════════════════

// Similarité basée sur les mots communs (Jaccard)
const _fallbackSimilarite = (texte1, texte2) => {
  const mots1 = new Set(
    texte1.toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(m => m.length > 3)
  );
  const mots2 = new Set(
    texte2.toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(m => m.length > 3)
  );

  const intersection = new Set([...mots1].filter(m => mots2.has(m)));
  const union = new Set([...mots1, ...mots2]);

  if (union.size === 0) return 0;

  const jaccard = intersection.size / union.size;
  // Amplifier le score (Jaccard est très conservateur)
  return Math.round(Math.min(100, jaccard * 300));
};

// Parser basique (extraction par regex)
const _fallbackParserCV = (cvUrl) => ({
  competences: [],
  experience:  [],
  formation:   [],
  langues:     ['Français'],
  email:       null,
  telephone:   null,
  score_ia:    null,
  raw:         null,
  fallback:    true,
});

// Mots-clés basiques (split simple)
const _fallbackMotsCles = (texte) => {
  const stopWords = new Set([
    'le', 'la', 'les', 'de', 'du', 'des', 'un', 'une', 'et',
    'en', 'pour', 'sur', 'avec', 'dans', 'par', 'au', 'aux',
    'que', 'qui', 'se', 'sa', 'son', 'ou', 'où', 'est', 'sont',
  ]);

  const mots = texte.toLowerCase()
    .replace(/[^\w\sàâéèêëîïôùûç]/g, ' ')
    .split(/\s+/)
    .filter(m => m.length > 4 && !stopWords.has(m));

  const freq = {};
  mots.forEach(m => { freq[m] = (freq[m] || 0) + 1; });

  return Object.entries(freq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 15)
    .map(([mot]) => mot);
};

// ══════════════════════════════════════════════════════════════
// HELPERS INTERNES
// ══════════════════════════════════════════════════════════════

const _buildProfilText = (profil) => {
  const parts = [];
  if (profil.titre)       parts.push(profil.titre);
  if (profil.about)       parts.push(profil.about);
  if (profil.competences) parts.push(profil.competences.join(' '));
  if (profil.experience)  parts.push(profil.experience.join(' '));
  if (profil.formation)   parts.push(profil.formation.join(' '));
  if (profil.texte_cv)    parts.push(profil.texte_cv);
  return parts.join(' ').trim();
};

const _buildOffreText = (offre) => {
  const parts = [];
  if (offre.titre)         parts.push(offre.titre);
  if (offre.description)   parts.push(offre.description);
  if (offre.exigences)     parts.push(offre.exigences);
  if (offre.competences_requises) {
    const comps = Array.isArray(offre.competences_requises)
      ? offre.competences_requises
      : Object.values(offre.competences_requises || {});
    parts.push(comps.join(' '));
  }
  return parts.join(' ').trim();
};

const _scoreCompetences = (compsCandidatRaw, compsOffreRaw) => {
  const compsCand = (Array.isArray(compsCandidatRaw)
    ? compsCandidatRaw
    : Object.values(compsCandidatRaw || {})
  ).map(c => c.toString().toLowerCase());

  const compsOffre = (Array.isArray(compsOffreRaw)
    ? compsOffreRaw
    : Object.values(compsOffreRaw || {})
  ).map(c => c.toString().toLowerCase());

  if (compsOffre.length === 0) return 50; // Pas d'exigences = score moyen

  let matches = 0;
  compsOffre.forEach(co => {
    if (compsCand.some(cc =>
      cc.includes(co) || co.includes(cc))) matches++;
  });

  return Math.round((matches / compsOffre.length) * 100);
};

const _bonusLocalisation = (villeCandidatRaw, localisationOffreRaw) => {
  if (!villeCandidatRaw || !localisationOffreRaw) return 50;
  const v1 = villeCandidatRaw.toLowerCase();
  const v2 = localisationOffreRaw.toLowerCase();
  return (v1.includes(v2) || v2.includes(v1)) ? 100 : 30;
};

const _bonusExperience = (anneesExperience, niveauRequis) => {
  if (!anneesExperience || !niveauRequis) return 50;
  const niveaux = {
    'sans_experience': 0,
    'junior': 1,
    '1_2_ans': 1.5,
    '3_5_ans': 4,
    '5_10_ans': 7,
    '10_ans_plus': 12,
  };
  const requis = niveaux[niveauRequis] || 0;
  if (anneesExperience >= requis) return 100;
  if (anneesExperience >= requis * 0.7) return 70;
  return 30;
};

// Normaliser les compétences extraites par le parser
const _extractCompetences = (data) => {
  const skills = data.skills || data.Skills || data.skill ||
    data.technical_skills || [];
  if (Array.isArray(skills)) return skills.slice(0, 20);
  if (typeof skills === 'object') return Object.values(skills).slice(0, 20);
  return [];
};

const _extractExperience = (data) => {
  const exp = data.experience || data.Experience ||
    data.work_experience || [];
  return Array.isArray(exp) ? exp.slice(0, 10) : [];
};

const _extractFormation = (data) => {
  const edu = data.education || data.Education ||
    data.formation || [];
  return Array.isArray(edu) ? edu.slice(0, 5) : [];
};

const _extractLangues = (data) => {
  const langs = data.languages || data.Languages ||
    data.langue || ['Français'];
  return Array.isArray(langs) ? langs.slice(0, 5) : ['Français'];
};

module.exports = {
  calculerSimilarite,
  analyserCV,
  extraireMotsCles,
  calculerMatchingScore,
};
```

---

## 4. Route Analyse CV — POST /api/cv/analyser

```javascript
// Ajouter dans backend/src/routes/cv.routes.js

const { analyserCV } = require('../services/ia.service');

// POST /api/cv/analyser
// Déclenché après l'upload d'un CV ou manuellement
router.post('/analyser', auth, async (req, res) => {
  try {
    const { supabase } = require('../config/supabase');

    // Récupérer le CV du candidat connecté
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

    const { data: cvData } = await supabase
      .from('cv')
      .select('id, fichier_url, texte_complet')
      .eq('chercheur_id', chercheur.id)
      .single();

    if (!cvData) {
      return res.status(404).json({
        success: false,
        message: 'Aucun CV trouvé. Uploadez votre CV d\'abord.'
      });
    }

    console.log('[analyserCV] Analyse du CV:', cvData.fichier_url);

    // Appel IA
    const resultat = await analyserCV(cvData.fichier_url);

    // Sauvegarder les résultats dans la BDD
    const { error: updateErr } = await supabase
      .from('cv')
      .update({
        competences_extrait: {
          competences: resultat.competences,
          experience:  resultat.experience,
          formation:   resultat.formation,
          langues:     resultat.langues,
          score_ia:    resultat.score_ia,
          fallback:    resultat.fallback || false,
          analyse_le:  new Date().toISOString(),
        },
        date_analyse:     new Date().toISOString(),
        date_modification: new Date().toISOString(),
      })
      .eq('id', cvData.id);

    if (updateErr) {
      console.error('[analyserCV] Erreur update:', updateErr);
    }

    return res.json({
      success: true,
      message: resultat.fallback
        ? 'CV analysé (mode basique — configurez l\'API pour plus de précision)'
        : 'CV analysé avec succès par l\'IA',
      data: {
        competences: resultat.competences,
        experience:  resultat.experience,
        formation:   resultat.formation,
        langues:     resultat.langues,
        nb_competences: resultat.competences.length,
        fallback:    resultat.fallback || false,
      }
    });

  } catch (err) {
    console.error('[POST /cv/analyser]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// Déclencher automatiquement l'analyse après l'upload
// Dans la route POST /api/cv/upload existante, AJOUTER à la fin :
// (après la sauvegarde en BDD)
//
// // Analyser le CV en arrière-plan (sans bloquer la réponse)
// setImmediate(async () => {
//   try {
//     const { analyserCV } = require('../services/ia.service');
//     const resultat = await analyserCV(cvUrl);
//     await supabase.from('cv').update({
//       competences_extrait: {
//         competences: resultat.competences,
//         ...
//       },
//       date_analyse: new Date().toISOString(),
//     }).eq('id', nouveauCV.id);
//     console.log('[CV Upload] Analyse IA terminée:', resultat.competences.length, 'compétences');
//   } catch (e) {
//     console.warn('[CV Upload] Analyse IA échouée (non bloquant):', e.message);
//   }
// });
```

---

## 5. Route Matching — POST /api/matching/score

```javascript
// backend/src/routes/matching.routes.js — NOUVEAU FICHIER

const express  = require('express');
const router   = express.Router();
const { auth } = require('../middleware/auth');
const { supabase } = require('../config/supabase');
const { calculerMatchingScore } = require('../services/ia.service');

// ══════════════════════════════════════════════════════════════
// POST /api/matching/score
// Calculer le score de matching entre le candidat connecté et une offre
// ══════════════════════════════════════════════════════════════
router.post('/score', auth, async (req, res) => {
  try {
    const { offre_id } = req.body;

    if (!offre_id) {
      return res.status(400).json({
        success: false, message: 'offre_id requis'
      });
    }

    // 1. Récupérer le profil du candidat
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select(`
        id, competences, disponibilite, niveau_etude,
        utilisateur:utilisateur_id (
          adresse, nom
        )
      `)
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.json({
        success: true,
        data: { score: 0, message: 'Profil candidat incomplet' }
      });
    }

    // 2. Récupérer le CV analysé
    const { data: cv } = await supabase
      .from('cv')
      .select('competences_extrait, texte_complet, niveau_experience')
      .eq('chercheur_id', chercheur.id)
      .single();

    // 3. Récupérer l'offre
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select(`
        titre, description, exigences,
        competences_requises, localisation,
        niveau_experience_requis, domaine
      `)
      .eq('id', offre_id)
      .single();

    if (!offre) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    // 4. Construire le profil pour le matching
    const competencesCV = cv?.competences_extrait?.competences || [];
    const competencesProfil = Array.isArray(chercheur.competences)
      ? chercheur.competences
      : Object.values(chercheur.competences || {});

    const profilCandidat = {
      titre:      cv?.niveau_experience || chercheur.niveau_etude || '',
      about:      '',
      competences: [...competencesCV, ...competencesProfil],
      experience: cv?.competences_extrait?.experience?.map(e =>
        typeof e === 'string' ? e : JSON.stringify(e)) || [],
      formation:  cv?.competences_extrait?.formation?.map(f =>
        typeof f === 'string' ? f : JSON.stringify(f)) || [],
      texte_cv:   cv?.texte_complet || '',
      ville:      chercheur.utilisateur?.adresse || '',
      annees_experience: _estimerAnneesExperience(cv?.niveau_experience),
    };

    // 5. Calculer le score
    const score = await calculerMatchingScore(profilCandidat, offre);

    // 6. Sauvegarder dans candidatures si existe
    await supabase
      .from('candidatures')
      .update({ score_compatibilite: score })
      .eq('chercheur_id', chercheur.id)
      .eq('offre_id', offre_id);

    // 7. Détail du score
    const detail = _buildScoreDetail(score);

    return res.json({
      success: true,
      data: {
        score,
        label:       detail.label,
        couleur:     detail.couleur,
        description: detail.description,
        offre_id,
      }
    });

  } catch (err) {
    console.error('[POST /matching/score]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// ══════════════════════════════════════════════════════════════
// GET /api/matching/scores-offres?offre_ids=id1,id2,id3
// Calculer les scores pour plusieurs offres en une fois
// ══════════════════════════════════════════════════════════════
router.get('/scores-offres', auth, async (req, res) => {
  try {
    const { offre_ids } = req.query;

    if (!offre_ids) {
      return res.json({ success: true, data: {} });
    }

    const ids = offre_ids.split(',').filter(Boolean).slice(0, 20);

    // Récupérer le profil une seule fois
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id, competences, disponibilite, niveau_etude')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.json({ success: true, data: {} });
    }

    const { data: cv } = await supabase
      .from('cv')
      .select('competences_extrait, texte_complet, niveau_experience')
      .eq('chercheur_id', chercheur.id)
      .single();

    const { data: offres } = await supabase
      .from('offres_emploi')
      .select('id, titre, description, exigences, competences_requises, localisation, niveau_experience_requis')
      .in('id', ids);

    const competencesCV = cv?.competences_extrait?.competences || [];
    const competencesProfil = Array.isArray(chercheur.competences)
      ? chercheur.competences
      : Object.values(chercheur.competences || {});

    const profilCandidat = {
      competences: [...competencesCV, ...competencesProfil],
      experience:  cv?.competences_extrait?.experience || [],
      texte_cv:    cv?.texte_complet || '',
      ville:       '',
      annees_experience: _estimerAnneesExperience(cv?.niveau_experience),
    };

    // Calculer les scores en parallèle
    const scores = {};
    await Promise.all((offres || []).map(async (offre) => {
      const score = await calculerMatchingScore(profilCandidat, offre);
      scores[offre.id] = {
        score,
        ..._buildScoreDetail(score),
      };
    }));

    return res.json({ success: true, data: scores });

  } catch (err) {
    console.error('[GET /matching/scores-offres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

// Helpers
const _estimerAnneesExperience = (niveau) => {
  const map = {
    'sans_experience': 0, 'debutant': 1,
    '1_2_ans': 1.5, '3_5_ans': 4,
    '5_10_ans': 7, '10_ans_plus': 12,
  };
  return map[niveau] || 0;
};

const _buildScoreDetail = (score) => {
  if (score >= 80) return {
    label: 'Excellent match',
    couleur: '#10B981',
    description: 'Votre profil correspond très bien à cette offre',
  };
  if (score >= 60) return {
    label: 'Bon match',
    couleur: '#1A56DB',
    description: 'Votre profil correspond bien à cette offre',
  };
  if (score >= 40) return {
    label: 'Match moyen',
    couleur: '#F59E0B',
    description: 'Votre profil correspond partiellement à cette offre',
  };
  return {
    label: 'Faible match',
    couleur: '#EF4444',
    description: 'Votre profil ne correspond pas bien à cette offre',
  };
};

module.exports = router;
```

### Enregistrer la route dans `backend/src/routes/index.js`

```javascript
router.use('/matching', require('./matching.routes'));
```

---

## 6. Route Suggestions — GET /api/offres/suggestions

```javascript
// Remplacer/améliorer la route existante GET /api/offres/suggestions

router.get('/suggestions', auth, async (req, res) => {
  try {
    const { limite = 10 } = req.query;
    const { supabase }    = require('../config/supabase');
    const { calculerMatchingScore, getRapidApiKeys } =
      require('../services/ia.service');

    // 1. Vérifier le seuil minimum
    const keys = await getRapidApiKeys();
    const seuil = keys.seuilMatching || 40;

    // 2. Profil du candidat
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id, competences, disponibilite, niveau_etude')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      // Pas de profil → retourner les offres récentes
      const { data: offresRecentes } = await supabase
        .from('offres_emploi')
        .select('*, entreprise:entreprise_id(nom_entreprise, logo_url)')
        .eq('statut', 'publiee')
        .order('date_publication', { ascending: false })
        .limit(parseInt(limite));

      return res.json({
        success: true,
        data: (offresRecentes || []).map(o => ({
          ...o, score_compatibilite: null, ia_active: false
        }))
      });
    }

    // 3. CV du candidat
    const { data: cv } = await supabase
      .from('cv')
      .select('competences_extrait, texte_complet, niveau_experience')
      .eq('chercheur_id', chercheur.id)
      .single();

    // 4. Offres publiées (candidatures déjà faites exclues)
    const { data: candidaturesExistantes } = await supabase
      .from('candidatures')
      .select('offre_id')
      .eq('chercheur_id', chercheur.id);

    const offresPostulees = (candidaturesExistantes || [])
      .map(c => c.offre_id);

    let query = supabase
      .from('offres_emploi')
      .select(`
        id, titre, description, exigences, competences_requises,
        localisation, type_contrat, salaire_min, salaire_max,
        devise, domaine, niveau_experience_requis,
        date_publication, date_limite, en_vedette,
        entreprise:entreprise_id (
          id, nom_entreprise, logo_url, secteur_activite
        )
      `)
      .eq('statut', 'publiee')
      .order('date_publication', { ascending: false })
      .limit(50); // Récupérer plus pour filtrer après

    if (offresPostulees.length > 0) {
      query = query.not('id', 'in', `(${offresPostulees.join(',')})`);
    }

    const { data: offres } = await query;

    if (!offres || offres.length === 0) {
      return res.json({ success: true, data: [] });
    }

    // 5. Construire le profil candidat
    const competencesCV = cv?.competences_extrait?.competences || [];
    const competencesProfil = Array.isArray(chercheur.competences)
      ? chercheur.competences
      : Object.values(chercheur.competences || {});

    const profilCandidat = {
      competences: [...competencesCV, ...competencesProfil],
      texte_cv:    cv?.texte_complet || '',
      experience:  cv?.competences_extrait?.experience || [],
      annees_experience: _estimerAnneesExperience(cv?.niveau_experience),
    };

    // 6. Calculer les scores en parallèle
    const offresAvecScores = await Promise.all(
      offres.map(async (offre) => {
        const score = await calculerMatchingScore(profilCandidat, offre);
        return { ...offre, score_compatibilite: score, ia_active: true };
      })
    );

    // 7. Filtrer par seuil et trier par score décroissant
    const suggestions = offresAvecScores
      .filter(o => o.score_compatibilite >= seuil)
      .sort((a, b) => b.score_compatibilite - a.score_compatibilite)
      .slice(0, parseInt(limite));

    // Si pas assez de résultats au-dessus du seuil → compléter
    if (suggestions.length < 3) {
      const complementaires = offresAvecScores
        .filter(o => o.score_compatibilite < seuil)
        .sort((a, b) => b.score_compatibilite - a.score_compatibilite)
        .slice(0, 5);
      suggestions.push(...complementaires);
    }

    return res.json({
      success: true,
      data: suggestions.slice(0, parseInt(limite)),
      meta: {
        seuil_utilise: seuil,
        total_analyse: offres.length,
        total_suggestions: suggestions.length,
      }
    });

  } catch (err) {
    console.error('[GET /offres/suggestions]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});
```

---

## 7. Automatisation — Déclencher l'IA automatiquement

### 7.1 Analyser le CV automatiquement après upload

```javascript
// Dans backend/src/routes/cv.routes.js
// Après l'upload réussi, ajouter AVANT le return res.json() :

// Analyser le CV en arrière-plan (non bloquant)
setImmediate(async () => {
  try {
    const { analyserCV } = require('../services/ia.service');
    console.log('[CV] Démarrage analyse IA en arrière-plan...');

    const resultat = await analyserCV(cvUrl);

    await supabase.from('cv').update({
      competences_extrait: {
        competences: resultat.competences,
        experience:  resultat.experience,
        formation:   resultat.formation,
        langues:     resultat.langues,
        score_ia:    resultat.score_ia,
        fallback:    resultat.fallback || false,
        analyse_le:  new Date().toISOString(),
      },
      date_analyse: new Date().toISOString(),
    }).eq('id', nouveauCV.id);

    console.log('[CV] Analyse IA terminée:',
      resultat.competences.length, 'compétences extraites');
  } catch (e) {
    console.warn('[CV] Analyse IA échouée (non bloquant):', e.message);
  }
});
```

### 7.2 Calculer le score à chaque candidature

```javascript
// Dans backend/src/routes/candidatures.routes.js (ou controller)
// Après la création d'une candidature, calculer le score :

// Après INSERT candidature réussi :
setImmediate(async () => {
  try {
    const { calculerMatchingScore } = require('../services/ia.service');

    // Récupérer profil + offre
    const [chercheurData, offreData, cvData] = await Promise.all([
      supabase.from('chercheurs_emploi')
        .select('competences, niveau_etude')
        .eq('utilisateur_id', req.user.id).single(),
      supabase.from('offres_emploi')
        .select('titre, description, competences_requises, localisation, niveau_experience_requis')
        .eq('id', offre_id).single(),
      supabase.from('cv')
        .select('competences_extrait, texte_complet, niveau_experience')
        .eq('chercheur_id', nouvelleCandidature.chercheur_id).single(),
    ]);

    const compCV = cvData.data?.competences_extrait?.competences || [];
    const compProfil = Array.isArray(chercheurData.data?.competences)
      ? chercheurData.data.competences
      : Object.values(chercheurData.data?.competences || {});

    const score = await calculerMatchingScore(
      {
        competences: [...compCV, ...compProfil],
        texte_cv:    cvData.data?.texte_complet || '',
        annees_experience: 0,
      },
      offreData.data
    );

    await supabase.from('candidatures')
      .update({ score_compatibilite: score })
      .eq('id', nouvelleCandidature.id);

    console.log('[Candidature] Score IA calculé:', score + '%');
  } catch (e) {
    console.warn('[Candidature] Score IA échoué:', e.message);
  }
});
```

---

## 8. Flutter — Afficher les scores IA partout

### 8.1 Service Flutter pour le matching

```dart
// lib/services/matching_service.dart

class MatchingService {
  final String _base = '${ApiConfig.baseUrl}/api';

  // Calculer le score pour une offre
  Future<Map<String, dynamic>> getScore(
    String token, String offreId) async {
    final res = await http.post(
      Uri.parse('$_base/matching/score'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'offre_id': offreId}),
    );
    return jsonDecode(res.body);
  }

  // Obtenir les scores pour plusieurs offres en une fois
  Future<Map<String, dynamic>> getScoresMultiples(
    String token, List<String> offreIds) async {
    final ids = offreIds.join(',');
    final res = await http.get(
      Uri.parse('$_base/matching/scores-offres?offre_ids=$ids'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }

  // Analyser le CV
  Future<Map<String, dynamic>> analyserCV(String token) async {
    final res = await http.post(
      Uri.parse('$_base/cv/analyser'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }

  // Obtenir les suggestions IA
  Future<Map<String, dynamic>> getSuggestions(
    String token, {int limite = 10}) async {
    final res = await http.get(
      Uri.parse('$_base/offres/suggestions?limite=$limite'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(res.body);
  }
}
```

### 8.2 Widget Score IA — Badge animé

```dart
// lib/shared/widgets/ia_score_badge.dart

class IAScoreBadge extends StatefulWidget {
  final int score;
  final bool large; // grande version pour la page détail
  const IAScoreBadge({super.key, required this.score, this.large = false});
  @override
  State<IAScoreBadge> createState() => _IAScoreBadgeState();
}

class _IAScoreBadgeState extends State<IAScoreBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _color {
    if (widget.score >= 80) return const Color(0xFF10B981);
    if (widget.score >= 60) return const Color(0xFF1A56DB);
    if (widget.score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _label {
    if (widget.score >= 80) return 'Excellent';
    if (widget.score >= 60) return 'Bon match';
    if (widget.score >= 40) return 'Moyen';
    return 'Faible';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.large) return _buildLarge();
    return _buildCompact();
  }

  Widget _buildCompact() => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF1A56DB)),
        const SizedBox(width: 4),
        Text('${(widget.score * _anim.value).toInt()}% · $_label',
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: _color)),
      ]),
    ),
  );

  Widget _buildLarge() => Column(children: [
    // Cercle de progression
    SizedBox(
      width: 80, height: 80,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: widget.score / 100 * _anim.value,
            strokeWidth: 7,
            backgroundColor: _color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(_color),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${(widget.score * _anim.value).toInt()}',
              style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: _color)),
            Text('%', style: GoogleFonts.inter(
              fontSize: 10, color: _color)),
          ]),
        ]),
      ),
    ),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF1A56DB)),
        const SizedBox(width: 5),
        Text(_label, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: _color)),
      ]),
    ),
  ]);
}
```

### 8.3 Intégrer le score dans les pages Candidat

```dart
// lib/screens/candidat/pages/recherche_offres_page.dart
// Charger les scores IA pour toutes les offres affichées

class _RechercheOffresPageState extends State<RechercheOffresPage> {
  final MatchingService _matchingSvc = MatchingService();
  List<dynamic> _offres = [];
  Map<String, dynamic> _scores = {}; // offreId → {score, label, couleur}

  Future<void> _loadOffresEtScores() async {
    // 1. Charger les offres
    final offresRes = await _loadOffres();
    final offres = offresRes['data'] as List? ?? [];
    setState(() => _offres = offres);

    // 2. Calculer les scores IA en arrière-plan
    if (offres.isNotEmpty) {
      final token = context.read<AuthProvider>().token ?? '';
      final ids = offres.map((o) => o['id'] as String).toList();

      try {
        final scoresRes = await _matchingSvc.getScoresMultiples(token, ids);
        if (scoresRes['success'] == true) {
          setState(() => _scores = scoresRes['data'] ?? {});
        }
      } catch (e) {
        print('[Scores IA] Erreur non bloquante: $e');
      }
    }
  }

  // Dans la OffreListCard, passer le score :
  // IAScoreBadge(score: _scores[offre['id']]?['score'] ?? 0)
}

// lib/screens/candidat/pages/offre_detail_page.dart
// Afficher le grand badge score + compétences correspondantes

class _OffreDetailPageState extends State<OffreDetailPage> {
  int? _score;
  List<String> _competencesMatch    = [];
  List<String> _competencesMissing  = [];

  Future<void> _loadScore() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await MatchingService().getScore(token, widget.jobId);

      if (res['success'] == true) {
        setState(() {
          _score = res['data']['score'];
        });
      }
    } catch (_) {}
  }

  // Dans le build, côté droit :
  // if (_score != null) IAScoreBadge(score: _score!, large: true)
}

// lib/screens/candidat/pages/recommandations_ia_page.dart
// Utiliser GET /api/offres/suggestions directement

class _RecommandationsPageState extends State<RecommandationsIAPage> {
  List<dynamic> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await MatchingService().getSuggestions(
        token, limite: 20);
      setState(() {
        _suggestions = res['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}
```

### 8.4 Page Profil Candidat — Analyse CV automatique

```dart
// Dans profil_cv_page.dart, section "Mon CV"
// Après l'upload du CV, afficher les résultats de l'analyse IA

Widget _buildCvAnalyseSection(Map<String, dynamic>? cv) {
  if (cv == null) return const SizedBox.shrink();

  final competences = cv['competences_extrait']?['competences']
      as List? ?? [];
  final analyseDate  = cv['date_analyse'];
  final isFallback   = cv['competences_extrait']?['fallback'] == true;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF1E3A8A).withOpacity(0.05),
          const Color(0xFF1A56DB).withOpacity(0.02),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF1A56DB).withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
            borderRadius: BorderRadius.circular(100)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text('Analyse IA', style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: Colors.white)),
          ]),
        ),
        const SizedBox(width: 10),
        Text('Compétences détectées dans votre CV',
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A))),
        const Spacer(),
        // Bouton ré-analyser
        TextButton.icon(
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('Ré-analyser'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1A56DB),
            textStyle: GoogleFonts.inter(fontSize: 12),
          ),
          onPressed: () => _reanalyserCV(),
        ),
      ]),

      if (isFallback) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8)),
          child: Text(
            '⚠️ Mode basique — Configurez l\'API dans l\'admin pour plus de précision',
            style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFF92400E))),
        ),
      ],
      const SizedBox(height: 12),

      if (competences.isEmpty)
        Text('Aucune compétence détectée. Votre CV sera analysé bientôt.',
          style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B)))
      else
        Wrap(spacing: 8, runSpacing: 8, children: competences
          .cast<String>()
          .map((skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFBFDBFE))),
            child: Text(skill, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: const Color(0xFF1E40AF))),
          )).toList()),

      if (analyseDate != null) ...[
        const SizedBox(height: 8),
        Text('Analysé le ${_formatDate(analyseDate)}',
          style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF94A3B8))),
      ],
    ]),
  );
}

Future<void> _reanalyserCV() async {
  final token = context.read<AuthProvider>().token ?? '';
  setState(() => _isAnalysing = true);
  try {
    await MatchingService().analyserCV(token);
    await _loadProfil(); // Recharger
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('CV ré-analysé avec succès !'),
      backgroundColor: Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
    ));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Erreur: $e'),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
    ));
  } finally {
    setState(() => _isAnalysing = false);
  }
}
```

---

## 9. Tests des endpoints IA

### Fichier `backend/tests/ia.test.http`

```http
### Variables
@baseUrl = http://localhost:3000/api
@tokenCandidat = VOTRE_JWT_CANDIDAT
@offreId = UUID_OFFRE_ICI

### ── TEST 1 : Analyser son CV
POST {{baseUrl}}/cv/analyser
Authorization: Bearer {{tokenCandidat}}

###

### ── TEST 2 : Score matching sur une offre
POST {{baseUrl}}/matching/score
Authorization: Bearer {{tokenCandidat}}
Content-Type: application/json

{"offre_id": "{{offreId}}"}

###

### ── TEST 3 : Scores pour plusieurs offres
GET {{baseUrl}}/matching/scores-offres?offre_ids=id1,id2,id3
Authorization: Bearer {{tokenCandidat}}

###

### ── TEST 4 : Suggestions personnalisées
GET {{baseUrl}}/offres/suggestions?limite=10
Authorization: Bearer {{tokenCandidat}}

###

### ── TEST 5 : Tester la connexion API depuis l'admin
POST {{baseUrl}}/admin/parametres/tester-ia
Authorization: Bearer {{VOTRE_JWT_ADMIN}}

###
```

### Vérifications dans le terminal

```bash
# Après avoir configuré la clé API dans l'admin :

# 1. Redémarrer le backend
cd backend && npm run dev

# 2. Vérifier les logs au démarrage
# Vous devriez voir :
# ✅ Bucket "logos" OK (public: true)
# ✅ Bucket "bannieres" OK (public: true)

# 3. Tester l'API similarity directement
curl "https://twinword-text-similarity-v1.p.rapidapi.com/similarity/?text1=flutter+developer&text2=mobile+developer+dart" \
  -H "X-RapidAPI-Key: VOTRE_CLE" \
  -H "X-RapidAPI-Host: twinword-text-similarity-v1.p.rapidapi.com"

# Réponse attendue :
# {"result_msg":"Success","similarity":0.756}
```

---

## 10. Critères d'Acceptation

### ✅ Configuration
- [ ] Variable `RAPIDAPI_KEY` dans `.env`
- [ ] `RAPIDAPI_SIMILARITY_HOST` dans `.env`
- [ ] Clé sauvegardée dans les paramètres admin (chiffrée)
- [ ] Bouton "Tester la connexion" retourne ✅

### ✅ Analyse CV
- [ ] Upload CV → analyse automatique en arrière-plan
- [ ] `POST /api/cv/analyser` retourne les compétences extraites
- [ ] Compétences affichées dans le profil candidat (page Mon CV)
- [ ] Bouton "Ré-analyser" fonctionnel
- [ ] Mode fallback si API indisponible (pas de crash)

### ✅ Score Matching
- [ ] `POST /api/matching/score` retourne un score 0-100
- [ ] Score sauvegardé dans `candidatures.score_compatibilite`
- [ ] Score calculé automatiquement à chaque nouvelle candidature
- [ ] `GET /api/matching/scores-offres` retourne les scores en batch

### ✅ Affichage Flutter
- [ ] `IAScoreBadge` affiché sur chaque card d'offre (recherche)
- [ ] Grand badge avec cercle animé sur la page détail offre
- [ ] Score visible dans la liste Mes Candidatures
- [ ] Compétences extraites affichées dans Mon Profil CV
- [ ] Couleur badge : vert ≥80% · bleu ≥60% · orange ≥40% · rouge <40%

### ✅ Suggestions Automatiques
- [ ] `GET /api/offres/suggestions` retourne offres triées par score
- [ ] Page Recommandations IA affiche les offres avec scores
- [ ] Dashboard candidat affiche les 4 meilleures suggestions IA
- [ ] Mode dégradé si API non configurée (offres récentes)

### ✅ Robustesse
- [ ] Si API RapidAPI down → fallback automatique (pas de crash)
- [ ] Si profil incomplet → score 0 (pas d'erreur)
- [ ] Si pas de CV → suggestions offres récentes
- [ ] Logs clairs dans le terminal pour chaque appel IA

---

*PRD EmploiConnect v4.0 — Intégration IA & Matching*
*RapidAPI : Twinword Text Similarity + Resume Parser + Topic Tagging*
*Cursor / Kirsoft AI — Phase 8*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
