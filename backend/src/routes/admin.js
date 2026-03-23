/**
 * Routes admin - Réservées aux utilisateurs avec role admin
 * Gestion utilisateurs (validation), statistiques, signalements
 */
import { Router } from 'express';
import { supabase } from '../config/supabase.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { attachProfileIds } from '../helpers/userProfile.js';
import { ROLES } from '../config/constants.js';

const router = Router();

router.use(authenticate);
router.use(requireRole(ROLES.ADMIN));
router.use(attachProfileIds);

/**
 * GET /admin/utilisateurs - Liste des utilisateurs (filtres : role, est_valide, est_actif)
 */
router.get('/utilisateurs', async (req, res) => {
  try {
    const { role, est_valide, est_actif, limit, offset } = req.query;

    let query = supabase
      .from('utilisateurs')
      .select('id, nom, email, role, telephone, est_actif, est_valide, date_creation', { count: 'exact' })
      .order('date_creation', { ascending: false });

    if (role) query = query.eq('role', role);
    if (est_valide !== undefined) query = query.eq('est_valide', est_valide === 'true');
    if (est_actif !== undefined) query = query.eq('est_actif', est_actif === 'true');

    const from = parseInt(offset, 10) || 0;
    const to = from + (parseInt(limit, 10) || 20) - 1;
    const { data, error, count } = await query.range(from, to);

    if (error) {
      console.error('GET /admin/utilisateurs:', error);
      return res.status(500).json({ message: 'Erreur lors de la récupération des utilisateurs' });
    }

    res.json({ utilisateurs: data, total: count ?? data.length });
  } catch (err) {
    console.error('GET /admin/utilisateurs:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * PATCH /admin/utilisateurs/:id - Valider/désactiver un compte
 * Body: { est_valide?, est_actif? }
 */
router.patch('/utilisateurs/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { est_valide, est_actif } = req.body;

    const update = {};
    if (typeof est_valide === 'boolean') update.est_valide = est_valide;
    if (typeof est_actif === 'boolean') update.est_actif = est_actif;

    if (Object.keys(update).length === 0) {
      return res.status(400).json({ message: 'Indiquez est_valide et/ou est_actif' });
    }

    const { data: user } = await supabase.from('utilisateurs').select('id, role').eq('id', id).single();
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur non trouvé' });
    }

    const { data, error } = await supabase
      .from('utilisateurs')
      .update(update)
      .eq('id', id)
      .select('id, nom, email, role, est_actif, est_valide')
      .single();

    if (error) {
      console.error('PATCH /admin/utilisateurs:', error);
      return res.status(500).json({ message: 'Erreur lors de la mise à jour' });
    }

    res.json(data);
  } catch (err) {
    console.error('PATCH /admin/utilisateurs/:id:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /admin/statistiques - Tableau de bord (comptages en temps réel)
 */
router.get('/statistiques', async (req, res) => {
  try {
    const [
      { count: nbChercheurs },
      { count: nbEntreprises },
      { count: nbOffresActives },
      { count: nbOffresTotal },
      { count: nbCandidatures },
      { count: nbCandidaturesAcceptees },
      { count: nbCv },
      { count: nbSignalementsEnAttente },
    ] = await Promise.all([
      supabase.from('chercheurs_emploi').select('id', { count: 'exact', head: true }),
      supabase.from('entreprises').select('id', { count: 'exact', head: true }),
      supabase.from('offres_emploi').select('id', { count: 'exact', head: true }).eq('statut', 'active'),
      supabase.from('offres_emploi').select('id', { count: 'exact', head: true }),
      supabase.from('candidatures').select('id', { count: 'exact', head: true }),
      supabase.from('candidatures').select('id', { count: 'exact', head: true }).eq('statut', 'acceptee'),
      supabase.from('cv').select('id', { count: 'exact', head: true }),
      supabase.from('signalements').select('id', { count: 'exact', head: true }).eq('statut', 'en_attente'),
    ]);

    res.json({
      nombre_chercheurs: nbChercheurs ?? 0,
      nombre_entreprises: nbEntreprises ?? 0,
      nombre_offres_actives: nbOffresActives ?? 0,
      nombre_offres_total: nbOffresTotal ?? 0,
      nombre_candidatures: nbCandidatures ?? 0,
      nombre_candidatures_acceptees: nbCandidaturesAcceptees ?? 0,
      nombre_cv: nbCv ?? 0,
      nombre_signalements_en_attente: nbSignalementsEnAttente ?? 0,
      date_collecte: new Date().toISOString(),
    });
  } catch (err) {
    console.error('GET /admin/statistiques:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /admin/signalements - Liste des signalements (filtres : statut, type_objet)
 */
router.get('/signalements', async (req, res) => {
  try {
    const { statut, type_objet, limit, offset } = req.query;

    let query = supabase
      .from('signalements')
      .select(`
        id,
        type_objet,
        objet_id,
        raison,
        statut,
        date_signalement,
        date_traitement,
        utilisateur_signalant_id
      `, { count: 'exact' })
      .order('date_signalement', { ascending: false });

    if (statut) query = query.eq('statut', statut);
    if (type_objet) query = query.eq('type_objet', type_objet);

    const from = parseInt(offset, 10) || 0;
    const to = from + (parseInt(limit, 10) || 50) - 1;
    const { data, error, count } = await query.range(from, to);

    if (error) {
      console.error('GET /admin/signalements:', error);
      return res.status(500).json({ message: 'Erreur lors de la récupération des signalements' });
    }

    res.json({ signalements: data, total: count ?? data.length });
  } catch (err) {
    console.error('GET /admin/signalements:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * PATCH /admin/signalements/:id - Traiter un signalement (statut: traite | rejete)
 */
router.patch('/signalements/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { statut } = req.body;

    if (!statut || !['traite', 'rejete'].includes(statut)) {
      return res.status(400).json({ message: 'statut requis : traite ou rejete' });
    }

    const { data: adminRow } = await supabase
      .from('administrateurs')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    const update = {
      statut,
      date_traitement: new Date().toISOString(),
      admin_traitant_id: adminRow?.id || null,
    };

    const { data, error } = await supabase
      .from('signalements')
      .update(update)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      if (error.code === 'PGRST116') return res.status(404).json({ message: 'Signalement non trouvé' });
      console.error('PATCH /admin/signalements:', error);
      return res.status(500).json({ message: 'Erreur lors du traitement' });
    }

    res.json(data);
  } catch (err) {
    console.error('PATCH /admin/signalements/:id:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

export default router;
