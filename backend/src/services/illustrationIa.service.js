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
const GEMINI_MODELES_GENERATE = [
  'gemini-2.5-flash-image',
  'gemini-3.1-flash-image-preview',
  'gemini-3-pro-image-preview',
];

const GEMINI_MODELES_PREDICT = [
  'imagen-4.0-fast-generate-001',
  'imagen-4.0-generate-001',
  'imagen-4.0-ultra-generate-001',
];

const STYLES_AFFICHES = [
  {
    id: 0,
    nom: 'Homme jubilant',
    sujet: 'happy young African man blue shirt fist raised celebrating smartphone',
    ambiance: 'bright blue gradient bokeh office',
    texte_titre: 'EMPLOI INTELLIGENT!',
    texte_cta: 'INSCRIVEZ-VOUS MAINTENANT!',
  },
  {
    id: 1,
    nom: 'Femme confettis',
    sujet: 'joyful African woman yellow top curly hair earbuds fist raised phone confetti falling',
    ambiance: 'dark blue gradient colorful confetti blue yellow white',
    texte_titre: 'TROUVEZ VOTRE EMPLOI!',
    texte_cta: 'Candidats et Entreprises connectes!',
  },
  {
    id: 2,
    nom: 'IA futuriste',
    sujet: 'young African professional surrounded by floating job match UI cards AI scoring badge',
    ambiance: 'deep blue purple gradient neural network glowing tech particles',
    texte_titre: 'MATCHING IA INTELLIGENT',
    texte_cta: 'Votre profil. Les meilleures offres.',
  },
  {
    id: 3,
    nom: 'Succes emploi',
    sujet: 'ecstatic African woman natural hair both hands raised victory phone showing Offre Acceptee notification',
    ambiance: 'confetti explosion blue gold white bright office celebration',
    texte_titre: 'ILS ONT TROUVE LEUR EMPLOI!',
    texte_cta: 'Rejoignez-les maintenant ->',
  },
  {
    id: 4,
    nom: 'Recruteur + Candidat',
    sujet: 'African male recruiter suit tablet left, African female candidate resume right, glowing handshake center',
    ambiance: 'split dark blue left light blue right',
    texte_titre: 'RECRUTEZ LES MEILLEURS TALENTS',
    texte_cta: 'Publier une Offre ->',
  },
  {
    id: 5,
    nom: 'Guinee patriotique',
    sujet: 'group of 3 young Guinean professionals smiling Conakry skyline Guinea map silhouette',
    ambiance: 'dark blue Guinea flag accent colors red yellow green subtle',
    texte_titre: 'L EMPLOI GUINEEN CONNECTE',
    texte_cta: 'La 1ere plateforme intelligente de Guinee',
  },
  {
    id: 6,
    nom: 'Equipe bureau',
    sujet: 'diverse young African professionals tablets laptops collaborative workspace smiling',
    ambiance: 'modern African office warm lighting blue accents',
    texte_titre: 'VOTRE CARRIERE COMMENCE ICI!',
    texte_cta: 'Rejoignez EmploiConnect',
  },
  {
    id: 7,
    nom: 'App mobile',
    sujet: 'large smartphone mockup EmploiConnect app job cards blue UI, African professional behind',
    ambiance: 'clean white light blue gradient floating geometric shapes',
    texte_titre: 'L EMPLOI DANS VOTRE POCHE',
    texte_cta: 'Recherchez, postulez, reussissez.',
  },
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
        'illustration_prompt_base',
        'illustration_mode_affiche',
        'illustration_dernier_style',
        'openai_api_key',
        'openai_model',
        'gemini_api_key',
        'illustration_provider',
        'gemini_modele',
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
      promptBase: String(c.illustration_prompt_base || '').trim(),
      modeAffiche: String(c.illustration_mode_affiche || 'true') !== 'false',
      dernierStyle: parseInt(String(c.illustration_dernier_style || '0'), 10) || 0,
      openaiKey: resolveSecret(c.openai_api_key) || process.env.OPENAI_API_KEY || '',
      openaiModel: String(c.openai_model || 'dall-e-3').trim() || 'dall-e-3',
      geminiKey: resolveSecret(c.gemini_api_key) || process.env.GEMINI_API_KEY || '',
      provider: String(c.illustration_provider || 'dalle').trim().toLowerCase() === 'gemini'
        ? 'gemini'
        : 'dalle',
      geminiModele: String(c.gemini_modele || 'auto').trim() || 'auto',
    };
  } catch (e) {
    console.error('[illustrationIa] Config erreur:', e.message);
    return {
      actif: false,
      nbParJour: 4,
      promptBase: '',
      modeAffiche: true,
      dernierStyle: 0,
      openaiKey: '',
      openaiModel: 'dall-e-3',
      geminiKey: '',
      provider: 'dalle',
      geminiModele: 'auto',
    };
  }
}

async function _construirePrompt(indexStyle, promptAdmin = '') {
  try {
    const style = STYLES_AFFICHES[indexStyle % STYLES_AFFICHES.length];
    if (promptAdmin) {
      return `${promptAdmin}

Style visuel de cette image (variation ${indexStyle + 1}) :
- Sujet principal : ${style.sujet}
- Ambiance/fond : ${style.ambiance}
- Titre a afficher : "${style.texte_titre}"
- Message CTA : "${style.texte_cta}"

Format : vertical portrait 1024x1792, photorealistic, vibrant colors, professional marketing poster quality.`;
    }
    return `Professional advertising visual for EmploiConnect, Guinea job platform.
Vertical portrait format 9:16 (1024x1792px).

Main subject: ${style.sujet}
Background/ambiance: ${style.ambiance}

CRITICAL RULES:
- NO TEXT anywhere on the image
- NO WORDS, NO LETTERS, NO NUMBERS
- NO LOGOS, NO BADGES, NO BANNERS WITH TEXT
- Pure visual scene only

Style requirements:
- Modern African professional marketing visual
- Vibrant blue and white color scheme
- High contrast, clean layout
- Realistic photographic quality
- Suitable for social media (Instagram/TikTok/Facebook)
- Professional and aspirational tone

Quality: HD photorealistic, no text elements whatsoever.`;
  } catch (e) {
    console.error('[illustrationIa] Prompt erreur:', e.message);
    return 'Professional job platform poster Guinea, vibrant blue, African professionals, HD quality.';
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
          size: '1024x1792',
          quality: 'hd',
          style: 'vivid',
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

async function _appellerGeminiGenerateContent(modele, prompt, geminiKey) {
  const endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/'
    + `${modele}:generateContent`
    + `?key=${geminiKey}`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: String(prompt) }] }],
      generationConfig: {
        responseModalities: ['TEXT', 'IMAGE'],
      },
    }),
  });
  const data = await response.json();
  if (!response.ok || data?.error) {
    throw new Error(data?.error?.message || response.statusText || `Gemini error (${modele})`);
  }
  const parts = data?.candidates?.[0]?.content?.parts || [];
  const imagePart = parts.find((p) => p?.inlineData?.mimeType?.startsWith('image/'));
  if (!imagePart?.inlineData?.data) {
    throw new Error(`Modele ${modele} n'a pas retourne d'image`);
  }
  console.log(`[Gemini] Image recue de ${modele}`);
  return {
    base64: imagePart.inlineData.data,
    mimeType: imagePart.inlineData.mimeType || 'image/png',
  };
}

async function _appellerImagen4(modele, prompt, geminiKey) {
  const endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/'
    + `${modele}:predict`
    + `?key=${geminiKey}`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      instances: [{ prompt: String(prompt) }],
      parameters: {
        sampleCount: 1,
        aspectRatio: '9:16',
        safetyFilterLevel: 'block_few',
        personGeneration: 'allow_adult',
      },
    }),
  });
  const data = await response.json();
  if (!response.ok || data?.error) {
    throw new Error(data?.error?.message || response.statusText || `Imagen error (${modele})`);
  }
  const prediction = data?.predictions?.[0];
  if (!prediction?.bytesBase64Encoded) {
    throw new Error(`${modele} : pas d'image retournee`);
  }
  console.log(`[Gemini] Imagen 4 OK: ${modele}`);
  return {
    base64: prediction.bytesBase64Encoded,
    mimeType: prediction.mimeType || 'image/png',
  };
}

async function _genererGeminiFlash(prompt, geminiKey) {
  try {
    console.log('[Gemini] Fallback Flash Image...');
    const image = await _appellerGeminiGenerateContent(
      'gemini-2.0-flash-preview-image-generation',
      prompt,
      geminiKey,
    );
    console.log('[Gemini] Flash Image generee');
    return image;
  } catch (e) {
    console.error('[Gemini] Flash erreur:', e.message);
    throw e;
  }
}

export async function genererImageGemini(prompt, geminiKey, modeleConfig = 'auto') {
  try {
    if (modeleConfig === 'flash-image') {
      return _appellerGeminiGenerateContent('gemini-2.5-flash-image', prompt, geminiKey);
    }
    if (modeleConfig === 'imagen-3') {
      try {
        return await _appellerImagen4('imagen-4.0-generate-001', prompt, geminiKey);
      } catch (e) {
        console.warn('[Gemini] Imagen 4 echec, fallback...');
      }
    }
    for (const modele of GEMINI_MODELES_GENERATE) {
      try {
        console.log(`[Gemini] Essai: ${modele}`);
        const result = await _appellerGeminiGenerateContent(modele, prompt, geminiKey);
        console.log(`[Gemini] ${modele} OK !`);
        return result;
      } catch (subError) {
        console.warn(`[Gemini] ${modele}:`, String(subError.message || '').slice(0, 60));
      }
    }
    for (const modele of GEMINI_MODELES_PREDICT) {
      try {
        console.log(`[Gemini] Fallback Imagen: ${modele}`);
        return await _appellerImagen4(modele, prompt, geminiKey);
      } catch (subError) {
        console.warn(`[Gemini] ${modele}:`, String(subError.message || '').slice(0, 60));
      }
    }
    return _genererGeminiFlash(prompt, geminiKey);
  } catch (e) {
    console.error('[Gemini] Erreur finale:', e.message);
    for (const modele of GEMINI_MODELES_GENERATE) {
      try {
        console.log(`[Gemini] Essai: ${modele}`);
        const result = await _appellerGeminiGenerateContent(modele, prompt, geminiKey);
        console.log(`[Gemini] ${modele} OK !`);
        return result;
      } catch (_) {
        // continue
      }
    }
    for (const modele of GEMINI_MODELES_PREDICT) {
      try {
        return await _appellerImagen4(modele, prompt, geminiKey);
      } catch (_) {
        // continue
      }
    }
    return _genererGeminiFlash(prompt, geminiKey);
  }
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

async function _sauvegarderImageGemini(base64Data, mimeType, nomFichier) {
  try {
    const rawExt = String(mimeType || 'image/jpeg').split('/')[1] || 'jpg';
    const ext = rawExt.replace(/[^a-z0-9]/gi, '').toLowerCase() || 'jpg';
    const buffer = Buffer.from(base64Data, 'base64');
    const cheminSto = `illustrations_ia/${nomFichier}.${ext}`;
    const { error: uploadError } = await supabase.storage.from(BUCKET).upload(cheminSto, buffer, {
      contentType: String(mimeType || 'image/jpeg'),
      upsert: true,
      cacheControl: '86400',
    });
    if (uploadError) throw uploadError;
    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(cheminSto);
    console.log('[Gemini] Image sauvegardee:', cheminSto);
    return pub.publicUrl;
  } catch (e) {
    console.error('[Gemini] Sauvegarde:', e.message);
    throw e;
  }
}

export async function genererIllustrationsJour() {
  try {
    const config = await _getConfig();

    if (!config.actif) {
      console.log('[illustrationIa] IA désactivée dans les paramètres');
      return { success: false, message: 'IA désactivée' };
    }

    if (config.provider === 'gemini' && !config.geminiKey) {
      return {
        success: false,
        message: 'Cle Gemini manquante. Configurez-la dans Admin -> Parametres -> IA',
      };
    }
    if (config.provider === 'dalle' && !config.openaiKey) {
      console.error('[illustrationIa] Cle OpenAI manquante');
      return { success: false, message: 'Cle OpenAI manquante' };
    }

    const nb = Math.max(1, Math.min(config.nbParJour, 8));
    const resultats = [];
    let indexDepart = config.dernierStyle;
    console.log(
      `[illustrationIa] Provider: ${config.provider.toUpperCase()} | `
      + `${nb} affiches depuis style ${indexDepart}...`,
    );

    for (let i = 0; i < nb; i += 1) {
      const indexStyle = (indexDepart + i) % STYLES_AFFICHES.length;
      const style = STYLES_AFFICHES[indexStyle];
      try {
        console.log(`[illustrationIa] Affiche ${i + 1}/${nb} -> Style: "${style.nom}"`);
        const prompt = await _construirePrompt(indexStyle, config.promptBase);
        let urlFinale = '';
        if (config.provider === 'gemini') {
          const { base64, mimeType } = await genererImageGemini(
            prompt,
            config.geminiKey,
            config.geminiModele,
          );
          const nomFichier = `gemini_${style.id}_${Date.now()}_${i}`;
          urlFinale = await _sauvegarderImageGemini(base64, mimeType, nomFichier);
        } else {
          const urlDalle = await genererImageDalle(prompt, config.openaiKey, config.openaiModel);
          const nomFichier = `dalle_${style.id}_${Date.now()}_${i}`;
          urlFinale = await _sauvegarderImage(urlDalle, nomFichier);
        }

        const { data: illus, error: insErr } = await supabase
          .from('illustrations_ia')
          .insert({
            url_image: urlFinale,
            prompt_utilise: prompt,
            source: config.provider,
            est_active: true,
            heure_affichage: Math.floor((24 / nb) * i),
            meta_donnees: {
              style_nom: style.nom,
              style_id: style.id,
              index: indexStyle,
              provider: config.provider,
              heure_fin: Math.floor((24 / nb) * (i + 1)),
            },
          })
          .select()
          .maybeSingle();

        if (insErr) throw insErr;
        if (illus) resultats.push(illus);
        console.log(`[illustrationIa] OK "${style.nom}" (${config.provider})`);

        if (i < nb - 1) {
          await new Promise((r) => {
            setTimeout(r, 3000);
          });
        }
      } catch (e) {
        console.error(`[illustrationIa] Style "${style.nom}" erreur:`, e.message);
      }
    }

    const prochainIndex = (indexDepart + nb) % STYLES_AFFICHES.length;
    await supabase.from('parametres_plateforme').upsert(
      {
        cle: 'illustration_dernier_style',
        valeur: prochainIndex.toString(),
        type_valeur: 'string',
        description: 'Index du dernier style genere (rotation)',
        categorie: 'ia',
      },
      { onConflict: 'cle' },
    );

    const hier = new Date();
    hier.setDate(hier.getDate() - 1);
    await supabase
      .from('illustrations_ia')
      .update({ est_active: false })
      .lt('date_generation', hier.toISOString())
      .eq('est_active', true);

    console.log(`[illustrationIa] ${resultats.length} affiches generees`);
    console.log('[illustrationIa] Styles generes:', resultats.map((r) => r?.meta_donnees?.style_nom).filter(Boolean).join(', '));
    return {
      success: resultats.length > 0,
      nb_generees: resultats.length,
      provider: config.provider,
      illustrations: resultats,
      styles: resultats.map((r) => r?.meta_donnees?.style_nom).filter(Boolean),
      prochain_style: STYLES_AFFICHES[prochainIndex].nom,
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
    const aujourdhui = new Date();
    aujourdhui.setHours(0, 0, 0, 0);
    const { data: illustrations } = await supabase
      .from('illustrations_ia')
      .select('*')
      .gte('date_generation', aujourdhui.toISOString())
      .order('heure_affichage', { ascending: true });

    if (illustrations && illustrations.length > 0) {
      const heureActuelle = new Date().getHours();
      const nb = illustrations.length;
      const heuresParImage = Math.max(1, Math.floor(24 / nb));
      const indexActuel = Math.floor(heureActuelle / heuresParImage);
      const index = Math.min(indexActuel, nb - 1);
      const imageActive = illustrations[index];

      console.log(
        `[illustrationActive] Heure: ${heureActuelle}h -> Image ${index + 1}/${nb}`
        + ` (style: ${imageActive?.meta_donnees?.style_nom || 'N/A'})`,
      );
      return {
        url_image: imageActive.url_image,
        source: imageActive.source,
        style_nom: imageActive?.meta_donnees?.style_nom,
        index_actuel: index + 1,
        total: nb,
        heure_prochain_changement: Math.min(24, (index + 1) * heuresParImage),
      };
    }

    const { data: fallback, error } = await supabase
      .from('illustrations_ia')
      .select('*')
      .eq('est_active', true)
      .order('date_generation', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (!error && fallback?.url_image) {
      return {
        url_image: fallback.url_image,
        source: fallback.source,
      };
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
