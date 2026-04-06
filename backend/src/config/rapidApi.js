import crypto from 'crypto';
import { supabase } from './supabase.js';

let keysCache = null;
let keysCacheTime = 0;

const DEFAULTS = {
  apiKey: process.env.RAPIDAPI_KEY || '',
  similarityHost: process.env.RAPIDAPI_SIMILARITY_HOST
    || 'twinword-text-similarity-v1.p.rapidapi.com',
  parserHost: process.env.RAPIDAPI_RESUME_PARSER_HOST
    || 'resume-parser3.p.rapidapi.com',
  taggingHost: process.env.RAPIDAPI_TOPIC_TAGGING_HOST
    || 'twinword-topic-tagging1.p.rapidapi.com',
  seuilMatching: Number.parseInt(process.env.IA_SEUIL_MATCHING || '40', 10) || 40,
};

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

export async function getRapidApiKeys() {
  const now = Date.now();
  if (keysCache && (now - keysCacheTime) < 5 * 60 * 1000) {
    return keysCache;
  }

  try {
    const { data, error } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'rapidapi_key',
        'rapidapi_similarity_host',
        'rapidapi_resume_parser_host',
        'rapidapi_topic_tagging_host',
        'seuil_matching_minimum',
      ]);

    if (error) throw error;

    const map = {};
    (data || []).forEach((p) => {
      map[p.cle] = p.valeur;
    });

    // Clé en base : si chiffrée (forme iv:hex), on n'utilise JAMAIS le texte brut comme clé API.
    const rawKey = String(map.rapidapi_key || '').trim();
    let dbKey = '';
    if (rawKey) {
      if (rawKey.includes(':')) {
        dbKey = decryptIfNeeded(rawKey);
        if (!dbKey) {
          console.warn(
            '[getRapidApiKeys] rapidapi_key en base est chiffrée mais le déchiffrement a échoué '
            + '(ENCRYPTION_KEY absente, < 16 car., ou clé différente de celle utilisée à l’enregistrement). '
            + 'Utilisation de RAPIDAPI_KEY dans .env si présente.',
          );
        }
      } else {
        dbKey = rawKey;
      }
    }

    keysCache = {
      apiKey: dbKey || DEFAULTS.apiKey,
      similarityHost: map.rapidapi_similarity_host || DEFAULTS.similarityHost,
      parserHost: map.rapidapi_resume_parser_host || DEFAULTS.parserHost,
      taggingHost: map.rapidapi_topic_tagging_host || DEFAULTS.taggingHost,
      seuilMatching: Number.parseInt(map.seuil_matching_minimum || '', 10)
        || DEFAULTS.seuilMatching,
    };
    keysCacheTime = now;
    return keysCache;
  } catch (err) {
    console.error('[getRapidApiKeys]', err?.message || err);
    keysCache = { ...DEFAULTS };
    keysCacheTime = now;
    return keysCache;
  }
}

export function invalidateKeysCache() {
  keysCache = null;
  keysCacheTime = 0;
}

export async function isNlpApiEnabled() {
  const keys = await getRapidApiKeys();
  return Boolean(keys.apiKey && keys.apiKey.length > 0);
}
