import { supabase } from '../../config/supabase.js';
import {
  notifySignalementResolutionPourSignalant,
  notifySignalementResolutionPourConcerne,
} from '../../services/candidatureSignalementNotify.service.js';

export async function getSignalements(req, res) {
  try {
    const {
      page = 1,
      limite = 20,
      statut,
      type_objet,
      ordre = 'date_signalement',
      direction = 'desc',
      offset: offsetQ,
      limit: limitLegacy,
    } = req.query;

    const lim = parseInt(limitLegacy || limite, 10) || 20;
    const off = offsetQ != null ? parseInt(offsetQ, 10) : (parseInt(page, 10) - 1) * lim;

    let query = supabase
      .from('signalements')
      .select(
        `
        id, type_objet, objet_id, raison, note_admin, statut,
        date_signalement, date_traitement,
        utilisateur_signalant_id, admin_traitant_id
      `,
        { count: 'exact' },
      )
      .order(ordre, { ascending: direction === 'asc' })
      .range(off, off + lim - 1);

    if (statut) query = query.eq('statut', statut);
    if (type_objet) query = query.eq('type_objet', type_objet);

    const { data, count, error } = await query;
    if (error) throw error;

    const signalementsEnrichis = await Promise.all(
      (data || []).map(async (s) => {
        let objet_details = null;
        if (s.type_objet === 'offre') {
          const { data: offre } = await supabase
            .from('offres_emploi')
            .select('titre, statut, entreprises ( nom_entreprise )')
            .eq('id', s.objet_id)
            .single();
          objet_details = offre;
        } else if (s.type_objet === 'profil' || s.type_objet === 'utilisateur') {
          const { data: user } = await supabase
            .from('utilisateurs')
            .select('nom, email, role, est_actif')
            .eq('id', s.objet_id)
            .single();
          objet_details = user;
        } else if (s.type_objet === 'candidature') {
          const { data: cand } = await supabase
            .from('candidatures')
            .select(
              'statut, date_candidature, offres_emploi ( titre ), chercheurs_emploi ( titre_poste, utilisateurs ( nom, email ) )',
            )
            .eq('id', s.objet_id)
            .maybeSingle();
          objet_details = cand;
        }
        return { ...s, objet_details };
      }),
    );

    const { data: tousStatuts } = await supabase.from('signalements').select('statut');
    const stats = {
      en_attente: tousStatuts?.filter((x) => x.statut === 'en_attente').length || 0,
      traites: tousStatuts?.filter((x) => x.statut === 'traite').length || 0,
      rejetes: tousStatuts?.filter((x) => x.statut === 'rejete').length || 0,
    };

    return res.json({
      success: true,
      signalements: signalementsEnrichis,
      total: count ?? signalementsEnrichis.length,
      data: {
        signalements: signalementsEnrichis,
        stats,
        pagination: {
          total: count || 0,
          page: parseInt(page, 10),
          limite: lim,
          total_pages: Math.ceil((count || 0) / lim),
        },
      },
    });
  } catch (err) {
    console.error('[getSignalements]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getSignalementById(req, res) {
  try {
    const { id } = req.params;
    const { data: row, error } = await supabase.from('signalements').select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    if (!row) {
      return res.status(404).json({ success: false, message: 'Signalement non trouvé' });
    }

    const { data: signalant } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, role')
      .eq('id', row.utilisateur_signalant_id)
      .maybeSingle();

    let admin_traitant = null;
    if (row.admin_traitant_id) {
      const { data: adm } = await supabase
        .from('administrateurs')
        .select('utilisateur_id')
        .eq('id', row.admin_traitant_id)
        .maybeSingle();
      if (adm?.utilisateur_id) {
        const { data: au } = await supabase
          .from('utilisateurs')
          .select('nom, email')
          .eq('id', adm.utilisateur_id)
          .maybeSingle();
        admin_traitant = au;
      }
    }

    return res.json({
      success: true,
      data: { ...row, signalant: signalant || null, admin_traitant },
    });
  } catch (err) {
    console.error('[getSignalementById]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function updateSignalement(req, res) {
  try {
    const { id } = req.params;
    let { statut, action, note, note_admin: noteAdminBody } = req.body;

    if (action && !statut) {
      const map = {
        traiter: 'traite',
        ignorer: 'rejete',
        marquer_urgent: 'en_attente',
      };
      statut = map[action];
    }

    if (!statut || !['traite', 'rejete', 'en_attente'].includes(statut)) {
      return res.status(400).json({
        success: false,
        message: 'statut requis : traite, rejete, en_attente (ou action: traiter, ignorer)',
      });
    }

    const { data: prev } = await supabase
      .from('signalements')
      .select('id, statut, utilisateur_signalant_id, type_objet, objet_id, raison, note_admin')
      .eq('id', id)
      .maybeSingle();
    if (!prev) {
      return res.status(404).json({ success: false, message: 'Signalement non trouvé' });
    }

    const { data: adminRow } = await supabase
      .from('administrateurs')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    const update = {
      statut,
      date_traitement: ['traite', 'rejete'].includes(statut) ? new Date().toISOString() : null,
      admin_traitant_id: adminRow?.id || null,
    };

    const noteKeyPresent = noteAdminBody !== undefined || note !== undefined;
    if (noteKeyPresent) {
      const raw = noteAdminBody !== undefined ? noteAdminBody : note;
      const v = String(raw ?? '').trim();
      update.note_admin = v.length ? v.slice(0, 4000) : null;
    }

    const { data, error } = await supabase
      .from('signalements')
      .update(update)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') return res.status(404).json({ message: 'Signalement non trouvé' });
      throw error;
    }

    if (['traite', 'rejete'].includes(statut) && prev.statut !== statut) {
      const noteAdmin = data.note_admin ?? prev.note_admin ?? null;
      if (prev.utilisateur_signalant_id) {
        void notifySignalementResolutionPourSignalant(prev.utilisateur_signalant_id, {
          statutResolution: statut,
          typeObjet: prev.type_objet,
          raison: prev.raison,
          noteAdmin,
        });
      }
      if (prev.objet_id) {
        void notifySignalementResolutionPourConcerne(prev.objet_id, prev.type_objet, {
          signalantUserId: prev.utilisateur_signalant_id,
          statutResolution: statut,
          raison: prev.raison,
          noteAdmin,
        });
      }
    }

    return res.json({
      success: true,
      message: 'Signalement mis à jour',
      data,
    });
  } catch (err) {
    console.error('[updateSignalement]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
