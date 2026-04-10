import axios from 'axios';
import FormData from 'form-data';
import http from 'node:http';
import https from 'node:https';
import crypto from 'crypto';
import { getRapidApiKeys, invalidateKeysCache } from '../config/rapidApi.js';
import { supabase, BUCKET_CV } from '../config/supabase.js';

const STOP_WORDS = new Set([
  'le', 'la', 'les', 'de', 'du', 'des', 'un', 'une', 'et', 'en', 'pour',
  'sur', 'avec', 'dans', 'par', 'au', 'aux', 'que', 'qui', 'se', 'sa',
  'son', 'ou', 'où', 'est', 'sont', 'the', 'and', 'for', 'with',
]);

const MIME_BY_EXT = {
  pdf: 'application/pdf',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  doc: 'application/msword',
  txt: 'text/plain',
};

function asArray(value) {
  if (Array.isArray(value)) return value;
  if (value && typeof value === 'object') return Object.values(value);
  return [];
}

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

function _fallbackParserCV(erreur = null) {
  return {
    competences: [],
    experience: [],
    formation: [],
    langues: ['Français'],
    resume_profil: '',
    email: null,
    telephone: null,
    nom: null,
    score_ia: null,
    raw: null,
    fallback: true,
    source: 'fallback',
    ...(erreur ? { erreur } : {}),
  };
}

/** Résumé / profil textuel depuis la réponse resume-parsing-api2 (PRD §1). */
function _extractResumeFromParsedJson(json) {
  if (!json || typeof json !== 'object') return '';
  const pi = json.personal_info || json.personalInfo || {};
  const candidates = [
    json.summary,
    json.executive_summary,
    json.objective,
    json.profile,
    json.professional_summary,
    pi.summary,
    pi.profile,
    pi.objective,
  ];
  for (const c of candidates) {
    const s = String(c || '').trim();
    if (s.length > 20) return s;
  }
  const we = Array.isArray(json.work_experience) ? json.work_experience[0] : null;
  const desc = we && String(we.description || '').trim();
  if (desc && desc.length > 15) return desc.slice(0, 800);
  return '';
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

function decryptIfNeeded(input) {
  const value = String(input || '');
  if (!value.includes(':')) return value;
  try {
    const encryptionKey = process.env.ENCRYPTION_KEY || '';
    if (encryptionKey.length < 16) return '';
    const [ivHex, encrypted] = value.split(':');
    const iv = Buffer.from(ivHex, 'hex');
    const key = crypto.scryptSync(encryptionKey, 'salt', 32);
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let dec = decipher.update(encrypted, 'hex', 'utf8');
    dec += decipher.final('utf8');
    return dec;
  } catch (_) {
    return '';
  }
}

function resolveSecret(raw) {
  const s = String(raw || '').trim();
  if (!s) return '';
  if (s.includes(':')) {
    const dec = decryptIfNeeded(s);
    if (!dec) {
      console.warn('[resolveSecret] Valeur chiffrée illisible (ENCRYPTION_KEY absente ou différente).');
    }
    return dec;
  }
  return s;
}

export async function _getClesIA() {
  try {
    const { data: rows, error } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'anthropic_api_key',
        'anthropic_model',
        'openai_api_key',
        'ia_amelioration_provider',
        'ia_matching_provider',
        'ia_matching_actif',
      ]);

    if (error) console.error('[_getClesIA] Supabase:', error.message);

    const c = {};
    (rows || []).forEach((r) => { c[r.cle] = r.valeur; });

    let anthropicKey = resolveSecret(c.anthropic_api_key) || process.env.ANTHROPIC_API_KEY || '';
    if (anthropicKey && !anthropicKey.startsWith('sk-ant-')) {
      console.warn(
        '[_getClesIA] anthropic_api_key : format inattendu (souvent ancienne valeur corrompue / hex) — ignorée, fallback .env',
      );
      anthropicKey = process.env.ANTHROPIC_API_KEY || '';
    }

    let openaiKey = resolveSecret(c.openai_api_key) || process.env.OPENAI_API_KEY || '';
    if (openaiKey && !/^sk-[a-zA-Z0-9_-]+/.test(openaiKey)) {
      console.warn('[_getClesIA] openai_api_key : format inattendu — ignorée, fallback .env');
      openaiKey = process.env.OPENAI_API_KEY || '';
    }

    console.log(
      '[_getClesIA] Clé Anthropic:',
      anthropicKey ? `✅ ${anthropicKey.substring(0, 15)}...` : '❌ VIDE',
    );
    console.log(
      '[_getClesIA] Clé OpenAI:',
      openaiKey ? `✅ ${openaiKey.substring(0, 10)}...` : '❌ VIDE',
    );

    return {
      anthropicKey,
      anthropicModel: String(c.anthropic_model || 'claude-haiku-4-5-20251001').trim(),
      openaiKey,
      providerTexte: String(c.ia_amelioration_provider || 'anthropic').trim().toLowerCase(),
      providerMatching: String(
        c.ia_matching_provider || c.ia_amelioration_provider || 'anthropic',
      ).trim().toLowerCase(),
      matchingActif: String(c.ia_matching_actif ?? 'true').toLowerCase() !== 'false',
    };
  } catch (e) {
    console.error('[getClesIA]', e?.message || e);
    return {
      anthropicKey: process.env.ANTHROPIC_API_KEY || '',
      anthropicModel: 'claude-haiku-4-5-20251001',
      openaiKey: process.env.OPENAI_API_KEY || '',
      providerTexte: 'anthropic',
      providerMatching: 'anthropic',
      matchingActif: true,
    };
  }
}

/** Extrait le premier bloc JSON objet `{ ... }` si le modèle ajoute du texte avant/après. */
function _tryExtractJsonObject(text) {
  const t = String(text || '').trim();
  const start = t.indexOf('{');
  const end = t.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) return null;
  return t.slice(start, end + 1);
}

export async function _appellerIA(prompt, cles, role = 'matching') {
  const provider = role === 'texte' ? cles.providerTexte : cles.providerMatching;
  console.log(`[IA] Provider: ${provider} | Rôle: ${role}`);

  if (provider === 'anthropic' && cles.anthropicKey) {
    try {
      console.log('[appellerIA] Envoi requête à Anthropic...');
      console.log('[appellerIA] Modèle:', cles.anthropicModel || 'claude-haiku-4-5-20251001');
      console.log('[appellerIA] Clé:', `${cles.anthropicKey.substring(0, 15)}...`);

      const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': cles.anthropicKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: cles.anthropicModel || 'claude-haiku-4-5-20251001',
          max_tokens: role === 'texte' ? 300 : 250,
          messages: [{ role: 'user', content: prompt }],
        }),
      });

      console.log('[appellerIA] Status HTTP:', response.status);

      const textRaw = await response.text();
      let data;
      try {
        data = JSON.parse(textRaw);
      } catch (pe) {
        console.error('[appellerIA] ❌ Réponse non-JSON Anthropic:', pe?.message);
        console.error('[appellerIA] Corps (extrait):', textRaw.substring(0, 500));
        return null;
      }

      console.log('[appellerIA] Réponse (extrait):', JSON.stringify(data).substring(0, 500));

      if (data?.error) {
        console.error(
          '[appellerIA] ❌ Erreur Anthropic:',
          data.error?.type || 'error',
          '-',
          data.error?.message || JSON.stringify(data.error),
        );
        return null;
      }

      if (!response.ok) {
        console.error('[appellerIA] ❌ HTTP non OK sans champ error standard, status:', response.status);
        return null;
      }

      const texte = String(data?.content?.[0]?.text || '').trim();
      console.log('[appellerIA] Texte reçu (extrait):', texte.substring(0, 200));
      return texte || null;
    } catch (e) {
      console.error('[appellerIA] ❌ Exception Anthropic:', e?.message || e);
      return null;
    }
  }

  if (provider === 'openai' && cles.openaiKey) {
    try {
      console.log('[appellerIA] Envoi requête à OpenAI...');
      console.log('[appellerIA] Clé:', `${cles.openaiKey.substring(0, 10)}...`);

      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${cles.openaiKey}`,
        },
        body: JSON.stringify({
          model: 'gpt-3.5-turbo',
          max_tokens: role === 'texte' ? 300 : 250,
          messages: [{ role: 'user', content: prompt }],
        }),
      });

      console.log('[appellerIA] Status HTTP (OpenAI):', response.status);

      const textRaw = await response.text();
      let data;
      try {
        data = JSON.parse(textRaw);
      } catch (pe) {
        console.error('[appellerIA] ❌ Réponse non-JSON OpenAI:', pe?.message);
        console.error('[appellerIA] Corps (extrait):', textRaw.substring(0, 500));
        return null;
      }

      console.log('[appellerIA] Réponse OpenAI (extrait):', JSON.stringify(data).substring(0, 500));

      if (data?.error) {
        console.error(
          '[appellerIA] ❌ Erreur OpenAI:',
          data.error?.type || 'error',
          '-',
          data.error?.message || JSON.stringify(data.error),
        );
        return null;
      }

      const texte = String(data?.choices?.[0]?.message?.content || '').trim();
      console.log('[appellerIA] Texte OpenAI (extrait):', texte.substring(0, 200));
      return texte || null;
    } catch (e) {
      console.error('[appellerIA] ❌ Exception OpenAI:', e?.message || e);
      return null;
    }
  }

  console.warn('[IA] Aucun appel API (provider=', provider, ', clés manquantes ou mode local/aucun)');
  return null;
}

function _telechargerHttp(cvUrl) {
  return new Promise((resolve, reject) => {
    const safe = String(cvUrl || '');
    const client = safe.startsWith('https://') ? https : http;
    const requete = client.get(safe, (reponse) => {
      if (reponse.statusCode === 301 || reponse.statusCode === 302) {
        const loc = reponse.headers.location;
        return _telechargerHttp(loc).then(resolve).catch(reject);
      }
      if (reponse.statusCode !== 200) {
        return reject(new Error(`HTTP ${reponse.statusCode}`));
      }
      const morceaux = [];
      reponse.on('data', (c) => morceaux.push(c));
      reponse.on('end', () => {
        const buffer = Buffer.concat(morceaux);
        console.log('[IA] Fichier HTTP:', buffer.length, 'bytes');
        resolve({
          buffer,
          contentType: reponse.headers['content-type'] || 'application/pdf',
        });
      });
      reponse.on('error', reject);
    });
    requete.on('error', reject);
    requete.setTimeout(15000, () => {
      requete.destroy();
      reject(new Error('Timeout téléchargement'));
    });
  });
}

async function _obtenirFichierCV(cvUrl) {
  const u = String(cvUrl || '').trim();
  console.log('[IA] Téléchargement:', u.substring(0, 80));

  if (!u.startsWith('http')) {
    const { data, error } = await supabase.storage.from(BUCKET_CV).download(u);
    if (error) throw new Error(`Storage error: ${error.message}`);
    const arrayBuffer = await data.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    const ext = u.split('.').pop()?.toLowerCase().replace(/[^a-z0-9]/g, '') || 'pdf';
    console.log('[IA] Fichier storage:', buffer.length, 'bytes');
    return {
      buffer,
      contentType: MIME_BY_EXT[ext] || 'application/pdf',
    };
  }

  return _telechargerHttp(u);
}

function _nomFichierDepuisUrlOuChemin(cvUrlOrPath, contentType) {
  const s = String(cvUrlOrPath || '');
  let base = s.split('/').pop()?.split('?')[0] || 'cv.pdf';
  if (!base.includes('.')) {
    if (String(contentType || '').includes('pdf')) base = `${base}.pdf`;
    else if (String(contentType || '').includes('wordprocessingml')) base = `${base}.docx`;
    else if (String(contentType || '').includes('msword')) base = `${base}.doc`;
    else base = `${base}.pdf`;
  }
  return base
    .replace(/\.pdf\.pdf$/i, '.pdf')
    .replace(/\.docx\.docx$/i, '.docx')
    .replace(/[^a-zA-Z0-9._-]/g, '_');
}

function _unwrapPayload(data) {
  if (!data || typeof data !== 'object') return {};
  const nested = data.parsed_resume || data.resume || data.result || data.parsed;
  if (nested && typeof nested === 'object' && nested !== data) {
    return { ...data, ...nested };
  }
  return data;
}

function _extraireDonnees(dataBrut) {
  console.log('[extraire] Traitement réponse API...');
  const data = _unwrapPayload(dataBrut);
  const dd = data?.data;
  const dr = data?.result;
  const dp = data?.parsed;

  const competences = [];
  const experience = [];
  const formation = [];
  let langues = ['Français'];

  const sourcesComps = [
    data.skills,
    data.Skills,
    data.technical_skills,
    data.TechnicalSkills,
    data.soft_skills,
    data.SoftSkills,
    data.extracted_skills,
    data.key_skills,
    dd?.skills,
    dr?.skills,
    dp?.skills,
  ];

  for (const src of sourcesComps) {
    if (!src) continue;
    if (Array.isArray(src)) {
      src.forEach((s) => {
        const v = typeof s === 'string'
          ? s
          : s?.name || s?.skill || s?.value || '';
        if (String(v || '').trim()) competences.push(String(v).trim());
      });
    } else if (typeof src === 'object') {
      Object.keys(src).forEach((k) => {
        if (k?.trim()) competences.push(k.trim());
      });
    } else if (typeof src === 'string') {
      src.split(',').forEach((s) => {
        if (s?.trim()) competences.push(s.trim());
      });
    }
  }

  const sourcesExp = [
    data.experience,
    data.Experience,
    data.work_experience,
    data.WorkExperience,
    data.employment_history,
    dd?.experience,
    dr?.experience,
    dp?.experience,
  ];

  for (const src of sourcesExp) {
    if (!src) continue;
    const liste = Array.isArray(src) ? src : [src];
    liste.forEach((e) => {
      if (e && (e.company || e.title || e.position)) {
        experience.push({
          titre: e.title || e.position || e.job_title || '',
          entreprise: e.company || e.employer || e.organization || '',
          duree: e.duration || e.dates || '',
          description: e.description || e.responsibilities || '',
        });
      } else if (typeof e === 'string' && e.trim()) {
        experience.push(e.trim());
      }
    });
  }

  const sourcesEdu = [
    data.education,
    data.Education,
    data.academic_history,
    dd?.education,
    dr?.education,
    dp?.education,
  ];

  for (const src of sourcesEdu) {
    if (!src) continue;
    const liste = Array.isArray(src) ? src : [src];
    liste.forEach((f) => {
      if (f && (f.school || f.degree || f.institution)) {
        formation.push({
          diplome: f.degree || f.qualification || '',
          ecole: f.school || f.institution || f.university || '',
          annee: f.year || f.graduation_year || '',
        });
      } else if (typeof f === 'string' && f.trim()) {
        formation.push(f.trim());
      }
    });
  }

  [data.languages, data.Languages, dp?.languages].forEach((src) => {
    if (!src) return;
    const liste = Array.isArray(src) ? src : [src];
    liste.forEach((l) => {
      const nom = typeof l === 'string' ? l : l?.language || l?.name || '';
      if (nom && !langues.includes(nom)) langues.push(nom);
    });
  });

  const nomCV = data.name || data.Name || data.full_name || data.candidate_name || '';

  const compsFiltrees = [...new Set(
    competences.filter((c) => c && c.length > 1 && c.length < 60),
  )];

  console.log('[extraire] ✅ Compétences:', compsFiltrees.length,
    '-', compsFiltrees.slice(0, 5).join(', '));
  console.log('[extraire] Expériences:', experience.length);
  console.log('[extraire] Formations:', formation.length);

  langues = [...new Set(langues)];

  const resumeProfil = String(
    data.summary
      || data.profile
      || data.professional_summary
      || data.about
      || data.objective
      || data.personal_info?.summary
      || data.personal_info?.profile
      || '',
  ).trim();

  return {
    competences: compsFiltrees,
    experience,
    formation,
    langues,
    resume_profil: resumeProfil,
    nom: nomCV || null,
    email: data.email || data.Email || null,
    telephone: data.phone || data.Phone || data.telephone || null,
    score_ia: data.score || null,
    raw: dataBrut,
    fallback: false,
    source: 'resume-parser-api',
  };
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

function _envoyerURL(urlCV, apiKey) {
  return axios
    .post(
      'https://cv-resume-parser.p.rapidapi.com/parse/url',
      { url: urlCV },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': 'cv-resume-parser.p.rapidapi.com',
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': 'cv-resume-parser.p.rapidapi.com',
        },
        timeout: 30000,
      },
    )
    .then((res) => {
      console.log('[envoyerURL] Status:', res.status);
      console.log('[envoyerURL] Réponse:', JSON.stringify(res.data).substring(0, 300));
      return res.data;
    })
    .catch((err) => {
      const status = err.response?.status;
      const data = JSON.stringify(err.response?.data || err.message).substring(0, 300);
      console.log('[envoyerURL] Status:', status);
      console.log('[envoyerURL] Réponse:', data);
      return { erreur: `HTTP ${status || ''}: ${data}`.trim() };
    });
}

function _envoyerFichier(buffer, nomFichier, contentType, apiKey) {
  const form = new FormData();
  form.append('file', buffer, {
    filename: nomFichier,
    contentType,
  });

  return axios
    .post(
      'https://cv-resume-parser.p.rapidapi.com/parse',
      form,
      {
        headers: {
          ...form.getHeaders(),
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': 'cv-resume-parser.p.rapidapi.com',
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': 'cv-resume-parser.p.rapidapi.com',
        },
        timeout: 30000,
        maxContentLength: Infinity,
        maxBodyLength: Infinity,
      },
    )
    .then((res) => {
      console.log('[envoyerFichier] Status:', res.status);
      console.log('[envoyerFichier] Réponse:', JSON.stringify(res.data).substring(0, 300));
      return res.data;
    })
    .catch((err) => {
      const status = err.response?.status;
      const data = JSON.stringify(err.response?.data || err.message).substring(0, 300);
      console.log('[envoyerFichier] Status:', status);
      console.log('[envoyerFichier] Réponse:', data);
      return { erreur: `HTTP ${status || ''}: ${data}`.trim() };
    });
}

function _normaliserErreurApi(erreur1, erreur2) {
  const raw = `${String(erreur1 || '')} ${String(erreur2 || '')}`.toLowerCase();
  if (raw.includes('not subscribed') || raw.includes('you are not subscribed')) {
    return 'Clé RapidAPI valide mais abonnement manquant pour cv-resume-parser.';
  }
  if (raw.includes('missing x-rapidapi-key')) {
    return 'Le provider ne reçoit pas la clé RapidAPI (vérifier abonnement/plan et host API).';
  }
  return String(erreur2 || erreur1 || 'API inaccessible');
}

export async function analyserCV(cvUrlOrPath) {
  console.log('\n[analyserCV] ═══ DÉBUT ═══');

  const cvUrl = String(cvUrlOrPath || '');
  const cles = await getRapidApiKeys();
  if (!cles.apiKey) {
    return {
      ..._fallbackParserCV(),
      erreur: 'Clé API manquante',
    };
  }

  console.log('[analyserCV] Clé:', `${cles.apiKey.substring(0, 15)}...`);

  let urlPublique = cvUrl;
  if (!cvUrl.startsWith('http')) {
    const { data } = supabase.storage.from(BUCKET_CV).getPublicUrl(cvUrl);
    urlPublique = data?.publicUrl || cvUrl;
  }

  console.log('[analyserCV] URL publique:', urlPublique.substring(0, 100));

  const corpsJSON = {
    extractionDetails: {
      name: 'Resume Extraction - EmploiConnect',
      language: 'French',
      fields: [
        {
          key: 'personal_info',
          description: 'personal information of the person',
          type: 'object',
          properties: [
            { key: 'name', description: 'full name', type: 'string', example: 'Jean Dupont' },
            { key: 'email', description: 'email', type: 'string', example: 'jean@email.com' },
            { key: 'phone', description: 'phone', type: 'string', example: '+224 620 000 000' },
            { key: 'address', description: 'city', type: 'string', example: 'Conakry, Guinée' },
          ],
        },
        {
          key: 'work_experience',
          description: 'work experience',
          type: 'array',
          items: {
            type: 'object',
            properties: [
              { key: 'title', description: 'job title', type: 'string', example: 'Développeur Flutter' },
              { key: 'company', description: 'company', type: 'string', example: 'Orange Guinée' },
              { key: 'start_date', description: 'start date', type: 'string', example: '2022' },
              { key: 'end_date', description: 'end date', type: 'string', example: '2024' },
              { key: 'description', description: 'description', type: 'string', example: 'Développement mobile' },
            ],
          },
        },
        {
          key: 'education',
          description: 'education',
          type: 'array',
          items: {
            type: 'object',
            properties: [
              { key: 'title', description: 'degree', type: 'string', example: 'Licence Informatique' },
              { key: 'institute', description: 'school', type: 'string', example: 'Université de Conakry' },
              { key: 'start_date', description: 'start year', type: 'string', example: '2020' },
              { key: 'end_date', description: 'end year', type: 'string', example: '2023' },
            ],
          },
        },
        {
          key: 'skills',
          description: 'technical and soft skills',
          type: 'array',
          items: { type: 'string', example: 'Flutter' },
        },
        {
          key: 'languages',
          description: 'languages spoken',
          type: 'array',
          items: { type: 'string', example: 'Français' },
        },
        {
          key: 'certificates',
          description: 'certifications',
          type: 'array',
          items: { type: 'string', example: 'AWS Developer' },
        },
      ],
    },
    file: urlPublique,
  };

  const corps = JSON.stringify(corpsJSON);
  console.log('[analyserCV] Envoi JSON vers resume-parsing-api2...');

  return new Promise((resolve) => {
    const options = {
      method: 'POST',
      hostname: 'resume-parsing-api2.p.rapidapi.com',
      path: '/processDocument',
      headers: {
        'x-rapidapi-key': cles.apiKey,
        'x-rapidapi-host': 'resume-parsing-api2.p.rapidapi.com',
        'content-type': 'application/json',
        'content-length': Buffer.byteLength(corps),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (c) => { data += c; });
      res.on('end', () => {
        console.log('[analyserCV] Status:', res.statusCode);
        console.log('[analyserCV] Réponse:', data.substring(0, 500));

        if (res.statusCode === 200 || res.statusCode === 201) {
          try {
            const json = JSON.parse(data);
            console.log('[analyserCV] ✅ SUCCÈS !');

            const competences = Array.isArray(json.skills) ? json.skills : [];
            const langues = Array.isArray(json.languages) && json.languages.length > 0
              ? json.languages
              : ['Français'];
            const experience = (Array.isArray(json.work_experience) ? json.work_experience : []).map((e) => ({
              titre: e.title || '',
              entreprise: e.company || '',
              duree: `${e.start_date || ''} - ${e.end_date || ''}`,
              description: e.description || '',
            }));
            const formation = (Array.isArray(json.education) ? json.education : []).map((f) => ({
              diplome: f.title || '',
              ecole: f.institute || '',
              annee: f.end_date || '',
            }));

            console.log('[analyserCV] Compétences:', competences.length, '-', competences.slice(0, 5).join(', '));
            console.log('[analyserCV] Expériences:', experience.length);
            console.log('[analyserCV] Formations:', formation.length);

            const resume_profil = _extractResumeFromParsedJson(json);
            resolve({
              competences,
              experience,
              formation,
              langues,
              resume_profil,
              fallback: false,
              source: 'resume-parsing-api2',
            });
          } catch (e) {
            resolve({
              ..._fallbackParserCV(),
              erreur: `Réponse non JSON: ${e.message}`,
            });
          }
        } else {
          console.error('[analyserCV] ❌', res.statusCode, data);
          resolve({
            ..._fallbackParserCV(),
            erreur: `HTTP ${res.statusCode}: ${data.substring(0, 200)}`,
          });
        }
      });
    });

    req.on('error', (e) => resolve({
      ..._fallbackParserCV(),
      erreur: e.message,
    }));
    req.setTimeout(30000, () => {
      req.destroy();
      resolve({
        ..._fallbackParserCV(),
        erreur: 'Timeout 30s',
      });
    });

    req.write(corps);
    req.end();
  });
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

  const fallbackScore = async () => {
    const scoreSimilarite = await calculerSimilarite(profilText, offreText);
    const scoreComp = scoreCompetences(profilCandidat?.competences, offre?.competences_requises);
    const bLoc = bonusLocalisation(profilCandidat?.ville, offre?.localisation);
    const bExp = bonusExperience(
      profilCandidat?.annees_experience,
      offre?.niveau_experience_requis,
    );
    const score = Math.round(
      scoreSimilarite * 0.6
      + scoreComp * 0.25
      + bLoc * 0.1
      + bExp * 0.05,
    );
    return Math.max(0, Math.min(100, score));
  };

  try {
    const cles = await _getClesIA();
    if (!cles.matchingActif) {
      console.log('[matching] IA désactivée depuis l\'admin, fallback local');
      return fallbackScore();
    }

    const prompt = `Tu es un expert en recrutement en Guinée.
Analyse la compatibilité entre ce profil et cette offre.

PROFIL CANDIDAT :
- Titre : ${profilCandidat?.titre_poste || profilCandidat?.titre || 'Non précisé'}
- Compétences : ${asArray(profilCandidat?.competences).slice(0, 15).join(', ') || 'Non précisées'}
- Expériences : ${asArray(profilCandidat?.experience || profilCandidat?.experiences).slice(0, 3).map((e) => {
  if (!e || typeof e !== 'object') return String(e || '');
  return `${e.titre || e.title || 'Poste'} chez ${e.entreprise || e.company || 'Entreprise'}`;
}).join(', ') || 'Non précisées'}
- À propos : ${String(profilCandidat?.about || '').substring(0, 200)}

OFFRE D'EMPLOI :
- Titre : ${offre?.titre || ''}
- Compétences requises : ${asArray(offre?.competences_requises).join(', ') || 'Non précisées'}
- Description : ${String(offre?.description || '').substring(0, 300)}

Réponds UNIQUEMENT avec ce JSON :
{
  "score": <0-100>,
  "domaine_match": <"exact"|"proche"|"partiel"|"different">,
  "competences_communes": [<max 5 compétences>],
  "competences_manquantes": [<max 3 compétences importantes>],
  "raison": "<max 80 caractères en français>"
}`;

    const texteReponse = await _appellerIA(prompt, cles, 'matching');
    console.log('[semantique] Texte brut reçu (extrait):', (texteReponse || '').substring(0, 500));
    if (!texteReponse) {
      console.warn('[matching] Pas de texte IA → fallback score local');
      return fallbackScore();
    }

    const clean = texteReponse.replace(/```json/g, '').replace(/```/g, '').trim();
    console.log('[semantique] Texte nettoyé (extrait):', clean.substring(0, 400));

    let analyseIA;
    try {
      analyseIA = JSON.parse(clean);
    } catch (parseErr) {
      console.warn('[semantique] JSON.parse direct échoué:', parseErr?.message);
      const extracted = _tryExtractJsonObject(clean);
      if (extracted) {
        try {
          analyseIA = JSON.parse(extracted);
          console.log('[semantique] ✅ Parse récupéré via extraction { ... }');
        } catch (e2) {
          console.error('[semantique] ❌ Parse JSON échoué après extraction:', e2?.message);
          console.error('[semantique] Texte qui a échoué:', texteReponse.substring(0, 800));
          return fallbackScore();
        }
      } else {
        console.error('[semantique] ❌ Parse JSON échoué:', parseErr?.message);
        console.error('[semantique] Texte qui a échoué:', texteReponse.substring(0, 800));
        return fallbackScore();
      }
    }

    console.log('[semantique] ✅ Parse OK (extrait):', JSON.stringify(analyseIA).substring(0, 400));

    const score = Number.parseInt(String(analyseIA?.score ?? ''), 10);
    if (Number.isNaN(score)) {
      console.warn('[matching] Champ score absent ou non numérique → fallback. Objet:', JSON.stringify(analyseIA).substring(0, 200));
      return fallbackScore();
    }

    const finalScore = Math.max(0, Math.min(100, score));
    console.log('[matching] ✅ Score IA:', score);
    console.log('[matching] Domaine:', analyseIA?.domaine_match ?? '(n/a)');
    console.log('[matching] Raison:', analyseIA?.raison ?? '(n/a)');
    console.log('[matching] SCORE FINAL:', finalScore, '%');
    return finalScore;
  } catch (e) {
    console.warn('[matching] Erreur IA:', e?.message || e);
    return fallbackScore();
  }
}
