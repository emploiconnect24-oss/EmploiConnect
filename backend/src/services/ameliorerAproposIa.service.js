import crypto from 'crypto';
import { supabase } from '../config/supabase.js';

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
    const d = decryptIfNeeded(s);
    return d || '';
  }
  return s;
}

export async function fetchIaAmeliorationConfig() {
  const { data, error } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .in('cle', [
      'ia_amelioration_provider',
      'anthropic_api_key',
      'anthropic_model',
      'openai_api_key',
    ]);

  if (error) throw error;

  const map = {};
  (data || []).forEach((p) => {
    map[p.cle] = p.valeur;
  });

  return {
    provider: String(map.ia_amelioration_provider || 'anthropic')
      .trim()
      .toLowerCase(),
    anthropicKey: resolveSecret(map.anthropic_api_key),
    anthropicModel: String(
      map.anthropic_model || 'claude-3-5-haiku-latest',
    ).trim(),
    openaiKey: resolveSecret(map.openai_api_key),
  };
}

function buildPrompt(texteOriginal, titrePoste, competences) {
  const raw = String(texteOriginal || '').trim();
  return {
    raw,
    prompt:
      'Tu es un expert en rédaction de profils professionnels.\n'
      + 'Améliore ce texte "À propos" pour un candidat à l\'emploi.\n\n'
      + `Titre du poste : ${String(titrePoste || 'Non précisé')}\n`
      + `Compétences : ${Array.isArray(competences) ? competences.join(', ') : ''}\n\n`
      + `Texte original :\n"${raw}"\n\n`
      + 'Consignes :\n'
      + '- Rendre le texte professionnel et percutant\n'
      + '- Maximum 150 mots\n'
      + '- Mettre en avant les compétences clés\n'
      + '- Ton dynamique et confiant\n'
      + '- Adapté au marché de l\'emploi en Afrique (Guinée)\n'
      + '- Garder la langue française\n\n'
      + 'Retourner UNIQUEMENT le texte amélioré, sans explication.',
  };
}

async function callAnthropic(apiKey, model, prompt) {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: model || 'claude-3-5-haiku-latest',
      max_tokens: 300,
      messages: [{ role: 'user', content: prompt }],
    }),
  });
  const data = await response.json();
  return String(data?.content?.[0]?.text || '').trim();
}

async function callOpenAI(apiKey, prompt) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      max_tokens: 400,
      messages: [{ role: 'user', content: prompt }],
    }),
  });
  const data = await response.json();
  return String(data?.choices?.[0]?.message?.content || '').trim();
}

function fallbackTexte(raw, titrePoste, competences) {
  const base = raw.replace(/\s+/g, ' ').trim();
  let texteAmeliore =
    `Professionnel(le) ${String(titrePoste || '').trim() || 'polyvalent(e)'} avec une forte capacité d'adaptation et un engagement constant pour la qualité. `
    + `Je mets à profit mes compétences (${Array.isArray(competences) ? competences.slice(0, 6).join(', ') : 'travail en équipe, rigueur'}) `
    + `pour contribuer à des projets à impact. ${base}`;
  if (texteAmeliore.length > 900) texteAmeliore = `${texteAmeliore.slice(0, 897)}...`;
  return texteAmeliore;
}

/**
 * Amélioration « À propos » : lit la config dans parametres_plateforme,
 * sinon ANTHROPIC_API_KEY en .env pour Anthropic.
 */
export async function ameliorerAproposAvecConfig(body) {
  const { texte_original: texteOriginal, titre_poste: titrePoste, competences } =
    body || {};
  const { raw, prompt } = buildPrompt(texteOriginal, titrePoste, competences);
  if (!raw) {
    return { error: 'Texte original requis' };
  }

  const cfg = await fetchIaAmeliorationConfig();
  let texteAmeliore = '';

  if (cfg.provider === 'aucun' || cfg.provider === 'local') {
    texteAmeliore = '';
  } else if (cfg.provider === 'openai' && cfg.openaiKey) {
    try {
      texteAmeliore = await callOpenAI(cfg.openaiKey, prompt);
    } catch (e) {
      console.warn('[ameliorerApropos] OpenAI', e?.message || e);
    }
  } else if (cfg.anthropicKey) {
    try {
      texteAmeliore = await callAnthropic(
        cfg.anthropicKey,
        cfg.anthropicModel,
        prompt,
      );
    } catch (e) {
      console.warn('[ameliorerApropos] Anthropic (BDD)', e?.message || e);
    }
  }

  if (!texteAmeliore) {
    const envKey = String(process.env.ANTHROPIC_API_KEY || '').trim();
    if (envKey && cfg.provider !== 'openai' && cfg.provider !== 'aucun' && cfg.provider !== 'local') {
      try {
        texteAmeliore = await callAnthropic(
          envKey,
          process.env.ANTHROPIC_MODEL || 'claude-3-5-haiku-latest',
          prompt,
        );
      } catch (e) {
        console.warn('[ameliorerApropos] Anthropic (.env)', e?.message || e);
      }
    }
  }

  if (!texteAmeliore) {
    texteAmeliore = fallbackTexte(raw, titrePoste, competences);
  }

  return {
    data: {
      texte_original: raw,
      texte_ameliore: texteAmeliore,
    },
  };
}
