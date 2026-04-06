import axios from 'axios';
import { getRapidApiKeys } from '../config/rapidApi.js';

const STOP_WORDS = new Set([
  'le', 'la', 'les', 'de', 'du', 'des', 'un', 'une', 'et', 'en', 'pour',
  'sur', 'avec', 'dans', 'par', 'au', 'aux', 'que', 'qui', 'se', 'sa',
  'son', 'ou', 'où', 'est', 'sont', 'the', 'and', 'for', 'with',
]);

function asArray(value) {
  if (Array.isArray(value)) return value;
  if (value && typeof value === 'object') return Object.values(value);
  return [];
}

const _toArray = (val) => {
  if (!val) return [];
  if (Array.isArray(val)) return val;
  if (typeof val === 'string') return val.split(',').map((s) => s.trim()).filter(Boolean);
  if (typeof val === 'object') return Object.values(val);
  return [];
};

function normalizeText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function splitTerms(value) {
  return normalizeText(value)
    .split(' ')
    .map((w) => w.trim())
    .filter((w) => w.length > 2 && !STOP_WORDS.has(w));
}

function _fallbackSimilarite(texte1, texte2) {
  const a = new Set(splitTerms(texte1));
  const b = new Set(splitTerms(texte2));
  if (!a.size || !b.size) return 0;
  const inter = new Set([...a].filter((x) => b.has(x)));
  const union = new Set([...a, ...b]);
  const jaccard = union.size ? (inter.size / union.size) : 0;
  return Math.max(0, Math.min(100, Math.round(jaccard * 300)));
}

function _fallbackMotsCles(text) {
  const freq = {};
  for (const term of splitTerms(text)) {
    freq[term] = (freq[term] || 0) + 1;
  }
  return Object.entries(freq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 15)
    .map(([term]) => term);
}

function _fallbackParserCV() {
  return {
    competences: [],
    experience: [],
    formation: [],
    langues: ['Français'],
    email: null,
    telephone: null,
    nom: null,
    score_ia: null,
    raw: null,
    fallback: true,
    source: 'fallback',
  };
}

function extractCompetences(data) {
  const skills = data?.skills || data?.Skills || data?.technical_skills || data?.skill || [];
  return asArray(skills)
    .map((x) => (typeof x === 'string' ? x : x?.name || x?.skill || String(x || '')))
    .filter(Boolean)
    .slice(0, 40);
}

function extractExperience(data) {
  return asArray(data?.experience || data?.Experience || data?.work_experience || data?.employment)
    .slice(0, 10);
}

function extractFormation(data) {
  return asArray(data?.education || data?.Education || data?.formation)
    .slice(0, 8);
}

function extractLangues(data) {
  const values = asArray(data?.languages || data?.Languages || data?.langue);
  return values.length ? values.slice(0, 8) : ['Français'];
}

function buildProfilText(profil = {}) {
  const parts = [];
  if (profil.titre) parts.push(profil.titre);
  if (profil.about) parts.push(profil.about);
  if (profil.texte_cv) parts.push(profil.texte_cv);
  if (profil.texteComplet) parts.push(profil.texteComplet);
  const competences = asArray(profil.competences);
  const experience = asArray(profil.experience);
  const formation = asArray(profil.formation);
  if (competences.length) parts.push(competences.join(' '));
  if (experience.length) parts.push(experience.map((e) => (typeof e === 'string' ? e : JSON.stringify(e))).join(' '));
  if (formation.length) parts.push(formation.map((f) => (typeof f === 'string' ? f : JSON.stringify(f))).join(' '));
  return parts.join(' ').trim();
}

function buildOffreText(offre = {}) {
  const parts = [];
  if (offre.titre) parts.push(offre.titre);
  if (offre.description) parts.push(offre.description);
  if (offre.exigences) parts.push(offre.exigences);
  const comps = asArray(offre.competences_requises);
  if (comps.length) parts.push(comps.join(' '));
  return parts.join(' ').trim();
}

function scoreCompetences(compsCandidatRaw, compsOffreRaw) {
  const cand = asArray(compsCandidatRaw).map((c) => normalizeText(c)).filter(Boolean);
  const req = asArray(compsOffreRaw).map((c) => normalizeText(c)).filter(Boolean);
  if (!req.length) return 50;
  let matched = 0;
  for (const r of req) {
    if (cand.some((c) => c.includes(r) || r.includes(c))) matched += 1;
  }
  return Math.round((matched / req.length) * 100);
}

function bonusLocalisation(ville, localisation) {
  const a = normalizeText(ville);
  const b = normalizeText(localisation);
  if (!a || !b) return 50;
  return (a.includes(b) || b.includes(a)) ? 100 : 30;
}

function bonusExperience(anneesExperience, niveauRequis) {
  if (anneesExperience == null || !niveauRequis) return 50;
  const map = {
    sans_experience: 0,
    debutant: 1,
    junior: 1,
    '1_2_ans': 1.5,
    '3_5_ans': 4,
    '5_10_ans': 7,
    '10_ans_plus': 12,
  };
  const requis = map[String(niveauRequis)] ?? 0;
  if (anneesExperience >= requis) return 100;
  if (anneesExperience >= requis * 0.7) return 70;
  return 30;
}

export async function calculerSimilarite(texte1, texte2) {
  try {
    const keys = await getRapidApiKeys();
    if (!keys.apiKey || !keys.similarityHost) {
      return _fallbackSimilarite(texte1, texte2);
    }

    const url = new URL(`https://${keys.similarityHost}/similarity/`);
    url.searchParams.set('text1', String(texte1 || '').slice(0, 2000));
    url.searchParams.set('text2', String(texte2 || '').slice(0, 2000));

    const ctrl = new AbortController();
    const timeout = setTimeout(() => ctrl.abort(), 8000);
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        'X-RapidAPI-Key': keys.apiKey,
        'X-RapidAPI-Host': keys.similarityHost,
      },
      signal: ctrl.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) return _fallbackSimilarite(texte1, texte2);

    const data = await res.json();
    const similarity = data?.similarity;
    if (typeof similarity === 'number') {
      return Math.max(0, Math.min(100, Math.round(similarity * 100)));
    }
    return _fallbackSimilarite(texte1, texte2);
  } catch (_) {
    return _fallbackSimilarite(texte1, texte2);
  }
}

export async function analyserCV(cvUrl) {
  try {
    const keys = await getRapidApiKeys();
    if (!keys.apiKey || !keys.parserHost) {
      console.warn('[IA/parser] Host non configuré → fallback basique');
      return _fallbackParserCV();
    }
    console.log('[IA/parser] Appel Resume Parser API...');
    const response = await axios.request({
      method: 'POST',
      url: `https://${keys.parserHost}/resume/parse`,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': keys.apiKey,
        'X-RapidAPI-Host': keys.parserHost,
      },
      data: { url: cvUrl },
      timeout: 20000,
    });
    const data = response.data || {};
    console.log('[IA/parser] Réponse reçue. Clés:', Object.keys(data));

    const competences = [];
    if (data.skills) competences.push(..._toArray(data.skills));
    if (data.Skills) competences.push(..._toArray(data.Skills));
    if (data.technical_skills) competences.push(..._toArray(data.technical_skills));
    if (data.soft_skills) competences.push(..._toArray(data.soft_skills));
    if (data.keywords) competences.push(..._toArray(data.keywords));

    const resultat = {
      competences: [...new Set(competences.map((c) => String(c).trim()).filter(Boolean))].slice(0, 25),
      experience: _toArray(
        data.experience || data.Experience || data.work_experience || data.workExperience || [],
      ).map((e) => (typeof e === 'string' ? e : JSON.stringify(e))).slice(0, 10),
      formation: _toArray(
        data.education || data.Education || data.formation || [],
      ).map((f) => (typeof f === 'string' ? f : JSON.stringify(f))).slice(0, 5),
      langues: _toArray(data.languages || data.Languages || ['Français']).slice(0, 5),
      email: data.email || data.Email || null,
      telephone: data.phone || data.Phone || data.telephone || null,
      nom: data.name || data.Name || null,
      score_ia: data.score || null,
      raw: data,
      fallback: false,
      source: 'resume-parser-api',
    };
    console.log('[IA/parser] Succès:', resultat.competences.length, 'compétences extraites');
    return resultat;
  } catch (err) {
    if (err.response?.status === 403) {
      console.error('[IA/parser] ❌ Clé API invalide ou quota dépassé');
    } else if (err.response?.status === 429) {
      console.error('[IA/parser] ❌ Limite de requêtes atteinte (plan gratuit)');
    } else if (err.code === 'ECONNABORTED') {
      console.error('[IA/parser] ❌ Timeout — le CV est peut-être trop volumineux');
    } else {
      console.warn('[IA/parser] API indisponible:', err.message);
    }
    return _fallbackParserCV();
  }
}

export async function extraireMotsCles(texteOffre) {
  try {
    const keys = await getRapidApiKeys();
    if (!keys.apiKey || !keys.taggingHost) {
      console.warn('[IA/tagging] Host non configuré → fallback');
      return _fallbackMotsCles(texteOffre);
    }
    console.log('[IA/tagging] Appel Topic Tagging API...');
    const texte = String(texteOffre || '').replace(/\s+/g, ' ').trim().slice(0, 3000);
    const response = await axios.request({
      method: 'GET',
      url: `https://${keys.taggingHost}/classify/`,
      params: { text: texte },
      headers: {
        'X-RapidAPI-Key': keys.apiKey,
        'X-RapidAPI-Host': keys.taggingHost,
      },
      timeout: 10000,
    });
    const data = response.data || {};
    console.log('[IA/tagging] Réponse reçue. Topics:', Object.keys(data.topic || {}).length);

    const keywords = [];
    if (data.keyword && typeof data.keyword === 'object') {
      Object.entries(data.keyword).forEach(([mot, score]) => {
        keywords.push({ mot, score: Number.parseFloat(score) || 0 });
      });
    }
    if (data.topic && typeof data.topic === 'object') {
      Object.entries(data.topic).forEach(([mot, score]) => {
        if (!keywords.find((k) => k.mot === mot)) {
          keywords.push({ mot, score: (Number.parseFloat(score) || 0) * 0.8 });
        }
      });
    }
    const result = keywords
      .sort((a, b) => b.score - a.score)
      .slice(0, 15)
      .map((k) => k.mot);
    console.log('[IA/tagging] Mots-clés extraits:', result.join(', '));
    return result.length ? result : _fallbackMotsCles(texteOffre);
  } catch (err) {
    if (err.response?.status === 429) {
      console.error('[IA/tagging] ❌ Quota dépassé');
    } else {
      console.warn('[IA/tagging] API indisponible:', err.message);
    }
    return _fallbackMotsCles(texteOffre);
  }
}

export async function calculerMatchingScore(profilCandidat, offre) {
  const profilText = buildProfilText(profilCandidat);
  const offreText = buildOffreText(offre);
  if (!profilText || !offreText) return 0;

  const scoreSimilarite = await calculerSimilarite(profilText, offreText);
  const scoreComp = scoreCompetences(profilCandidat?.competences, offre?.competences_requises);
  const bonusLoc = bonusLocalisation(profilCandidat?.ville, offre?.localisation);
  const bonusExp = bonusExperience(
    profilCandidat?.annees_experience,
    offre?.niveau_experience_requis,
  );

  const score = Math.round(
    scoreSimilarite * 0.6
    + scoreComp * 0.25
    + bonusLoc * 0.1
    + bonusExp * 0.05,
  );
  return Math.max(0, Math.min(100, score));
}

