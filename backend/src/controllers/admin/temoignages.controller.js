import { supabase } from '../../config/supabase.js';

async function notifierCandidatTemoignage(utilisateurId, { approuve, note }) {
  if (!utilisateurId) return;
  const titre = approuve
    ? 'Témoignage publié'
    : 'Témoignage non retenu';
  const message = approuve
    ? 'Votre témoignage a été validé et est visible sur la page d’accueil.'
    : `Votre témoignage n’a pas été retenu pour la vitrine.${note ? ` Motif : ${note}` : ''}`;
  try {
    await supabase.from('notifications').insert({
      destinataire_id: utilisateurId,
      type_destinataire: 'individuel',
      titre,
      message,
      type: 'systeme',
      lien: approuve ? '/' : '/dashboard/temoignage',
      est_lue: false,
    });
  } catch (e) {
    console.warn('[notifierCandidatTemoignage]', e.message);
  }
}

export async function getTemoignages(req, res) {
  try {
    const statut = String(req.query.statut || 'all').trim().toLowerCase();
    const allowed = new Set(['all', 'en_attente', 'approuve', 'refuse']);
    const filt = allowed.has(statut) ? statut : 'all';

    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 200);
    const offset = Math.max(parseInt(req.query.offset, 10) || 0, 0);

    let q = supabase
      .from('temoignages_recrutement')
      .select(
        `
        id,
        message,
        statut_moderation,
        est_publie,
        note_moderation,
        date_creation,
        date_moderation,
        candidature_id,
        utilisateur_id,
        utilisateurs ( id, nom, email, photo_url ),
        entreprises ( id, nom_entreprise, logo_url )
      `,
        { count: 'exact' },
      )
      .order('date_creation', { ascending: false })
      .range(offset, offset + limit - 1);

    if (filt !== 'all') {
      q = q.eq('statut_moderation', filt);
    }

    const { data, error, count } = await q;
    if (error) throw error;

    const rows = (data || []).map((row) => {
      const u = row.utilisateurs;
      const uRow = Array.isArray(u) ? u[0] : u;
      const e = row.entreprises;
      const eRow = Array.isArray(e) ? e[0] : e;
      return {
        id: row.id,
        message: row.message,
        statut_moderation: row.statut_moderation,
        est_publie: row.est_publie,
        note_moderation: row.note_moderation,
        date_creation: row.date_creation,
        date_moderation: row.date_moderation,
        candidature_id: row.candidature_id,
        utilisateur_id: row.utilisateur_id,
        candidat: uRow
          ? { id: uRow.id, nom: uRow.nom, email: uRow.email, photo_url: uRow.photo_url }
          : null,
        entreprise: eRow
          ? { id: eRow.id, nom_entreprise: eRow.nom_entreprise, logo_url: eRow.logo_url }
          : null,
      };
    });

    return res.json({
      success: true,
      data: { temoignages: rows, total: count ?? rows.length },
    });
  } catch (err) {
    console.error('[admin getTemoignages]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function patchTemoignage(req, res) {
  try {
    const { id } = req.params;
    const action = String(req.body?.action || '').trim().toLowerCase();
    const noteModeration = req.body?.note_moderation != null ? String(req.body.note_moderation).trim() : '';

    if (!action || !['approuver', 'refuser'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'action requise : approuver ou refuser',
      });
    }

    const { data: row, error: fe } = await supabase
      .from('temoignages_recrutement')
      .select('id, utilisateur_id, statut_moderation')
      .eq('id', id)
      .maybeSingle();

    if (fe) throw fe;
    if (!row) {
      return res.status(404).json({ success: false, message: 'Témoignage introuvable' });
    }

    const now = new Date().toISOString();
    const adminUserId = req.user?.id || null;

    if (action === 'approuver') {
      const { data: updated, error: ue } = await supabase
        .from('temoignages_recrutement')
        .update({
          statut_moderation: 'approuve',
          est_publie: true,
          note_moderation: noteModeration || null,
          date_moderation: now,
          moderateur_user_id: adminUserId,
        })
        .eq('id', id)
        .select('id')
        .single();

      if (ue) throw ue;
      void notifierCandidatTemoignage(row.utilisateur_id, { approuve: true, note: noteModeration });

      return res.json({
        success: true,
        message: 'Témoignage publié.',
        data: updated,
      });
    }

    const { data: updated, error: ue } = await supabase
      .from('temoignages_recrutement')
      .update({
        statut_moderation: 'refuse',
        est_publie: false,
        note_moderation: noteModeration || null,
        date_moderation: now,
        moderateur_user_id: adminUserId,
      })
      .eq('id', id)
      .select('id')
      .single();

    if (ue) throw ue;
    void notifierCandidatTemoignage(row.utilisateur_id, { approuve: false, note: noteModeration });

    return res.json({
      success: true,
      message: 'Témoignage refusé.',
      data: updated,
    });
  } catch (err) {
    console.error('[admin patchTemoignage]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
