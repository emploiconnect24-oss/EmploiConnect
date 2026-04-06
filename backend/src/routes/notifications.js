/**
 * Notifications reçues par l'utilisateur connecté (admin, candidat, recruteur).
 */
import { Router } from 'express';
import { authenticate } from '../middleware/auth.js';
import { supabase } from '../config/supabase.js';

const router = Router();
router.use(authenticate);

router.get('/mes', async (req, res) => {
  try {
    const { page = 1, limite = 20, non_lues_seulement = 'false' } = req.query;
    const p = parseInt(page, 10) || 1;
    const l = Math.min(parseInt(limite, 10) || 20, 100);
    const offset = (p - 1) * l;
    const onlyUnread = non_lues_seulement === 'true' || non_lues_seulement === true;

    let query = supabase
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .order('date_creation', { ascending: false })
      .range(offset, offset + l - 1);

    if (onlyUnread) query = query.eq('est_lue', false);

    const { data, count, error } = await query;
    if (error) throw error;

    const { count: nonLues, error: errCount } = await supabase
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('destinataire_id', req.user.id)
      .eq('est_lue', false);
    if (errCount) throw errCount;

    return res.json({
      success: true,
      data: {
        notifications: data || [],
        nb_non_lues: nonLues ?? 0,
        pagination: {
          total: count || 0,
          page: p,
          limite: l,
          total_pages: Math.ceil((count || 0) / l) || 0,
        },
      },
    });
  } catch (err) {
    console.error('[GET /notifications/mes]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
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
    return res.json({
      success: true,
      message: 'Toutes les notifications marquées comme lues',
    });
  } catch (err) {
    console.error('[PATCH /notifications/tout-lire/action]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/parametres', async (req, res) => {
  try {
    const {
      email_candidature: emailCandidature,
      email_message: emailMessage,
      notif_in_app: notifInApp,
      offres_alertes_email: offresAlertes,
      resume_hebdo: resumeHebdo,
      conseils_email: conseilsEmail,
    } = req.body || {};

    const payload = {
      notif_nouvelles_candidatures: emailCandidature ?? true,
      notif_messages_recus: emailMessage ?? true,
      notif_push: notifInApp ?? true,
    };
    if (offresAlertes !== undefined) payload.notif_offres_expiration = !!offresAlertes;
    if (resumeHebdo !== undefined) payload.notif_resume_hebdo = !!resumeHebdo;

    const { error } = await supabase
      .from('utilisateurs')
      .update(payload)
      .eq('id', req.user.id);
    if (error) throw error;

    if (conseilsEmail !== undefined) {
      const { data: u2, error: e2 } = await supabase
        .from('utilisateurs')
        .select('preferences_notif')
        .eq('id', req.user.id)
        .single();
      if (e2) throw e2;
      const base = u2?.preferences_notif && typeof u2.preferences_notif === 'object'
        ? { ...u2.preferences_notif }
        : {};
      base.conseils_email = !!conseilsEmail;
      const { error: e3 } = await supabase
        .from('utilisateurs')
        .update({ preferences_notif: base })
        .eq('id', req.user.id);
      if (e3) throw e3;
    }

    return res.json({
      success: true,
      message: 'Préférences de notification sauvegardées',
      data: payload,
    });
  } catch (err) {
    console.error('[POST /notifications/parametres]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.patch('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('notifications')
      .update({ est_lue: true })
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id)
      .select()
      .maybeSingle();

    if (error) throw error;
    if (!data) {
      return res.status(404).json({ success: false, message: 'Notification introuvable' });
    }
    return res.json({ success: true, data });
  } catch (err) {
    console.error('[PATCH /notifications/:id]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id)
      .select('id');

    if (error) throw error;
    if (!data?.length) {
      return res.status(404).json({ success: false, message: 'Notification introuvable' });
    }
    return res.json({ success: true, message: 'Notification supprimée' });
  } catch (err) {
    console.error('[DELETE /notifications/:id]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
