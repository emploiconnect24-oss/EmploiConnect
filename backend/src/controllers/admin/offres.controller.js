import { supabase } from '../../config/supabase.js';
import { sendOffreModerationEmailToRecruiter } from '../../services/mail.service.js';
import { notifierAlertesPourOffrePubliee } from '../../services/alerteEmploiNotify.service.js';

export async function getOffres(req, res) {
  try {
    const {
      page = 1,
      limite = 20,
      statut,
      domaine,
      localisation,
      entreprise_id,
      recherche,
      ordre = 'date_creation',
      direction = 'desc',
    } = req.query;

    const offset = (parseInt(page, 10) - 1) * parseInt(limite, 10);

    let query = supabase
      .from('offres_emploi')
      .select(
        `
        id, titre, localisation, type_contrat, domaine,
        statut, nombre_postes, en_vedette,
        salaire_min, salaire_max, devise,
        date_publication, date_limite, date_creation,
        raison_refus, entreprise_id,
        entreprises ( id, nom_entreprise, logo_url, secteur_activite, utilisateur_id )
      `,
        { count: 'exact' },
      )
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite, 10) - 1);

    if (statut) query = query.eq('statut', statut);
    if (domaine) query = query.ilike('domaine', `%${domaine}%`);
    if (localisation) query = query.ilike('localisation', `%${localisation}%`);
    if (entreprise_id) query = query.eq('entreprise_id', entreprise_id);
    if (recherche) query = query.ilike('titre', `%${recherche}%`);

    const { data, count, error } = await query;
    if (error) throw error;

    const { data: tousStatuts } = await supabase.from('offres_emploi').select('statut');
    const statsStatuts = {
      total: count || 0,
      actives: tousStatuts?.filter((o) => o.statut === 'active' || o.statut === 'publiee').length || 0,
      brouillons: tousStatuts?.filter((o) => o.statut === 'brouillon').length || 0,
      suspendues: tousStatuts?.filter((o) => o.statut === 'suspendue' || o.statut === 'refusee').length || 0,
      fermees: tousStatuts?.filter((o) => o.statut === 'fermee').length || 0,
    };

    const offreIds = (data || []).map((o) => o.id);
    const candidaturesCount = {};
    if (offreIds.length > 0) {
      const { data: cands } = await supabase.from('candidatures').select('offre_id').in('offre_id', offreIds);
      (cands || []).forEach((c) => {
        candidaturesCount[c.offre_id] = (candidaturesCount[c.offre_id] || 0) + 1;
      });
    }

    const offresAvecStats = (data || []).map((o) => ({
      ...o,
      nb_candidatures: candidaturesCount[o.id] || 0,
    }));

    return res.json({
      success: true,
      data: {
        offres: offresAvecStats,
        stats: statsStatuts,
        pagination: {
          total: count || 0,
          page: parseInt(page, 10),
          limite: parseInt(limite, 10),
          total_pages: Math.ceil((count || 0) / parseInt(limite, 10)),
        },
      },
    });
  } catch (err) {
    console.error('[getOffres]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getOffreById(req, res) {
  try {
    const { id } = req.params;
    const { data, error } = await supabase
      .from('offres_emploi')
      .select(
        `
        *,
        entreprises ( id, nom_entreprise, description, secteur_activite, logo_url, adresse_siege, utilisateur_id )
      `,
      )
      .eq('id', id)
      .single();

    if (error || !data) {
      return res.status(404).json({ success: false, message: 'Offre non trouvée' });
    }

    const { count: nbCand } = await supabase
      .from('candidatures')
      .select('id', { count: 'exact', head: true })
      .eq('offre_id', id);

    return res.json({ success: true, data: { ...data, nb_candidatures: nbCand ?? 0 } });
  } catch (err) {
    console.error('[getOffreById]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

async function republishPayload() {
  const { data: params } = await supabase
    .from('parametres_plateforme')
    .select('valeur')
    .eq('cle', 'duree_validite_offre_jours')
    .maybeSingle();
  const nbJours = parseInt(params?.valeur || '30', 10);
  const dateLimite = new Date();
  dateLimite.setDate(dateLimite.getDate() + nbJours);
  return {
    statut: 'publiee',
    date_publication: new Date().toISOString(),
    date_limite: dateLimite.toISOString().split('T')[0],
    raison_refus: null,
  };
}

async function notifierRecruteur({ offreId, entrepriseId, action, raisonRefus }) {
  try {
    const { data: entreprise } = await supabase
      .from('entreprises')
      .select('utilisateur_id')
      .eq('id', entrepriseId)
      .single();
    if (!entreprise?.utilisateur_id) return;

    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('titre')
      .eq('id', offreId)
      .single();

    let titre = '';
    let message = '';
    if (action === 'valider') {
      titre = '✅ Votre offre a été validée !';
      message = `Votre offre "${offre?.titre}" est maintenant publiée et visible par les candidats.`;
    } else if (action === 'refuser') {
      titre = '❌ Votre offre a été refusée';
      message = `Votre offre "${offre?.titre}" a été refusée.${raisonRefus ? ` Motif: ${raisonRefus}` : ''}`;
    } else if (action === 'mettre_en_vedette') {
      titre = '⭐ Votre offre est mise en vedette !';
      message = `Votre offre "${offre?.titre}" est maintenant mise en avant sur la plateforme.`;
    }
    if (!titre) return;

    await supabase.from('notifications').insert({
      destinataire_id: entreprise.utilisateur_id,
      type_destinataire: 'individuel',
      titre,
      message,
      type: 'offre',
      lien: '/dashboard-recruteur/offres',
    });
    void sendOffreModerationEmailToRecruiter(
      entreprise.utilisateur_id,
      titre,
      message,
    );
  } catch (e) {
    console.warn('[notifierRecruteur] Non bloquant:', e.message);
  }
}

export async function updateOffre(req, res) {
  try {
    const { id } = req.params;
    const { action, raison_refus } = req.body;

    const { data: offreActuelle, error: fetchErr } = await supabase
      .from('offres_emploi')
      .select('id, statut, en_vedette, titre, entreprise_id')
      .eq('id', id)
      .single();

    if (fetchErr || !offreActuelle) {
      return res.status(404).json({ success: false, message: 'Offre non trouvée' });
    }

    let updateData = {};
    let messageReponse = 'Offre mise à jour';

    switch (action) {
      case 'valider':
        updateData = {
          statut: 'publiee',
          valide_par: req.user.id,
          date_validation: new Date().toISOString(),
          date_publication: new Date().toISOString(),
          raison_refus: null,
        };
        messageReponse = 'Offre validée et publiée';
        break;
      case 'refuser':
        if (!raison_refus) {
          return res.status(400).json({
            success: false,
            message: 'Un motif de refus est requis',
          });
        }
        updateData = {
          statut: 'refusee',
          raison_refus: String(raison_refus).trim(),
        };
        messageReponse = 'Offre refusée';
        break;
      case 'mettre_en_vedette':
        updateData = { en_vedette: true };
        messageReponse = 'Offre mise en vedette';
        break;
      case 'retirer_vedette':
        updateData = { en_vedette: false };
        messageReponse = 'Offre retirée de la vedette';
        break;
      case 'archiver':
        updateData = { statut: 'fermee' };
        messageReponse = 'Offre archivée';
        break;
      case 'desarchiver':
        if (offreActuelle.statut !== 'fermee') {
          return res.status(400).json({
            success: false,
            message: 'Seules les offres archivées (fermées) peuvent être désarchivées',
          });
        }
        updateData = await republishPayload();
        messageReponse = 'Offre désarchivée et republiée';
        break;
      case 'republier':
        updateData = await republishPayload();
        messageReponse = 'Offre republiée';
        break;
      default:
        return res.status(400).json({
          success: false,
          message:
            'Action invalide. Valeurs: valider, refuser, mettre_en_vedette, retirer_vedette, archiver, desarchiver, republier',
        });
    }

    const { data, error } = await supabase
      .from('offres_emploi')
      .update(updateData)
      .eq('id', id)
      .select(`
        id, titre, statut, en_vedette, raison_refus,
        entreprises ( nom_entreprise )
      `)
      .single();

    if (error) throw error;

    const prevLive = ['publiee', 'active'].includes(String(offreActuelle.statut || '').toLowerCase());
    const nowLive = ['publiee', 'active'].includes(String(data.statut || '').toLowerCase());
    if (!prevLive && nowLive) {
      setImmediate(() => {
        void notifierAlertesPourOffrePubliee(id);
      });
    }

    if (['valider', 'refuser', 'mettre_en_vedette'].includes(action)) {
      setImmediate(() => {
        notifierRecruteur({
          offreId: id,
          entrepriseId: offreActuelle.entreprise_id,
          action,
          raisonRefus: raison_refus,
        });
      });
    }

    return res.json({
      success: true,
      message: messageReponse,
      data,
    });
  } catch (err) {
    console.error('[updateOffre]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function exportOffresCsv(req, res) {
  try {
    const { data, error } = await supabase
      .from('offres_emploi')
      .select(
        `
        titre, localisation, type_contrat, statut,
        salaire_min, salaire_max, devise,
        date_publication, date_limite,
        entreprises ( nom_entreprise )
      `,
      )
      .order('date_creation', { ascending: false });

    if (error) throw error;

    const lines = ['Titre,Entreprise,Ville,Contrat,Salaire Min,Salaire Max,Statut,Date Publication'];
    for (const o of data || []) {
      const ent = o.entreprises;
      const eRow = Array.isArray(ent) ? ent[0] : ent;
      const nomEnt = eRow?.nom_entreprise ?? '';
      const esc = (v) => {
        const s = v == null ? '' : String(v);
        if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
        return s;
      };
      lines.push(
        [
          esc(o.titre),
          esc(nomEnt),
          esc(o.localisation),
          esc(o.type_contrat),
          esc(o.salaire_min),
          esc(o.salaire_max),
          esc(o.statut),
          esc((o.date_publication || '').toString().split('T')[0]),
        ].join(','),
      );
    }

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="offres_emploiconnect.csv"');
    return res.send(`\uFEFF${lines.join('\n')}`);
  } catch (err) {
    console.error('[exportOffresCsv]', err);
    res.status(500).json({ success: false, message: 'Erreur export' });
  }
}

export async function deleteOffre(req, res) {
  try {
    const { id } = req.params;
    const { data: offre } = await supabase.from('offres_emploi').select('titre').eq('id', id).single();
    if (!offre) {
      return res.status(404).json({ success: false, message: 'Offre non trouvée' });
    }
    const { error } = await supabase.from('offres_emploi').delete().eq('id', id);
    if (error) throw error;
    return res.json({
      success: true,
      message: `Offre "${offre.titre}" supprimée définitivement`,
    });
  } catch (err) {
    console.error('[deleteOffre]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
