import { supabase } from '../../config/supabase.js';

/**
 * GET /api/admin/entreprises/:id
 * [id] = UUID entreprise OU UUID utilisateur (compte entreprise).
 */
export async function getEntrepriseDetail(req, res) {
  try {
    const { id } = req.params;

    let { data: ent } = await supabase.from('entreprises').select('*').eq('id', id).maybeSingle();
    if (!ent) {
      const r = await supabase.from('entreprises').select('*').eq('utilisateur_id', id).maybeSingle();
      ent = r.data;
    }

    if (!ent) {
      return res.status(404).json({ success: false, message: 'Entreprise non trouvée' });
    }

    const { data: user, error: uErr } = await supabase
      .from('utilisateurs')
      .select(
        `
        id, nom, email, telephone, adresse,
        est_actif, est_valide, date_creation,
        raison_blocage, derniere_connexion
      `,
      )
      .eq('id', ent.utilisateur_id)
      .single();

    if (uErr || !user) {
      return res.status(404).json({ success: false, message: 'Entreprise non trouvée' });
    }

    const { data: offres } = await supabase
      .from('offres_emploi')
      .select('id, titre, statut, date_publication, nombre_postes')
      .eq('entreprise_id', ent.id)
      .order('date_publication', { ascending: false });

    const oids = (offres || []).map((o) => o.id);
    let nbCandidatures = 0;
    if (oids.length > 0) {
      const { count } = await supabase
        .from('candidatures')
        .select('id', { count: 'exact', head: true })
        .in('offre_id', oids);
      nbCandidatures = count ?? 0;
    }

    const entreprisePayload = {
      id: ent.id,
      nom_entreprise: ent.nom_entreprise,
      description: ent.description,
      secteur_activite: ent.secteur_activite,
      taille_entreprise: ent.taille_entreprise,
      site_web: ent.site_web,
      logo_url: ent.logo_url,
      banniere_url: ent.banniere_url,
      adresse_siege: ent.adresse_siege,
    };

    return res.json({
      success: true,
      data: {
        ...user,
        entreprise: entreprisePayload,
        offres: offres || [],
        nb_candidatures_total: nbCandidatures,
      },
    });
  } catch (err) {
    console.error('[getEntrepriseDetail]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

export async function getEntreprises(req, res) {
  try {
    const {
      page = 1,
      limite = 20,
      statut,
      secteur,
      ville,
      recherche,
      ordre = 'date_creation',
      direction = 'desc',
    } = req.query;

    const offset = (parseInt(page, 10) - 1) * parseInt(limite, 10);

    let query = supabase
      .from('entreprises')
      .select(
        `
        id, nom_entreprise, description, secteur_activite,
        taille_entreprise, site_web, logo_url, adresse_siege,
        date_creation, utilisateur_id,
        utilisateurs ( id, nom, email, telephone, est_actif, est_valide, date_creation )
      `,
        { count: 'exact' },
      )
      .order(ordre, { ascending: direction === 'asc' })
      .range(offset, offset + parseInt(limite, 10) - 1);

    if (secteur) query = query.eq('secteur_activite', secteur);
    if (ville) query = query.ilike('adresse_siege', `%${ville}%`);
    if (recherche) query = query.ilike('nom_entreprise', `%${recherche}%`);

    const { data, count, error } = await query;
    if (error) throw error;

    const uOf = (e) => {
      const u = e.utilisateurs;
      return Array.isArray(u) ? u[0] : u;
    };

    let entreprises = data || [];
    if (statut === 'actif') {
      entreprises = entreprises.filter((e) => {
        const u = uOf(e);
        return u?.est_actif && u?.est_valide;
      });
    }
    if (statut === 'en_attente') {
      entreprises = entreprises.filter((e) => !uOf(e)?.est_valide);
    }
    if (statut === 'bloque') {
      entreprises = entreprises.filter((e) => {
        const u = uOf(e);
        return !u?.est_actif && u?.est_valide;
      });
    }

    const entIds = entreprises.map((e) => e.id);
    const offresCount = {};
    if (entIds.length > 0) {
      const { data: offres } = await supabase
        .from('offres_emploi')
        .select('entreprise_id, statut')
        .in('entreprise_id', entIds);
      (offres || []).forEach((o) => {
        if (!offresCount[o.entreprise_id]) {
          offresCount[o.entreprise_id] = { total: 0, actives: 0 };
        }
        offresCount[o.entreprise_id].total += 1;
        if (o.statut === 'active') offresCount[o.entreprise_id].actives += 1;
      });
    }

    const result = entreprises.map((e) => ({
      ...e,
      nb_offres_total: offresCount[e.id]?.total || 0,
      nb_offres_actives: offresCount[e.id]?.actives || 0,
    }));

    return res.json({
      success: true,
      data: {
        entreprises: result,
        pagination: {
          total: count || 0,
          page: parseInt(page, 10),
          limite: parseInt(limite, 10),
          total_pages: Math.ceil((count || 0) / parseInt(limite, 10)),
        },
      },
    });
  } catch (err) {
    console.error('[getEntreprises]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}

/**
 * PATCH /api/admin/entreprises/:id — id = UUID entreprise (table entreprises)
 */
export async function updateEntreprise(req, res) {
  try {
    const { id } = req.params;
    const { action, raison } = req.body;

    const { data: ent, error: entErr } = await supabase
      .from('entreprises')
      .select('id, utilisateur_id')
      .eq('id', id)
      .single();

    if (entErr || !ent) {
      return res.status(404).json({ success: false, message: 'Entreprise non trouvée' });
    }

    let updateData = {};

    switch (action) {
      case 'valider':
        updateData = {
          est_valide: true,
          est_actif: true,
          traite_par: req.user.id,
          raison_blocage: null,
        };
        break;
      case 'suspendre':
        if (!raison) {
          return res.status(400).json({ success: false, message: 'Raison requise' });
        }
        updateData = { est_actif: false, raison_blocage: raison, traite_par: req.user.id };
        break;
      case 'reactiver':
      case 'lever_suspension':
        updateData = { est_actif: true, raison_blocage: null, traite_par: req.user.id };
        break;
      case 'rejeter':
        updateData = {
          est_valide: false,
          est_actif: false,
          raison_blocage: raison || 'Entreprise rejetée',
          traite_par: req.user.id,
        };
        break;
      default:
        return res.status(400).json({
          success: false,
          message: 'Action invalide. Valeurs: valider, suspendre, lever_suspension, reactiver, rejeter',
        });
    }

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(updateData)
      .eq('id', ent.utilisateur_id)
      .select('id, nom, email, est_actif, est_valide')
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: 'Entreprise / compte mis à jour',
      data,
    });
  } catch (err) {
    console.error('[updateEntreprise]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
