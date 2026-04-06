/**
 * NLP via RapidAPI
 * - Parsing de CV (Resume Parser API) → compétences, expérience, éducation
 * - Similarité sémantique (Text Similarity API) → score 0-1 entre deux textes pour le matching
 *
 * Sans RAPIDAPI_KEY, les fonctions retournent null et le backend utilise la logique locale.
 */

import { getRapidApiKeys } from '../config/rapidApi.js';

function getHeaders(host, apiKey) {
  return {
    'X-RapidAPI-Key': apiKey,
    'X-RapidAPI-Host': host,
  };
}

/**
 * Appel à l'API Text Similarity (Twinword ou compatible RapidAPI)
 * Compare deux textes et retourne un score de similarité sémantique entre 0 et 1.
 * @param {string} text1 - Ex: résumé CV ou compétences du candidat
 * @param {string} text2 - Ex: exigences de l'offre
 * @returns {Promise<number|null>} Score 0-1 ou null si API désactivée/erreur
 */
export async function getTextSimilarityScore(text1, text2) {
  const keys = await getRapidApiKeys();
  if (!keys.apiKey || !text1?.trim() || !text2?.trim()) return null;

  const t1 = String(text1).trim().slice(0, 5000);
  const t2 = String(text2).trim().slice(0, 5000);
  if (!t1 || !t2) return null;

  try {
    const host = String(keys.similarityHost || '').replace(/^https?:\/\//, '');
    if (!host) return null;
    const res = await fetch(
      `https://${host}/similarity/?text1=${encodeURIComponent(t1)}&text2=${encodeURIComponent(t2)}`,
      {
      method: 'GET',
      headers: getHeaders(host, keys.apiKey),
    }
    );

    if (!res.ok) {
      console.warn('RapidAPI Similarity:', res.status, await res.text());
      return null;
    }

    const data = await res.json();
    const score = data.similarity ?? data.value ?? data.score ?? data.result;
    if (typeof score === 'number' && score >= 0 && score <= 1) return score;
    if (typeof score === 'number') return Math.max(0, Math.min(1, score / 100));
    return null;
  } catch (err) {
    console.warn('RapidAPI Similarity error:', err.message);
    return null;
  }
}

/**
 * Appel à l'API Resume Parser (RapidAPI)
 * Envoie le fichier CV et récupère un JSON structuré (compétences, expérience, etc.).
 * @param {Buffer} fileBuffer - Contenu du fichier (PDF ou DOCX)
 * @param {string} filename - Nom du fichier (ex: cv.pdf)
 * @param {string} mimeType - application/pdf ou application/vnd.openxmlformats-...
 * @returns {Promise<{ competences: string[], experience?: object[], domaine_activite?: string, niveau_experience?: string }|null>}
 */
export async function parseResumeWithApi(fileBuffer, filename, mimeType) {
  const keys = await getRapidApiKeys();
  if (!keys.apiKey || !fileBuffer?.length) return null;

  try {
    const form = new FormData();
    const blob = new Blob([fileBuffer], { type: mimeType });
    form.append('file', blob, filename || 'resume.pdf');

    const parserHost = String(keys.parserHost || '').replace(/^https?:\/\//, '');
    if (!parserHost) return null;
    const path = (process.env.RAPIDAPI_RESUME_PARSER_PATH || '').trim() || '/';
    const url = `https://${parserHost}${path.startsWith('/') ? path : '/' + path}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: getHeaders(parserHost, keys.apiKey),
      body: form,
    });

    if (!res.ok) {
      console.warn('RapidAPI Resume Parser:', res.status, await res.text());
      return null;
    }

    const data = await res.json();

    const skills = data.skills ?? data.Skills ?? data.competences ?? [];
    const competences = Array.isArray(skills)
      ? skills.map((s) => (typeof s === 'string' ? s : s?.name ?? s?.skill ?? String(s))).filter(Boolean)
      : [];

    const experience = data.experience ?? data.Experience ?? data.work_experience ?? data.employment ?? null;
    const expArray = Array.isArray(experience) ? experience : experience ? [experience] : [];

    const education = data.education ?? data.Education ?? null;
    const domaine = data.domain ?? data.domaine_activite ?? data.industry ?? data.job_title ?? null;
    const niveau = data.experience_level ?? data.niveau_experience ?? data.years_of_experience ?? null;

    return {
      competences: competences.slice(0, 50),
      experience: expArray.length ? expArray : undefined,
      domaine_activite: typeof domaine === 'string' ? domaine : null,
      niveau_experience: typeof niveau === 'string' ? niveau : (niveau != null ? String(niveau) : null),
    };
  } catch (err) {
    console.warn('RapidAPI Resume Parser error:', err.message);
    return null;
  }
}
