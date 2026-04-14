/**
 * Liste abonnés + envoi campagne newsletter (admin).
 */
import { supabase } from '../../config/supabase.js';
import { sendPlatformEmail } from '../../services/mail.service.js';
import { getMailSettings } from '../../config/mailSettings.js';
import { buildWrappedEmailHtml } from '../../services/emailLayout.service.js';
import { genererEtEnvoyerNewsletter } from '../../services/newsletterIa.service.js';

const DECLENCHEURS_AUTORISES = ['hebdomadaire', 'nouvelles_offres', 'admin'];

function htmlEscape(s) {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function apiPublicBaseUrl(req) {
  const fromEnv = String(process.env.PUBLIC_API_URL || '').trim();
  if (fromEnv) return fromEnv.replace(/\/$/, '');
  const host = req.get('host');
  if (host) {
    const proto = req.headers['x-forwarded-proto'] || req.protocol || 'http';
    return `${proto}://${host}`.replace(/\/$/, '');
  }
  return 'http://localhost:3000';
}

export async function getNewsletterAbonnes(req, res) {
  try {
    const actifsOnly = String(req.query.actifs || '1') !== '0';
    let q = supabase
      .from('newsletter_abonnes')
      .select('*', { count: 'exact' })
      .order('date_inscription', { ascending: false });
    if (actifsOnly) q = q.eq('est_actif', true);
    const { data, error, count } = await q;
    if (error) {
      console.error('[GET /admin/newsletter]', error.message);
      return res.status(500).json({ success: false, message: error.message });
    }
    return res.json({
      success: true,
      data: { abonnes: data || [], total: count ?? (data || []).length },
    });
  } catch (err) {
    console.error('[GET /admin/newsletter]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function postNewsletterEnvoyer(req, res) {
  try {
    const sujet = String(req.body?.sujet || '').trim();
    let contenu = String(req.body?.contenu || '').trim();
    if (!sujet || !contenu) {
      return res.status(400).json({
        success: false,
        message: 'Sujet et contenu requis',
      });
    }

    const { data: abonnes, error } = await supabase
      .from('newsletter_abonnes')
      .select('email, nom, token_desabo')
      .eq('est_actif', true);

    if (error) {
      console.error('[POST /admin/newsletter/envoyer]', error.message);
      return res.status(500).json({ success: false, message: error.message });
    }
    if (!abonnes?.length) {
      return res.json({
        success: false,
        message: 'Aucun abonné actif',
      });
    }

    const cfg = await getMailSettings();
    const baseApi = apiPublicBaseUrl(req);
    contenu = contenu.replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, '');
    const innerBody = `<div style="font-size:15px;line-height:1.6;color:#0f172a;">${contenu}</div>`;

    let nbEnvois = 0;
    for (const ab of abonnes) {
      const token = ab.token_desabo;
      const unsub = token
        ? `${baseApi}/api/newsletter/unsubscribe?token=${encodeURIComponent(token)}`
        : `${baseApi}/api/newsletter/unsubscribe`;
      const inner = `${innerBody}<hr style="border:none;border-top:1px solid #e2e8f0;margin:24px 0;" />`
        + `<p style="color:#94a3b8;font-size:12px;">`
        + `<a href="${htmlEscape(unsub)}">Se désabonner</a> · ${htmlEscape(cfg.platformName)}</p>`;
      const html = await buildWrappedEmailHtml(inner);
      const text = `${contenu.replace(/<[^>]+>/g, ' ')}\n\nDésinscription : ${unsub}`;
      // eslint-disable-next-line no-await-in-loop
      const r = await sendPlatformEmail({
        to: ab.email,
        subject: sujet.slice(0, 200),
        text,
        html,
      });
      if (r.ok) nbEnvois += 1;
    }

    return res.json({
      success: true,
      message: `Newsletter envoyée à ${nbEnvois} abonné(s).`,
      nb_envois: nbEnvois,
    });
  } catch (err) {
    console.error('[POST /admin/newsletter/envoyer]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function postNewsletterIaGenerer(req, res) {
  try {
    const declencheur = String(req.body?.declencheur || 'admin').trim() || 'admin';
    if (!DECLENCHEURS_AUTORISES.includes(declencheur)) {
      return res.status(400).json({
        success: false,
        message: `Type de newsletter invalide. Valeurs autorisées : ${DECLENCHEURS_AUTORISES.join(', ')}`,
      });
    }
    const result = await genererEtEnvoyerNewsletter(declencheur, {
      ...(req.body?.contexte || {}),
      contexte_libre: String(req.body?.contexte_libre || '').trim(),
    });
    if (!result.success) {
      return res.status(400).json(result);
    }
    return res.json(result);
  } catch (err) {
    console.error('[POST /admin/newsletter/ia/generer]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}
