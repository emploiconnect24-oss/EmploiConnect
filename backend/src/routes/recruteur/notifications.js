import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase } from '../../config/supabase.js';

const router = Router();
router.use(authenticate, requireRecruteur);

router.get('/', async (req, res) => {
  try {
    const { page = 1, limite = 30, lu, type } = req.query;
    const lim = Math.min(100, Math.max(1, parseInt(limite, 10) || 30));
    const offset = (Math.max(1, parseInt(page, 10) || 1) - 1) * lim;

    let query = supabase
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .order('date_creation', { ascending: false })
      .range(offset, offset + lim - 1);

    if (lu === 'true') query = query.eq('est_lue', true);
    else if (lu === 'false') query = query.eq('est_lue', false);
    if (type && String(type).trim() !== '' && type !== 'all') {
      query = query.eq('type', String(type).trim());
    }

    const { data, count, error } = await query;
    if (error) throw error;

    const { count: unread } = await supabase
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('destinataire_id', req.user.id)
      .eq('est_lue', false);

    const { data: allForStats } = await supabase
      .from('notifications')
      .select('type, est_lue')
      .eq('destinataire_id', req.user.id);

    const parType = {};
    for (const n of allForStats || []) {
      const t = n.type || 'autre';
      parType[t] = (parType[t] || 0) + 1;
    }

    return res.json({
      success: true,
      data: {
        notifications: data || [],
        nb_non_lues: unread ?? 0,
        total: count || 0,
        page: parseInt(page, 10) || 1,
        limite: lim,
        meta: {
          par_type: parType,
          total_chargees: (data || []).length,
        },
      },
    });
  } catch (err) {
    console.error('[recruteur/notifications GET]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.patch('/:id/lire', async (req, res) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .update({ est_lue: true })
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id);
    if (error) throw error;
    return res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.patch('/tout-lire/action', async (req, res) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .update({ est_lue: true })
      .eq('destinataire_id', req.user.id)
      .eq('est_lue', false);
    if (error) throw error;
    return res.json({ success: true, message: 'Toutes les notifications marquées comme lues' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
