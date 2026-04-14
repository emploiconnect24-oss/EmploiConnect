/**
 * Vérification rôle administrateur + ligne administrateurs.
 * À utiliser après authenticate (req.user défini).
 */
import { supabase } from '../config/supabase.js';

export async function requireAdmin(req, res, next) {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Authentification requise' });
    }
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Droits administrateur requis.',
      });
    }
    const { data: admin, error } = await supabase
      .from('administrateurs')
      .select('id, niveau_acces, role_id, est_super_admin, est_actif')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (error || !admin) {
      return res.status(403).json({
        success: false,
        message: 'Compte administrateur non trouvé',
      });
    }
    if (admin.est_actif === false) {
      return res.status(403).json({
        success: false,
        message: 'Compte administrateur désactivé',
      });
    }
    req.admin = admin;
    next();
  } catch (err) {
    console.error('[adminAuth]', err);
    res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la vérification des droits',
    });
  }
}
