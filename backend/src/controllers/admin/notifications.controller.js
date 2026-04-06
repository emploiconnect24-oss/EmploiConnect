import { supabase } from '../../config/supabase.js';

export async function envoyerNotification(req, res) {
  try {
    const {
      titre,
      message,
      type = 'systeme',
      type_destinataire = 'tous',
      destinataire_id = null,
      lien = null,
    } = req.body;

    if (!titre || !message) {
      return res.status(400).json({
        success: false,
        message: 'Titre et message requis',
      });
    }

    if (type_destinataire === 'individuel' && !destinataire_id) {
      return res.status(400).json({
        success: false,
        message: 'destinataire_id requis pour envoi individuel',
      });
    }

    let rows = [];

    if (type_destinataire === 'individuel') {
      rows.push({
        destinataire_id,
        type_destinataire: 'individuel',
        titre,
        message,
        type,
        lien,
        envoye_par: req.user.id,
      });
    } else {
      let q = supabase.from('utilisateurs').select('id').eq('est_actif', true);
      if (type_destinataire === 'chercheurs') q = q.eq('role', 'chercheur');
      if (type_destinataire === 'entreprises') q = q.eq('role', 'entreprise');
      const { data: users, error } = await q;
      if (error) throw error;
      rows = (users || []).map((u) => ({
        destinataire_id: u.id,
        type_destinataire: type_destinataire === 'tous' ? 'tous' : type_destinataire,
        titre,
        message,
        type,
        lien,
        envoye_par: req.user.id,
      }));
    }

    // Insertion par lots (limite prudente)
    const chunkSize = 500;
    const ids = [];
    for (let i = 0; i < rows.length; i += chunkSize) {
      const chunk = rows.slice(i, i + chunkSize);
      const { data, error } = await supabase.from('notifications').insert(chunk).select('id');
      if (error) throw error;
      (data || []).forEach((r) => ids.push(r.id));
    }

    return res.status(201).json({
      success: true,
      message: `Notification envoyée à ${rows.length} utilisateur(s)`,
      data: {
        nb_envoyes: rows.length,
        ids,
      },
    });
  } catch (err) {
    console.error('[envoyerNotification]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getNotifications(req, res) {
  try {
    const { page = 1, limite = 20, type } = req.query;
    const offset = (parseInt(page, 10) - 1) * parseInt(limite, 10);

    let query = supabase
      .from('notifications')
      .select(
        'id, titre, message, type, type_destinataire, lien, date_envoi_reel, envoye_par',
        { count: 'exact' },
      )
      .not('envoye_par', 'is', null)
      .order('date_envoi_reel', { ascending: false })
      .range(offset, offset + parseInt(limite, 10) - 1);

    if (type) query = query.eq('type', type);

    const { data, count, error } = await query;
    if (error) throw error;

    return res.json({
      success: true,
      data: {
        notifications: data || [],
        pagination: {
          total: count || 0,
          page: parseInt(page, 10),
          limite: parseInt(limite, 10),
          total_pages: Math.ceil((count || 0) / parseInt(limite, 10)),
        },
      },
    });
  } catch (err) {
    console.error('[getNotifications]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
