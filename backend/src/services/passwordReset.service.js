import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';
import { getMailSettings } from '../config/mailSettings.js';
import { sendPasswordResetEmail } from './mail.service.js';

const SALT = 10;
const TTL_MS = 60 * 60 * 1000;

function hashToken(raw) {
  return crypto.createHash('sha256').update(String(raw || ''), 'utf8').digest('hex');
}

/**
 * Toujours succès générique (pas d’énumération d’emails).
 */
export async function requestPasswordReset(emailRaw) {
  const email = String(emailRaw || '').trim().toLowerCase();
  if (!email) return;

  const { data: user } = await supabase
    .from('utilisateurs')
    .select('id, email, nom, est_actif, est_valide, role')
    .eq('email', email)
    .maybeSingle();

  if (!user?.id || !user.est_actif) return;
  if (user.role !== ROLES.ADMIN && !user.est_valide) return;

  const cfg = await getMailSettings();
  if (!cfg.enabled || !cfg.notifEmailResetMdp) return;

  await supabase
    .from('password_reset_tokens')
    .update({ used_at: new Date().toISOString() })
    .eq('utilisateur_id', user.id)
    .is('used_at', null);

  const raw = crypto.randomBytes(32).toString('hex');
  const tokenHash = hashToken(raw);
  const expiresAt = new Date(Date.now() + TTL_MS).toISOString();

  const { error } = await supabase.from('password_reset_tokens').insert({
    utilisateur_id: user.id,
    token_hash: tokenHash,
    expires_at: expiresAt,
  });
  if (error) {
    console.warn('[requestPasswordReset] insert:', error.message);
    return;
  }

  const base = (
    process.env.PUBLIC_APP_URL
    || cfg.publicAppUrl
    || 'http://localhost:8080'
  ).replace(/\/$/, '');
  const resetLink = `${base}/#/reset-password?token=${raw}`;

  void sendPasswordResetEmail({
    to: user.email,
    nom: user.nom,
    resetLink,
  });
}

export async function completePasswordReset(rawToken, newPassword) {
  const pwd = String(newPassword || '');
  if (pwd.length < 8) {
    return { ok: false, message: 'Le mot de passe doit contenir au moins 8 caractères' };
  }

  const tokenHash = hashToken(rawToken);
  const { data: row, error } = await supabase
    .from('password_reset_tokens')
    .select('id, utilisateur_id, expires_at, used_at')
    .eq('token_hash', tokenHash)
    .maybeSingle();

  if (error || !row || row.used_at) {
    return { ok: false, message: 'Lien invalide ou déjà utilisé' };
  }
  if (new Date(row.expires_at) < new Date()) {
    return { ok: false, message: 'Ce lien a expiré. Demandez un nouvel email.' };
  }

  const hashed = await bcrypt.hash(pwd, SALT);
  const { error: uErr } = await supabase
    .from('utilisateurs')
    .update({ mot_de_passe: hashed })
    .eq('id', row.utilisateur_id);
  if (uErr) {
    return { ok: false, message: 'Impossible de mettre à jour le mot de passe' };
  }

  await supabase
    .from('password_reset_tokens')
    .update({ used_at: new Date().toISOString() })
    .eq('id', row.id);

  await supabase
    .from('password_reset_tokens')
    .update({ used_at: new Date().toISOString() })
    .eq('utilisateur_id', row.utilisateur_id)
    .is('used_at', null)
    .neq('id', row.id);

  return { ok: true };
}
