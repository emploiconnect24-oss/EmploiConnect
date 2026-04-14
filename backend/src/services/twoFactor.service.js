/**
 * TOTP 2FA pour les comptes administrateurs (otplib v13 API fonctionnelle + qrcode).
 */
import { generateSecret, generateURI, verifySync } from 'otplib';
import QRCode from 'qrcode';
import { supabase } from '../config/supabase.js';

const APP_NAME = 'EmploiConnect';

function totpValid(secret, token) {
  const s = String(secret || '').trim();
  const t = String(token || '').trim();
  if (!s || !t) return false;
  try {
    return verifySync({ secret: s, token: t }).valid === true;
  } catch {
    return false;
  }
}

export async function getAdminTotpRow(utilisateurId) {
  const { data, error } = await supabase
    .from('administrateurs')
    .select('id, totp_secret, totp_secret_temp, twofa_actif')
    .eq('utilisateur_id', utilisateurId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function genererSetup2FA(utilisateurId, email) {
  const admin = await getAdminTotpRow(utilisateurId);
  if (!admin?.id) {
    throw new Error('Profil administrateur introuvable');
  }
  const secret = generateSecret();
  const { error } = await supabase
    .from('administrateurs')
    .update({
      totp_secret_temp: secret,
    })
    .eq('id', admin.id);
  if (error) throw error;

  const otpauth = generateURI({
    issuer: APP_NAME,
    label: String(email || 'admin'),
    secret,
  });
  const qrCodeDataUrl = await QRCode.toDataURL(otpauth, { margin: 1, width: 220 });
  return { secret, qrCodeDataUrl };
}

export async function activer2FA(utilisateurId, code) {
  const admin = await getAdminTotpRow(utilisateurId);
  if (!admin?.id) throw new Error('Profil administrateur introuvable');
  const temp = admin.totp_secret_temp;
  if (!temp) throw new Error('Aucune configuration 2FA en cours. Relancez « Activer ».');

  if (!totpValid(temp, code)) throw new Error('Code 2FA invalide');

  const { error } = await supabase
    .from('administrateurs')
    .update({
      totp_secret: temp,
      totp_secret_temp: null,
      twofa_actif: true,
    })
    .eq('id', admin.id);
  if (error) throw error;
  return true;
}

export async function desactiver2FA(utilisateurId, code) {
  const admin = await getAdminTotpRow(utilisateurId);
  if (!admin?.id) throw new Error('Profil administrateur introuvable');
  if (!admin.twofa_actif || !admin.totp_secret) {
    throw new Error('Le 2FA n’est pas activé');
  }
  if (!totpValid(admin.totp_secret, code)) throw new Error('Code 2FA invalide');

  const { error } = await supabase
    .from('administrateurs')
    .update({
      totp_secret: null,
      totp_secret_temp: null,
      twofa_actif: false,
    })
    .eq('id', admin.id);
  if (error) throw error;
  return true;
}

export function verifierCodeTotp(secret, code) {
  return totpValid(secret, code);
}
