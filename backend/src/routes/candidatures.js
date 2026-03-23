/**
 * Routes candidatures
 * - Postuler (chercheur)
 * - Liste : mes candidatures (chercheur) ou candidatures d'une offre (entreprise)
 * - Détail et mise à jour du statut (entreprise propriétaire de l'offre ou admin)
 */
import { Router } from 'express';
import { supabase } from '../config/supabase.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { attachProfileIds } from '../helpers/userProfile.js';
import { ROLES } from '../config/constants.js';
import { STATUT_CANDIDATURE } from '../config/constants.js';
import { computeMatchingScoreAsync } from '../services/matchingScore.js';
import { logError } from '../utils/logger.js';

const router = Router();

router.use(authenticate);
router.use(attachProfileIds);

/**
 * POST /candidatures - Postuler à une offre (chercheur uniquement)
 * Body: { offre_id, lettre_motivation?, cv_id? }
 * score_compatibilite peut rester null (sera rempli par le module IA plus tard)
 */
router.post('/', requireRole(ROLES.CHERCHEUR), async (req, res) => {
  try {
    const chercheurId = req.chercheurId;
    if (!chercheurId) {
      return res.status(400).json({ message: 'Profil chercheur introuvable' });
    }

    const { offre_id, lettre_motivation, cv_id } = req.body;

    if (!offre_id) {
      return res.status(400).json({ message: 'offre_id requis' });
    }

    // Vérifier que l'offre existe et est active
    const { data: offre, error: errOffre } = await supabase
      .from('offres_emploi')
      .select('id, statut, exigences, competences_requises')
      .eq('id', offre_id)
      .single();

    if (errOffre || !offre) {
      return res.status(404).json({ message: 'Offre non trouvée' });
    }
    if (offre.statut !== 'active') {
      return res.status(400).json({ message: 'Cette offre n\'accepte plus de candidatures' });
    }

    let cvId = cv_id || null;
    let scoreCompatibilite = null;

    const { data: cvRow } = await supabase
      .from('cv')
      .select('id, competences_extrait, texte_complet')
      .eq('chercheur_id', chercheurId)
      .single();

    if (cvRow) {
      if (!cvId) cvId = cvRow.id;
      scoreCompatibilite = await computeMatchingScoreAsync(
        { competences_extrait: cvRow.competences_extrait, texte_complet: cvRow.texte_complet },
        { exigences: offre.exigences, competences_requises: offre.competences_requises }
      );
    }

    if (lettre_motivation && String(lettre_motivation).length > 4000) {
      return res.status(400).json({ message: 'La lettre de motivation ne doit pas dépasser 4000 caractères' });
    }

    const payload = {
      chercheur_id: chercheurId,
      offre_id,
      cv_id: cvId,
      lettre_motivation: lettre_motivation?.trim() || null,
      statut: STATUT_CANDIDATURE.EN_ATTENTE,
      score_compatibilite: scoreCompatibilite,
    };

    const { data, error } = await supabase
      .from('candidatures')
      .insert(payload)
      .select(`
        id,
        offre_id,
        cv_id,
        date_candidature,
        statut,
        score_compatibilite,
        lettre_motivation
      `)
      .single();

    if (error) {
      if (error.code === '23505') {
        return res.status(409).json({ message: 'Vous avez déjà postulé à cette offre' });
      }
      logError('POST /candidatures - erreur insertion', error);
      return res.status(500).json({ message: 'Erreur lors de la candidature' });
    }

    res.status(201).json(data);
  } catch (err) {
    logError('POST /candidatures - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /candidatures
 * - Chercheur : mes candidatures (toutes)
 * - Entreprise : ?offre_id=xxx obligatoire, candidatures de cette offre (si l'offre m'appartient)
 * - Admin : toutes ou filtrées par offre_id
 */
router.get('/', async (req, res) => {
  try {
    const { role } = req.user;
    const { offre_id: offreId } = req.query;

    if (role === ROLES.CHERCHEUR) {
      if (!req.chercheurId) {
        return res.status(400).json({ message: 'Profil chercheur introuvable' });
      }
      let query = supabase
        .from('candidatures')
        .select(`
          id,
          offre_id,
          date_candidature,
          statut,
          score_compatibilite,
          lettre_motivation,
          offres_emploi(titre, localisation, type_contrat, entreprises(nom_entreprise))
        `)
        .eq('chercheur_id', req.chercheurId)
        .order('date_candidature', { ascending: false });

      const { data, error } = await query;
      if (error) {
        logError('GET /candidatures (chercheur) - erreur requête', error);
        return res.status(500).json({ message: 'Erreur lors de la récupération des candidatures' });
      }
      return res.json({ candidatures: data });
    }

    if (role === ROLES.ENTREPRISE) {
      if (!offreId) {
        return res.status(400).json({ message: 'Pour une entreprise, le paramètre offre_id est requis' });
      }
      const { data: offre } = await supabase
        .from('offres_emploi')
        .select('id')
        .eq('id', offreId)
        .eq('entreprise_id', req.entrepriseId)
        .single();

      if (!offre) {
        return res.status(404).json({ message: 'Offre non trouvée ou vous n\'êtes pas propriétaire' });
      }

      const { data, error } = await supabase
        .from('v_candidatures_completes')
        .select('*')
        .eq('offre_id', offreId)
        .order('score_compatibilite', { ascending: false, nullsFirst: false })
        .order('date_candidature', { ascending: false });

      if (error) {
        logError('GET /candidatures (entreprise) - erreur requête', error);
        return res.status(500).json({ message: 'Erreur lors de la récupération des candidatures' });
      }

      return res.json({ candidatures: data });
    }

    if (role === ROLES.ADMIN) {
      let query = supabase
        .from('v_candidatures_completes')
        .select('*')
        .order('date_candidature', { ascending: false });
      if (offreId) query = query.eq('offre_id', offreId);
      const { data, error } = await query;
      if (error) {
        logError('GET /candidatures (admin) - erreur requête', error);
        return res.status(500).json({ message: 'Erreur lors de la récupération des candidatures' });
      }
      return res.json({ candidatures: data });
    }

    return res.status(403).json({ message: 'Droits insuffisants' });
  } catch (err) {
    logError('GET /candidatures - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /candidatures/:id - Détail d'une candidature
 * Chercheur : uniquement les siennes. Entreprise : si l'offre lui appartient. Admin : toutes
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.user;

    const { data: cand, error } = await supabase
      .from('candidatures')
      .select(`
        *,
        offres_emploi(id, titre, entreprise_id, entreprises(nom_entreprise)),
        chercheurs_emploi(id, competences, niveau_etude)
      `)
      .eq('id', id)
      .single();

    if (error || !cand) {
      return res.status(404).json({ message: 'Candidature non trouvée' });
    }

    if (role === ROLES.CHERCHEUR) {
      if (cand.chercheur_id !== req.chercheurId) {
        return res.status(404).json({ message: 'Candidature non trouvée' });
      }
    } else if (role === ROLES.ENTREPRISE) {
      if (cand.offres_emploi?.entreprise_id !== req.entrepriseId) {
        return res.status(404).json({ message: 'Candidature non trouvée' });
      }
    }
    // Admin : accès à tout

    res.json(cand);
  } catch (err) {
    logError('GET /candidatures/:id - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * PATCH /candidatures/:id - Mettre à jour le statut
 * - Chercheur : peut uniquement passer à "annulee" (sa propre candidature)
 * - Entreprise propriétaire de l'offre ou admin : tous les statuts
 */
router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.user;
    const { statut } = req.body;

    if (!statut || !Object.values(STATUT_CANDIDATURE).includes(statut)) {
      return res.status(400).json({
        message: 'statut requis : en_attente, en_cours, acceptee, refusee, annulee',
      });
    }

    const { data: existing, error: errE } = await supabase
      .from('candidatures')
      .select('id, offre_id, chercheur_id')
      .eq('id', id)
      .single();

    if (errE || !existing) {
      return res.status(404).json({ message: 'Candidature non trouvée' });
    }

    // Chercheur : peut uniquement annuler sa propre candidature
    if (role === ROLES.CHERCHEUR) {
      if (existing.chercheur_id !== req.chercheurId) {
        return res.status(403).json({ message: 'Droits insuffisants' });
      }
      if (statut !== STATUT_CANDIDATURE.ANNULEE) {
        return res.status(403).json({ message: 'En tant que candidat, vous ne pouvez qu\'annuler votre candidature' });
      }
      const { data, error } = await supabase
        .from('candidatures')
        .update({ statut })
        .eq('id', id)
        .select()
        .single();
      if (error) {
        logError('PATCH /candidatures (annulation candidat) - erreur update', error);
        return res.status(500).json({ message: 'Erreur lors de la mise à jour' });
      }
      return res.json(data);
    }

    const { data: offreRow } = await supabase
      .from('offres_emploi')
      .select('entreprise_id')
      .eq('id', existing.offre_id)
      .single();
    const entrepriseId = offreRow?.entreprise_id;

    const isAdmin = role === ROLES.ADMIN;
    const isOwner = role === ROLES.ENTREPRISE && req.entrepriseId && entrepriseId === req.entrepriseId;
    if (!isAdmin && !isOwner) {
      return res.status(403).json({ message: 'Droits insuffisants pour modifier cette candidature' });
    }

    const { data, error } = await supabase
      .from('candidatures')
      .update({ statut })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      logError('PATCH /candidatures (entreprise/admin) - erreur update', error);
      return res.status(500).json({ message: 'Erreur lors de la mise à jour' });
    }

    res.json(data);
  } catch (err) {
    logError('PATCH /candidatures/:id - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

export default router;
