import crypto from 'crypto';
import multer from 'multer';
import sharp from 'sharp';
import axios from 'axios';
import { supabase } from '../../config/supabase.js';
import { getRapidApiKeys, invalidateKeysCache } from '../../config/rapidApi.js';
import { invalidateMailSettingsCache } from '../../config/mailSettings.js';
import { verifySmtpConnection, sendPlatformEmail } from '../../services/mail.service.js';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || '';

function encrypt(text) {
  if (!text || String(text).trim() === '') return '';
  if (!ENCRYPTION_KEY || ENCRYPTION_KEY.length < 16) {
    console.warn('[encrypt] ENCRYPTION_KEY absente ou trop courte — stockage en clair (non recommandé)');
    return String(text);
  }
  try {
    const iv = crypto.randomBytes(16);
    const key = crypto.scryptSync(ENCRYPTION_KEY, 'salt', 32);
    const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    let encrypted = cipher.update(String(text), 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return `${iv.toString('hex')}:${encrypted}`;
  } catch (e) {
    console.error('[encrypt]', e.message);
    return String(text);
  }
}

function decrypt(text) {
  if (!text || !String(text).includes(':')) return text;
  if (!ENCRYPTION_KEY || ENCRYPTION_KEY.length < 16) return text;
  try {
    const [ivHex, encrypted] = String(text).split(':');
    const iv = Buffer.from(ivHex, 'hex');
    const key = crypto.scryptSync(ENCRYPTION_KEY, 'salt', 32);
    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (e) {
    return '';
  }
}

const SENSITIVE_KEYS = ['rapidapi_key', 'openai_api_key', 'email_smtp_password'];

/** Invalider le cache RapidAPI dès qu’un paramètre IA est enregistré (sinon jusqu’à 5 min d’ancienneté). */
const RAPIDAPI_CACHE_KEYS = new Set([
  'rapidapi_key',
  'rapidapi_similarity_host',
  'rapidapi_resume_parser_host',
  'rapidapi_topic_tagging_host',
  'seuil_matching_minimum',
]);

const MAIL_SETTINGS_CACHE_KEYS = new Set([
  'email_service_actif',
  'email_smtp_host',
  'email_smtp_port',
  'email_smtp_user',
  'email_smtp_password',
  'email_nom_expediteur',
  'template_bienvenue_sujet',
  'template_bienvenue_corps',
  'template_candidature_sujet',
  'template_validation_sujet',
  'notif_email_candidature',
  'notif_email_validation',
  'notif_email_messages',
  'notif_email_offre_moderation',
  'notif_email_alertes_admin',
  'notif_email_confirmation_candidature',
  'notif_email_compte_rejete',
  'notif_email_statut_candidature',
  'notif_email_signalement_resolution',
  'notif_email_annulation_candidature_recruteur',
  'notif_email_signalement_concerne',
  'notif_email_reset_mdp',
  'notif_email_alerte_emploi',
  'notif_email_resume_hebdo',
  'notif_email_analyse_cv',
  'url_application_publique',
  'email_template_wrapper_html',
  'email_couleur_primaire',
  'template_reset_mdp_sujet',
  'template_alerte_offre_sujet',
  'template_resume_hebdo_sujet',
  'template_analyse_cv_sujet',
]);

function maskSensitiveValue(cle, valeur) {
  if (typeof valeur !== 'string') return valeur;
  if (SENSITIVE_KEYS.includes(cle) && valeur.length > 4) {
    return `••••••••••••${valeur.slice(-4)}`;
  }
  return valeur;
}

function isMaskedPlaceholder(v) {
  if (typeof v !== 'string') return false;
  return v.startsWith('•') || v.startsWith('\u2022');
}

function rowToValeur(p) {
  let valeur = p.valeur;
  if (p.type_valeur === 'boolean') valeur = p.valeur === 'true';
  else if (p.type_valeur === 'integer') valeur = parseInt(p.valeur, 10);
  else if (p.type_valeur === 'json') {
    try {
      valeur = JSON.parse(p.valeur);
    } catch {
      valeur = [];
    }
  }
  if (typeof valeur === 'string') valeur = maskSensitiveValue(p.cle, valeur);
  return valeur;
}

export async function getParametres(req, res) {
  try {
    const { categorie } = req.query;
    let query = supabase
      .from('parametres_plateforme')
      .select('*')
      .order('categorie', { ascending: true })
      .order('cle', { ascending: true });

    if (categorie) query = query.eq('categorie', categorie);

    const { data, error } = await query;
    if (error) throw error;

    const grouped = {};
    (data || []).forEach((p) => {
      if (!grouped[p.categorie]) grouped[p.categorie] = {};
      grouped[p.categorie][p.cle] = {
        valeur: rowToValeur(p),
        type_valeur: p.type_valeur,
        description: p.description,
        modifiable_admin: p.modifiable_admin,
        date_modification: p.date_modification,
      };
    });

    return res.json({ success: true, data: grouped });
  } catch (err) {
    console.error('[getParametres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function updateParametres(req, res) {
  try {
    const { parametres } = req.body;

    if (!Array.isArray(parametres) || parametres.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Tableau de paramètres requis',
      });
    }

    const resultats = [];
    const erreurs = [];
    let rapidApiCacheShouldInvalidate = false;
    let mailCacheShouldInvalidate = false;

    for (const param of parametres) {
      if (!param.cle || param.valeur === undefined) {
        erreurs.push(`Paramètre invalide: ${JSON.stringify(param)}`);
        continue;
      }

      if (typeof param.valeur === 'string' && isMaskedPlaceholder(param.valeur)) {
        continue;
      }

      let valeurString =
        typeof param.valeur === 'object' && param.valeur !== null
          ? JSON.stringify(param.valeur)
          : String(param.valeur);

      if (SENSITIVE_KEYS.includes(param.cle) && valeurString.trim() !== '') {
        valeurString = encrypt(valeurString);
      }

      const { data, error } = await supabase
        .from('parametres_plateforme')
        .update({
          valeur: valeurString,
          date_modification: new Date().toISOString(),
          modifie_par: req.user.id,
        })
        .eq('cle', param.cle)
        .eq('modifiable_admin', true)
        .select('cle, type_valeur, date_modification')
        .single();

      if (error) {
        erreurs.push(`Erreur pour '${param.cle}': ${error.message}`);
      } else {
        resultats.push(data);
        if (RAPIDAPI_CACHE_KEYS.has(param.cle)) rapidApiCacheShouldInvalidate = true;
        if (MAIL_SETTINGS_CACHE_KEYS.has(param.cle)) mailCacheShouldInvalidate = true;
      }
    }

    if (rapidApiCacheShouldInvalidate) {
      invalidateKeysCache();
    }
    if (mailCacheShouldInvalidate) {
      invalidateMailSettingsCache();
    }

    return res.json({
      success: erreurs.length === 0,
      message:
        erreurs.length === 0
          ? `${resultats.length} paramètre(s) mis à jour avec succès`
          : `${resultats.length} succès, ${erreurs.length} erreur(s)`,
      data: { mis_a_jour: resultats, erreurs },
    });
  } catch (err) {
    console.error('[updateParametres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function testerConnexionIA(req, res) {
  const keys = await getRapidApiKeys();

  if (!keys.apiKey) {
    return res.status(400).json({
      success: false,
      message:
        'Clé RapidAPI absente ou illisible. Renseignez-la dans l’admin (IA) et/ou '
        + 'RAPIDAPI_KEY dans le .env du backend. Si la clé est en base chiffrée, '
        + 'vérifiez ENCRYPTION_KEY (≥16 car.) identique au serveur.',
    });
  }

  const resultats = { apiKey: '✅ Configurée', tests: {} };

  try {
    const r = await axios.get(`https://${keys.similarityHost}/similarity/`, {
      params: { text1: 'developer', text2: 'programmer' },
      headers: {
        'X-RapidAPI-Key': keys.apiKey,
        'X-RapidAPI-Host': keys.similarityHost,
      },
      timeout: 8000,
    });
    resultats.tests.similarity = {
      status: '✅ OK',
      score_test: r.data?.similarity,
      host: keys.similarityHost,
    };
  } catch (e) {
    resultats.tests.similarity = {
      status: `❌ Erreur: ${e.response?.status || e.message}`,
      host: keys.similarityHost,
    };
  }

  if (keys.parserHost) {
    try {
      await axios.post(
        `https://${keys.parserHost}/resume/parse`,
        { url: 'https://jsonresume.org/schema/' },
        {
          headers: {
            'Content-Type': 'application/json',
            'X-RapidAPI-Key': keys.apiKey,
            'X-RapidAPI-Host': keys.parserHost,
          },
          timeout: 15000,
        },
      );
      resultats.tests.parser = {
        status: '✅ OK',
        host: keys.parserHost,
      };
    } catch (e) {
      resultats.tests.parser = {
        status: e.response?.status === 404
          ? '✅ OK (API répond, URL test invalide — normal)'
          : `❌ Erreur: ${e.response?.status || e.message}`,
        host: keys.parserHost,
      };
    }
  } else {
    resultats.tests.parser = {
      status: '⚠️ Host non configuré',
      host: 'Non configuré',
    };
  }

  if (keys.taggingHost) {
    const taggingHost = String(keys.taggingHost || '').replace(/^https?:\/\//, '');
    try {
      const r = await axios.get(`https://${taggingHost}/classify/`, {
        params: {
          text: 'software developer flutter mobile application javascript python',
        },
        headers: {
          'X-RapidAPI-Key': keys.apiKey,
          'X-RapidAPI-Host': taggingHost,
        },
        timeout: 8000,
      });
      resultats.tests.tagging = {
        status: '✅ OK',
        topics_test: Object.keys(r.data?.topic || {}).slice(0, 3),
        host: taggingHost,
      };
    } catch (e) {
      const status = e.response?.status;
      resultats.tests.tagging = {
        status: (status === 404 || status === 422)
          ? '✅ OK (API répond)'
          : `❌ Erreur: ${status || e.message}`,
        host: taggingHost,
      };
    }
  } else {
    resultats.tests.tagging = {
      status: '⚠️ Host non configuré',
      host: 'Non configuré',
    };
  }

  const tousOK = Object.values(resultats.tests).every((t) => String(t.status || '').startsWith('✅'));

  return res.json({
    success: tousOK,
    message: tousOK
      ? 'Toutes les APIs IA sont opérationnelles ✅'
      : 'Certaines APIs nécessitent une configuration',
    data: resultats,
  });
}

/** Usage interne backend uniquement (ne pas exposer au navigateur). */
export async function getIAKeysDecrypted(req, res) {
  try {
    const { data } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .eq('categorie', 'ia_matching');

    const keys = {};
    (data || []).forEach((p) => {
      keys[p.cle] = SENSITIVE_KEYS.includes(p.cle) ? decrypt(p.valeur) : p.valeur;
    });

    return res.json({ success: true, data: keys });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function viderCache(req, res) {
  invalidateKeysCache();
  invalidateMailSettingsCache();
  return res.json({
    success: true,
    message: 'Cache vidé avec succès',
    data: { timestamp: new Date().toISOString() },
  });
}

/**
 * POST /api/admin/parametres/tester-smtp
 * Body optionnel : { "destinataire": "email@..." } (sinon email du compte admin connecté).
 */
export async function testerSMTP(req, res) {
  try {
    invalidateMailSettingsCache();
    const verify = await verifySmtpConnection();
    if (!verify.ok) {
      return res.status(400).json({
        success: false,
        message: verify.message,
        data: { verify: false },
      });
    }

    const to = String(req.body?.destinataire || req.user?.email || '').trim();
    if (!to) {
      return res.status(400).json({
        success: false,
        message: 'Indiquez un destinataire (body.destinataire) ou renseignez l’email de votre compte admin.',
        data: { verify: true },
      });
    }

    const subject = 'EmploiConnect — test SMTP';
    const text = 'Si vous recevez ce message, la configuration SMTP de la plateforme est opérationnelle.';
    const html = `<p>${text}</p>`;
    const sent = await sendPlatformEmail({ to, subject, text, html });

    return res.json({
      success: sent.ok,
      message: sent.ok
        ? `Connexion OK et message envoyé à ${to}`
        : (sent.error || 'Échec envoi'),
      data: { verify: true, envoye: sent.ok },
    });
  } catch (err) {
    console.error('[testerSMTP]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getParametreByCle(req, res) {
  try {
    const { cle } = req.params;
    const { data, error } = await supabase
      .from('parametres_plateforme')
      .select('*')
      .eq('cle', cle)
      .maybeSingle();

    if (error) throw error;
    if (!data) {
      return res.status(404).json({ success: false, message: 'Paramètre non trouvé' });
    }

    let valeur = data.valeur;
    if (data.type_valeur === 'boolean') valeur = data.valeur === 'true';
    if (data.type_valeur === 'integer') valeur = parseInt(data.valeur, 10);
    if (typeof valeur === 'string') valeur = maskSensitiveValue(data.cle, valeur);

    return res.json({ success: true, data: { ...data, valeur } });
  } catch (err) {
    console.error('[getParametreByCle]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export const uploadLogoMulter = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    console.log('[Upload] Fichier reçu:', file.originalname, file.mimetype, file.size);
    cb(null, true);
  },
});

export async function uploadLogo(req, res) {
  try {
    console.log('[uploadLogo] Fichier reçu:', req.file?.originalname, req.file?.size, req.file?.mimetype);
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier reçu par le serveur',
      });
    }

    const bucket = process.env.SUPABASE_LOGOS_BUCKET || 'logos';
    console.log('[uploadLogo] Tentative upload dans bucket:', bucket);
    const isSvg = req.file.mimetype.toLowerCase() === 'image/svg+xml';
    let buffer = req.file.buffer;
    let mimeType = req.file.mimetype;

    if (!isSvg) {
      buffer = await sharp(req.file.buffer)
        .resize(400, 200, { fit: 'inside', withoutEnlargement: true })
        .png({ quality: 90 })
        .toBuffer();
      mimeType = 'image/png';
    }

    const ext = isSvg ? '.svg' : '.png';
    const fileName = `logo-emploiconnect-${Date.now()}${ext}`;

    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(fileName, buffer, {
        contentType: mimeType,
        upsert: true,
      });

    if (uploadErr) {
      console.error('[uploadLogo] ERREUR Supabase:', uploadErr);
      return res.status(500).json({
        success: false,
        message: `Erreur Supabase Storage: ${uploadErr.message}. Vérifiez que le bucket "logos" existe et est public.`,
      });
    }
    console.log('[uploadLogo] Upload OK');

    const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(fileName);
    const logoUrl = `${urlData.publicUrl}?t=${Date.now()}`;
    console.log('[uploadLogo] URL publique:', logoUrl);

    const { error: updateErr } = await supabase
      .from('parametres_plateforme')
      .update({
        valeur: logoUrl,
        date_modification: new Date().toISOString(),
        modifie_par: req.user.id,
      })
      .eq('cle', 'logo_url');
    if (updateErr) {
      console.error('[uploadLogo] Erreur update paramètre:', updateErr);
    }

    return res.json({
      success: true,
      message: 'Logo mis à jour avec succès',
      data: { logo_url: logoUrl },
    });
  } catch (err) {
    console.error('[uploadLogo]', err);
    res.status(500).json({
      success: false,
      message: err.message || 'Erreur upload logo',
    });
  }
}
