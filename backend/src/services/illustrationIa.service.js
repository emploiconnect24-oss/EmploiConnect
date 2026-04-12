/**
 * Illustrations homepage — DALL-E + stockage Supabase + paramètres plateforme.
 */
import crypto from 'crypto';
import { supabase } from '../config/supabase.js';

export const ILLUSTRATIONS_STORAGE_BUCKET =
  process.env.SUPABASE_ILLUSTRATIONS_BUCKET?.trim()
  || process.env.SUPABASE_BANNIERES_BUCKET?.trim()
  || 'bannieres';

const BUCKET = ILLUSTRATIONS_STORAGE_BUCKET;

const PROMPTS_EMPLOI = [
  'Professional African woman smiling confidently at work desk '
    + 'in modern office, business attire, clean white background, '
    + 'photorealistic, no background artifacts',
  'Young African professional man in suit celebrating job offer '
    + 'with laptop, diverse workplace Guinea West Africa, '
    + 'white background, high quality illustration',
  'African business team meeting collaboration smiling, '
    + 'modern office Guinea, diverse professionals, '
    + 'transparent/white background, professional photography',
  'Confident African woman holding resume document smiling, '
    + 'professional business outfit, clean background, '
    + 'Guinea West Africa employment theme',
  'African man working on laptop modern office setup, '
    + 'professional technology worker, clean white background, '
    + 'high resolution illustration',
  'Happy African professionals shaking hands job interview, '
    + 'modern Guinea office, business suits, white background',
  'African woman graduate celebrating success career milestone, '
    + 'joyful expression, professional setting white background',
  'Diverse African business team standing together smiling, '
    + 'modern office Guinea, professional attire, clean background',
];

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

async function _getConfig() {
  try {
    const { data: rows, error } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'illustration_ia_actif',
        'illustration_nb_par_jour',
        'openai_api_key',
        'openai_model',
      ]);

    if (error) throw error;

    const c = {};
    (rows || []).forEach((r) => {
      c[r.cle] = r.valeur;
    });

    const parsedNb = parseInt(c.illustration_nb_par_jour || '4', 10);
    const nbSafe = Number.isFinite(parsedNb) ? parsedNb : 4;

    return {
      actif: c.illustration_ia_actif === 'true',
      nbParJour: Math.min(Math.max(1, nbSafe), 10),
      openaiKey: resolveSecret(c.openai_api_key) || process.env.OPENAI_API_KEY || '',
      openaiModel: String(c.openai_model || 'dall-e-3').trim() || 'dall-e-3',
    };
  } catch (e) {
    console.error('[illustrationIa] Config erreur:', e.message);
    return { actif: false, nbParJour: 4, openaiKey: '', openaiModel: 'dall-e-3' };
  }
}

export async function getIllustrationCronHour() {
  try {
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'illustration_heure_generation')
      .maybeSingle();
    const h = parseInt(String(data?.valeur ?? '6'), 10);
    if (Number.isFinite(h) && h >= 0 && h <= 23) return h;
  } catch (_) {
    /* ignore */
  }
  return 6;
}

export async function genererImageDalle(prompt, openaiKey, model = 'dall-e-3') {
  const m = model === 'dall-e-2' ? 'dall-e-2' : 'dall-e-3';
  console.log('[DALL-E] Génération image…', m);
  console.log('[DALL-E] Prompt:', `${String(prompt).slice(0, 60)}…`);

  const body =
    m === 'dall-e-2'
      ? {
          model: 'dall-e-2',
          prompt: String(prompt),
          n: 1,
          size: '1024x1024',
        }
      : {
          model: 'dall-e-3',
          prompt: String(prompt),
          n: 1,
          size: '1024x1024',
          quality: 'standard',
          style: 'natural',
        };

  const response = await fetch('https://api.openai.com/v1/images/generations', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${openaiKey}`,
    },
    body: JSON.stringify(body),
  });

  const data = await response.json();

  if (!response.ok || data.error) {
    const msg = data.error?.message || response.statusText || 'OpenAI error';
    throw new Error(msg);
  }

  const urlImage = data.data?.[0]?.url;
  if (!urlImage) throw new Error('Pas d\'URL retournée par OpenAI');

  console.log('[DALL-E] OK image:', `${String(urlImage).slice(0, 50)}…`);
  return urlImage;
}

async function _sauvegarderImage(urlExterne, nomFichier) {
  try {
    const response = await fetch(urlExterne);
    if (!response.ok) throw new Error('Download failed');

    const ab = await response.arrayBuffer();
    const buffer = Buffer.from(ab);
    const cheminSto = `illustrations_ia/${nomFichier}.png`;

    const { error: uploadError } = await supabase.storage.from(BUCKET).upload(cheminSto, buffer, {
      contentType: 'image/png',
      upsert: true,
      cacheControl: '86400',
    });

    if (uploadError) {
      console.warn('[illustrationIa] Upload Supabase:', uploadError.message);
      return urlExterne;
    }

    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(cheminSto);
    console.log('[illustrationIa] Image sauvegardée sur', BUCKET);
    return pub.publicUrl;
  } catch (e) {
    console.warn('[illustrationIa] Sauvegarde erreur:', e.message);
    return urlExterne;
  }
}

export async function genererIllustrationsJour() {
  try {
    const config = await _getConfig();

    if (!config.actif) {
      console.log('[illustrationIa] IA désactivée dans les paramètres');
      return { success: false, message: 'IA désactivée' };
    }

    if (!config.openaiKey) {
      console.error('[illustrationIa] Clé OpenAI manquante');
      return { success: false, message: 'Clé OpenAI manquante' };
    }

    const nb = Math.max(1, Math.min(config.nbParJour, 10));
    const resultats = [];

    await supabase.from('illustrations_ia').update({ est_active: false }).eq('est_active', true);

    console.log(`[illustrationIa] Génération de ${nb} image(s)…`);

    for (let i = 0; i < nb; i += 1) {
      try {
        const prompt = PROMPTS_EMPLOI[Math.floor(Math.random() * PROMPTS_EMPLOI.length)];
        const urlDalle = await genererImageDalle(prompt, config.openaiKey, config.openaiModel);
        const nomFichier = `day_${Date.now()}_${i}`;
        const urlFinale = await _sauvegarderImage(urlDalle, nomFichier);

        const { data: illus, error: insErr } = await supabase
          .from('illustrations_ia')
          .insert({
            url_image: urlFinale,
            prompt_utilise: prompt,
            source: 'dalle',
            est_active: i === 0,
            heure_affichage: Math.floor((24 / nb) * i),
          })
          .select()
          .maybeSingle();

        if (insErr) throw insErr;
        if (illus) resultats.push(illus);
        console.log(`[illustrationIa] Image ${i + 1}/${nb} OK`);

        if (i < nb - 1) {
          await new Promise((r) => {
            setTimeout(r, 2000);
          });
        }
      } catch (e) {
        console.error(`[illustrationIa] Image ${i + 1} erreur:`, e.message);
      }
    }

    console.log(`[illustrationIa] ${resultats.length} image(s) générée(s)`);
    return {
      success: resultats.length > 0,
      nb_generees: resultats.length,
      illustrations: resultats,
      message: resultats.length === 0 ? 'Aucune image générée' : undefined,
    };
  } catch (e) {
    console.error('[illustrationIa] Erreur globale:', e.message);
    return { success: false, message: e.message };
  }
}

const FALLBACK_UNSPLASH =
  'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800&q=80';

export async function getIllustrationActive() {
  try {
    const { data: illus, error } = await supabase
      .from('illustrations_ia')
      .select('url_image, prompt_utilise, source')
      .eq('est_active', true)
      .order('date_generation', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!error && illus?.url_image) {
      return illus;
    }

    const { data: param } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'illustration_url_manuelle')
      .maybeSingle();

    const manual = String(param?.valeur || '').trim();
    if (manual) {
      return { url_image: manual, source: 'upload', prompt_utilise: null };
    }

    return {
      url_image: FALLBACK_UNSPLASH,
      source: 'unsplash',
      prompt_utilise: null,
    };
  } catch (e) {
    console.warn('[illustrationIa] getActive:', e.message);
    return {
      url_image: FALLBACK_UNSPLASH,
      source: 'unsplash',
      prompt_utilise: null,
    };
  }
}
