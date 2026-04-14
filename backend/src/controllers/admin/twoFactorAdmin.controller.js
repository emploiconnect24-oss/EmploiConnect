import { supabase } from '../../config/supabase.js';
import { getSecurityParamsCached } from '../../middleware/security.middleware.js';
import {
  activer2FA,
  desactiver2FA,
  genererSetup2FA,
  getAdminTotpRow,
} from '../../services/twoFactor.service.js';

export async function get2faStatus(req, res) {
  try {
    const row = await getAdminTotpRow(req.user.id);
    if (!row) {
      return res.status(403).json({ success: false, message: 'Administrateur introuvable' });
    }
    return res.json({
      success: true,
      data: {
        twofa_actif: row.twofa_actif === true,
        setup_pending: !!(row.totp_secret_temp && String(row.totp_secret_temp).trim()),
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function get2faSetup(req, res) {
  try {
    const sec = await getSecurityParamsCached();
    if (String(sec.twofa_admin_actif || '').toLowerCase() !== 'true') {
      return res.status(403).json({
        success: false,
        message: 'La fonctionnalité 2FA est désactivée dans les paramètres plateforme.',
      });
    }
    const { data: u, error } = await supabase
      .from('utilisateurs')
      .select('email')
      .eq('id', req.user.id)
      .single();
    if (error || !u) {
      return res.status(400).json({ success: false, message: 'Utilisateur introuvable' });
    }
    const result = await genererSetup2FA(req.user.id, u.email);
    return res.json({ success: true, data: result });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
}

export async function post2faActiver(req, res) {
  try {
    const sec = await getSecurityParamsCached();
    if (String(sec.twofa_admin_actif || '').toLowerCase() !== 'true') {
      return res.status(403).json({
        success: false,
        message: 'La fonctionnalité 2FA est désactivée dans les paramètres plateforme.',
      });
    }
    const code = req.body?.code;
    await activer2FA(req.user.id, code);
    return res.json({ success: true, message: '2FA activé avec succès.' });
  } catch (err) {
    return res.status(400).json({ success: false, message: err.message || 'Erreur' });
  }
}

export async function post2faDesactiver(req, res) {
  try {
    const code = req.body?.code;
    await desactiver2FA(req.user.id, code);
    return res.json({ success: true, message: '2FA désactivé.' });
  } catch (err) {
    return res.status(400).json({ success: false, message: err.message || 'Erreur' });
  }
}
