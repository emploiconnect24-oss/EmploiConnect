import crypto from 'crypto';
import { supabase } from '../config/supabase.js';
import { getMailSettings } from '../config/mailSettings.js';
import {
  sendAdminEmailChangeCodeEmail,
  sendAdminEmailChangedConfirmationEmails,
} from './mail.service.js';

const TTL_MS = 15 * 60 * 1000;
const MIN_INTERVAL_MS = 60 * 1000;
const MAX_TENTATIVES = 5;

function normalizeEmail(raw) {
  return String(raw || '')
    .trim()
    .toLowerCase();
}

function hashCode(utilisateurId, newEmail, code) {
  const payload = `${utilisateurId}:${newEmail}:${String(code).trim()}`;
  return crypto.createHash('sha256').update(payload, 'utf8').digest('hex');
}

function generateSixDigitCode() {
  const n = crypto.randomInt(0, 1_000_000);
  return String(n).padStart(6, '0');
}

/**
 * Demande un code sur la nouvelle adresse e-mail.
 * @returns {{ ok: true } | { ok: false, status: number, message: string }}
 */
export async function demanderChangementEmailAdmin(utilisateurId, nom, newEmailRaw) {
  const newEmail = normalizeEmail(newEmailRaw);
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!newEmail || !emailRegex.test(newEmail)) {
    return { ok: false, status: 400, message: "Format d'e-mail invalide" };
  }

  const { data: cur, error: curErr } = await supabase
    .from('utilisateurs')
    .select('email')
    .eq('id', utilisateurId)
    .single();
  if (curErr || !cur) {
    return { ok: false, status: 400, message: 'Profil introuvable' };
  }
  if (newEmail === String(cur.email).toLowerCase()) {
    return { ok: false, status: 400, message: 'Cette adresse est déjà celle de votre compte' };
  }

  const { data: taken } = await supabase
    .from('utilisateurs')
    .select('id')
    .eq('email', newEmail)
    .maybeSingle();
  if (taken?.id && taken.id !== utilisateurId) {
    return {
      ok: false,
      status: 409,
      message: 'Cette adresse e-mail est déjà utilisée par un autre compte',
    };
  }

  const cfg = await getMailSettings();
  if (!cfg.enabled) {
    return {
      ok: false,
      status: 503,
      message: 'Envoi d’e-mails désactivé. Activez et configurez le SMTP dans les paramètres plateforme.',
    };
  }

  const { data: existing } = await supabase
    .from('admin_email_change_codes')
    .select('created_at')
    .eq('utilisateur_id', utilisateurId)
    .maybeSingle();

  if (existing?.created_at) {
    const elapsed = Date.now() - new Date(existing.created_at).getTime();
    if (elapsed < MIN_INTERVAL_MS) {
      const sec = Math.ceil((MIN_INTERVAL_MS - elapsed) / 1000);
      return {
        ok: false,
        status: 429,
        message: `Veuillez patienter ${sec} seconde(s) avant de demander un nouveau code.`,
      };
    }
  }

  const code = generateSixDigitCode();
  const codeHash = hashCode(utilisateurId, newEmail, code);
  const expiresAt = new Date(Date.now() + TTL_MS).toISOString();

  const sendResult = await sendAdminEmailChangeCodeEmail({
    to: newEmail,
    nom: nom || '',
    code,
    minutesValid: 15,
  });

  if (!sendResult.ok) {
    return {
      ok: false,
      status: 503,
      message:
        sendResult.error
        || "L'e-mail de vérification n'a pas pu être envoyé. Vérifiez la configuration SMTP.",
    };
  }

  await supabase.from('admin_email_change_codes').delete().eq('utilisateur_id', utilisateurId);

  const { error: insErr } = await supabase.from('admin_email_change_codes').insert({
    utilisateur_id: utilisateurId,
    new_email: newEmail,
    code_hash: codeHash,
    expires_at: expiresAt,
    tentatives_echouees: 0,
  });

  if (insErr) {
    console.error('[adminEmailChange] insert:', insErr);
    return { ok: false, status: 500, message: 'Erreur lors de l’enregistrement du code' };
  }

  return { ok: true };
}

/**
 * @returns {{ ok: true, email: string } | { ok: false, status: number, message: string }}
 */
export async function confirmerChangementEmailAdmin(utilisateurId, newEmailRaw, codeRaw) {
  const newEmail = normalizeEmail(newEmailRaw);
  const code = String(codeRaw ?? '').trim().replace(/\s/g, '');
  if (!/^\d{6}$/.test(code)) {
    return { ok: false, status: 400, message: 'Le code doit contenir 6 chiffres' };
  }

  const { data: row, error } = await supabase
    .from('admin_email_change_codes')
    .select('id, new_email, code_hash, expires_at, tentatives_echouees')
    .eq('utilisateur_id', utilisateurId)
    .maybeSingle();

  if (error || !row) {
    return {
      ok: false,
      status: 400,
      message: 'Aucune demande en cours. Demandez d’abord un code pour la nouvelle adresse.',
    };
  }

  if (row.new_email !== newEmail) {
    return {
      ok: false,
      status: 400,
      message: 'L’adresse e-mail ne correspond pas à celle pour laquelle un code a été envoyé.',
    };
  }

  if (new Date(row.expires_at) < new Date()) {
    await supabase.from('admin_email_change_codes').delete().eq('id', row.id);
    return { ok: false, status: 400, message: 'Ce code a expiré. Demandez un nouveau code.' };
  }

  if (row.tentatives_echouees >= MAX_TENTATIVES) {
    await supabase.from('admin_email_change_codes').delete().eq('id', row.id);
    return {
      ok: false,
      status: 400,
      message: 'Trop de tentatives incorrectes. Demandez un nouveau code.',
    };
  }

  const expectedHash = hashCode(utilisateurId, newEmail, code);
  let match = false;
  try {
    const a = Buffer.from(expectedHash, 'hex');
    const b = Buffer.from(row.code_hash, 'hex');
    match = a.length === b.length && crypto.timingSafeEqual(a, b);
  } catch {
    match = false;
  }

  if (!match) {
    await supabase
      .from('admin_email_change_codes')
      .update({ tentatives_echouees: row.tentatives_echouees + 1 })
      .eq('id', row.id);
    return { ok: false, status: 400, message: 'Code incorrect' };
  }

  const { data: taken } = await supabase
    .from('utilisateurs')
    .select('id')
    .eq('email', newEmail)
    .maybeSingle();
  if (taken?.id && taken.id !== utilisateurId) {
    await supabase.from('admin_email_change_codes').delete().eq('id', row.id);
    return {
      ok: false,
      status: 409,
      message: 'Cette adresse e-mail est déjà utilisée par un autre compte',
    };
  }

  const { data: userBefore, error: bfErr } = await supabase
    .from('utilisateurs')
    .select('email, nom')
    .eq('id', utilisateurId)
    .single();
  if (bfErr || !userBefore?.email) {
    return { ok: false, status: 400, message: 'Profil introuvable' };
  }
  const previousEmail = userBefore.email;
  const nomCompte = userBefore.nom || '';

  const nowIso = new Date().toISOString();
  const { data: updated, error: uErr } = await supabase
    .from('utilisateurs')
    .update({ email: newEmail, date_modification: nowIso })
    .eq('id', utilisateurId)
    .select('id, nom, email, telephone, adresse, photo_url')
    .single();

  if (uErr || !updated) {
    console.error('[adminEmailChange] update utilisateur:', uErr);
    return { ok: false, status: 500, message: 'Impossible de mettre à jour l’adresse e-mail' };
  }

  await supabase.from('admin_email_change_codes').delete().eq('id', row.id);

  const { error: notifErr } = await supabase.from('notifications').insert({
    destinataire_id: utilisateurId,
    type_destinataire: 'individuel',
    titre: 'Adresse e-mail de connexion mise à jour',
    message: `Votre nouvelle adresse de connexion est ${newEmail}. Utilisez-la pour vous connecter ; votre mot de passe reste le même.`,
    type: 'systeme',
    lien: '/admin/profil',
    est_lue: false,
  });
  if (notifErr) {
    console.warn('[adminEmailChange] notification in-app:', notifErr.message);
  }

  void sendAdminEmailChangedConfirmationEmails({
    nom: nomCompte,
    previousEmail,
    newEmail,
  }).then((r) => {
    if (!r?.ok) console.warn('[adminEmailChange] e-mails de confirmation:', r?.error);
  });

  return { ok: true, email: updated.email, data: updated };
}
