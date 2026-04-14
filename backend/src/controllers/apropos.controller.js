/**
 * Sections page « À propos » (public + admin authentifié).
 */
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';

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
