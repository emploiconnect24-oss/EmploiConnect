/**
 * Inscription / désinscription newsletter (public).
 */
import { supabase } from '../../config/supabase.js';
import { sendPlatformEmail } from '../../services/mail.service.js';
import { getMailSettings } from '../../config/mailSettings.js';
import { buildWrappedEmailHtml } from '../../services/emailLayout.service.js';

function htmlEscape(s) {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

async function newsletterActif() {
  const { data } = await supabase
    .from('parametres_plateforme')
    .select('valeur')
    .eq('cle', 'newsletter_actif')
    .maybeSingle();
  return String(data?.valeur ?? 'true').toLowerCase() !== 'false';
}

async function refreshAbonnesCountCache() {
  const { count, error } = await supabase
    .from('newsletter_abonnes')
    .select('*', { count: 'exact', head: true })
    .eq('est_actif', true);
  if (error) return;
  await supabase
    .from('parametres_plateforme')
    .update({
      valeur: String(count ?? 0),
      date_modification: new Date().toISOString(),
    })
    .eq('cle', 'newsletter_nb_abonnes');
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

async function envoyerConfirmationNewsletter(req, email, nom) {
  const cfg = await getMailSettings();
  const baseApi = apiPublicBaseUrl(req);
  const app = cfg.publicAppUrl.replace(/\/$/, '');
  const tokenRow = await supabase
    .from('newsletter_abonnes')
    .select('token_desabo')
    .eq('email', email.toLowerCase().trim())
    .maybeSingle();
  const token = tokenRow.data?.token_desabo;
  const unsub = token
    ? `${baseApi}/api/newsletter/unsubscribe?token=${encodeURIComponent(token)}`
    : `${baseApi}/api/newsletter/unsubscribe`;

  const inner = `<p style="margin:0 0 16px;">Bonjour ${htmlEscape(nom || '') || 'cher abonné'},</p>`
    + `<p style="margin:0 0 16px;">Vous êtes bien inscrit à la newsletter <strong>${htmlEscape(cfg.platformName)}</strong>.</p>`
    + '<p style="margin:0 0 16px;">Vous recevrez les nouvelles offres et actualités du marché de l’emploi en Guinée.</p>'
    + `<p style="margin:0 0 20px;"><a href="${htmlEscape(`${app}/#/public/offres`)}" `
    + 'style="display:inline-block;padding:12px 24px;background:#1A56DB;color:#fff;'
    + 'text-decoration:none;border-radius:8px;font-weight:600;">Voir les offres</a></p>'
    + `<p style="margin:0;font-size:12px;color:#64748b;">`
    + `<a href="${htmlEscape(unsub)}">Se désabonner</a></p>`;
  const html = await buildWrappedEmailHtml(inner);
  const text = `Bonjour,\n\nVous êtes inscrit à la newsletter ${cfg.platformName}.\n`
    + `Offres : ${app}/#/public/offres\nDésinscription : ${unsub}\n`;

  void sendPlatformEmail({
    to: email,
    subject: `Newsletter — ${cfg.platformName}`,
    text,
    html,
  }).then((r) => {
    if (!r.ok) console.warn('[newsletter] Confirmation non envoyée:', r.error);
  });
}

export async function postNewsletterSubscribe(req, res) {
  try {
    if (!(await newsletterActif())) {
      return res.status(403).json({
        success: false,
        message: 'Newsletter non disponible',
      });
    }

    const emailRaw = String(req.body?.email || '').trim().toLowerCase();
    const nom = String(req.body?.nom || '').trim() || null;
    const source = String(req.body?.source || 'footer').trim().slice(0, 80) || 'footer';

    if (!emailRaw || !emailRaw.includes('@')) {
      return res.status(400).json({ success: false, message: 'Email invalide' });
    }

    const { data: existing, error: selErr } = await supabase
      .from('newsletter_abonnes')
      .select('id, est_actif')
      .eq('email', emailRaw)
      .maybeSingle();

    if (selErr) {
      console.error('[newsletter] select', selErr.message);
      return res.status(500).json({ success: false, message: selErr.message });
    }

    if (existing) {
      if (existing.est_actif) {
        return res.json({
          success: true,
          message: 'Vous êtes déjà abonné à notre newsletter !',
          deja_abonne: true,
        });
      }
      const { error: upErr } = await supabase
        .from('newsletter_abonnes')
        .update({ est_actif: true, nom, source })
        .eq('id', existing.id);
      if (upErr) {
        if (upErr.code === '23505') {
          return res.json({
            success: true,
            message: 'Vous êtes déjà abonné à notre newsletter !',
            deja_abonne: true,
          });
        }
        console.error('[newsletter] update', upErr.message);
        return res.status(500).json({ success: false, message: upErr.message });
      }
    } else {
      const { error: insErr } = await supabase.from('newsletter_abonnes').insert({
        email: emailRaw,
        nom,
        source,
      });
      if (insErr) {
        if (insErr.code === '23505') {
          return res.json({
            success: true,
            message: 'Vous êtes déjà abonné à notre newsletter !',
            deja_abonne: true,
          });
        }
        console.error('[newsletter] insert', insErr.message);
        return res.status(500).json({ success: false, message: insErr.message });
      }
    }

    await refreshAbonnesCountCache();
    void envoyerConfirmationNewsletter(req, emailRaw, nom);

    return res.json({
      success: true,
      message: 'Inscription réussie ! Merci de vous abonner.',
    });
  } catch (err) {
    console.error('[newsletter] subscribe', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function getNewsletterUnsubscribe(req, res) {
  try {
    const token = String(req.query.token || '').trim();
    if (!token) {
      return res.status(400).json({ success: false, message: 'Token manquant' });
    }
    const { error } = await supabase
      .from('newsletter_abonnes')
      .update({ est_actif: false })
      .eq('token_desabo', token);
    if (error) {
      console.error('[newsletter] unsubscribe', error.message);
      return res.status(500).json({ success: false, message: error.message });
    }
    await refreshAbonnesCountCache();
    return res.json({
      success: true,
      message: 'Désinscription effectuée avec succès.',
    });
  } catch (err) {
    console.error('[newsletter] unsubscribe', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}
