/**
 * Sections page « À propos » (public + admin authentifié).
 */
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';
import { sendPlatformEmail } from '../services/mail.service.js';

export async function getApropos(req, res) {
  try {
    const isAdmin = req.user?.role === ROLES.ADMIN;
    let query = supabase
      .from('page_a_propos')
      .select('*')
      .order('ordre', { ascending: true });
    if (!isAdmin) {
      query = query.eq('est_actif', true);
    }
    const { data, error } = await query;
    if (error) {
      console.error('[GET /apropos]', error.message);
      return res.status(500).json({ success: false, message: error.message });
    }
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    console.error('[GET /apropos]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function getAproposEquipe(_req, res) {
  try {
    const { data, error } = await supabase
      .from('equipe_membres')
      .select('*')
      .eq('est_actif', true)
      .order('ordre', { ascending: true });
    if (error) {
      return res.status(500).json({ success: false, message: error.message });
    }
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

function _isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email || '').trim());
}

function _escapeHtml(s) {
  return String(s || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

export async function postAproposContact(req, res) {
  try {
    const {
      nom = '',
      email = '',
      sujet = '',
      message = '',
    } = req.body || {};

    if (!String(nom).trim() || !String(email).trim() || !String(message).trim()) {
      return res.status(400).json({
        success: false,
        message: 'Nom, email et message requis',
      });
    }

    if (!_isValidEmail(email)) {
      return res.status(400).json({
        success: false,
        message: 'Email invalide',
      });
    }

    const { error } = await supabase
      .from('messages_contact')
      .insert({
        nom: String(nom).trim(),
        email: String(email).trim().toLowerCase(),
        sujet: String(sujet).trim(),
        message: String(message).trim(),
      });
    if (error) throw error;

    try {
      const { data: params } = await supabase
        .from('parametres_plateforme')
        .select('valeur')
        .eq('cle', 'email_contact')
        .maybeSingle();
      const emailAdmin = String(params?.valeur || '').trim();
      if (emailAdmin) {
        const safeNom = _escapeHtml(nom);
        const safeEmail = _escapeHtml(email);
        const safeSujet = _escapeHtml(sujet || 'Non précisé');
        const safeMessage = _escapeHtml(message).replace(/\n/g, '<br/>');
        await sendPlatformEmail({
          to: emailAdmin,
          subject: `[Contact EmploiConnect] ${String(sujet || 'Nouveau message').slice(0, 160)}`,
          text: `Nouveau message de contact\n\nDe: ${nom} (${email})\nSujet: ${sujet || 'Non précisé'}\n\n${message}`,
          html: `<h2>Nouveau message de contact</h2>
<p><strong>De :</strong> ${safeNom} (${safeEmail})</p>
<p><strong>Sujet :</strong> ${safeSujet}</p>
<p><strong>Message :</strong></p>
<p>${safeMessage}</p>`,
        });
      }
    } catch (_) {
      // Le contact reste validé même si la notif e-mail échoue.
    }

    try {
      const safeNom = _escapeHtml(nom);
      const safeMessage = _escapeHtml(message).replace(/\n/g, '<br/>');
      const offresUrl = `${String(process.env.PUBLIC_API_URL || 'http://localhost:3001').replace(/\/$/, '')}/offres`;
      await sendPlatformEmail({
        to: String(email).trim().toLowerCase(),
        subject: 'Nous avons bien reçu votre message — EmploiConnect',
        text: `Bonjour ${nom},\n\nNous avons bien reçu votre message et nous reviendrons vers vous rapidement.\n\nVotre message:\n${message}\n\nVoir les offres: ${offresUrl}\n\nL'équipe EmploiConnect`,
        html: `<div style="font-family:Arial,sans-serif;max-width:640px;margin:0 auto;">
<h2 style="margin:0 0 16px;color:#0F172A;">Bonjour ${safeNom} !</h2>
<p>Nous avons bien reçu votre message et nous vous répondrons dans les plus brefs délais.</p>
<div style="background:#F8FAFC;border-radius:8px;padding:12px;border:1px solid #E2E8F0;">
<p style="margin:0 0 8px;"><strong>Votre message :</strong></p>
<p style="margin:0;color:#475569;">${safeMessage}</p>
</div>
<p style="margin-top:16px;"><a href="${offresUrl}">Voir les offres disponibles</a></p>
<p style="margin-top:20px;">L'équipe EmploiConnect</p>
</div>`,
      });
    } catch (_) {
      // Le formulaire reste validé même si l’accusé de réception échoue.
    }

    return res.json({
      success: true,
      message: 'Message envoyé ! Nous vous répondrons bientôt.',
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}
