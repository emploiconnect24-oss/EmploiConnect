/**
 * Routes offres d'emploi
 * - Liste publique (avec filtres), détail
 * - CRUD pour les entreprises (leurs offres) et l'admin
 */
import { Router } from 'express';
import { supabase } from '../config/supabase.js';
import { authenticate, requireRole, optionalAuth } from '../middleware/auth.js';
import { attachProfileIds } from '../helpers/userProfile.js';
import { ROLES } from '../config/constants.js';
import { STATUT_OFFRE } from '../config/constants.js';
import { logError } from '../utils/logger.js';

const router = Router();

/**
 * GET /offres
 * Liste des offres. Par défaut : statut=active. Filtres : statut, domaine, localisation, type_contrat
 * Si authentifié en tant qu'entreprise et ?mes=1 : uniquement les offres de mon entreprise
 */
router.get('/', optionalAuth, attachProfileIds, async (req, res) => {
  try {
    const { statut, domaine, localisation, type_contrat, mes } = req.query;

    let query = supabase
      .from('offres_emploi')
      .select(`
        id,
        entreprise_id,
        titre,
        description,
        exigences,
        salaire_min,
        salaire_max,
        devise,
        localisation,
        type_contrat,
        niveau_experience_requis,
        domaine,
        statut,
        nombre_postes,
        date_publication,
        date_limite,
        date_creation,
        entreprises(nom_entreprise, secteur_activite)
      `, { count: 'exact' })
      .order('date_publication', { ascending: false });

    // "Mes offres" pour une entreprise connectée
    if (mes === '1' && req.user?.role === ROLES.ENTREPRISE && req.entrepriseId) {
      query = query.eq('entreprise_id', req.entrepriseId);
    } else if (mes === '1' && req.user?.role === ROLES.ADMIN) {
      // Admin peut voir toutes avec mes=1 (pas de filtre entreprise)
    } else {
      // Par défaut : uniquement les offres actives (sauf pour l'admin qui peut tout voir)
      const isAdmin = req.user?.role === ROLES.ADMIN;
      if (!statut && !isAdmin) query = query.eq('statut', STATUT_OFFRE.ACTIVE);
    }

    if (statut) query = query.eq('statut', statut);
    if (domaine) query = query.ilike('domaine', `%${domaine}%`);
    if (localisation) query = query.ilike('localisation', `%${localisation}%`);
    if (type_contrat) query = query.eq('type_contrat', type_contrat);

    const { data, error, count } = await query.range(
      parseInt(req.query.offset, 10) || 0,
      (parseInt(req.query.limit, 10) || 20) - 1
    );

    if (error) {
      logError('GET /offres - erreur requête', error);
      return res.status(500).json({ message: 'Erreur lors de la récupération des offres' });
    }

    res.json({ offres: data, total: count ?? data.length });
  } catch (err) {
    logError('GET /offres - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /offres/suggestions - Offres recommandées pour le chercheur connecté (selon son CV)
 * Authentification requise (chercheur)
 */
router.get('/suggestions', authenticate, attachProfileIds, async (req, res) => {
  try {
    if (req.user.role !== ROLES.CHERCHEUR || !req.chercheurId) {
      return res.status(403).json({ message: 'Réservé aux chercheurs d\'emploi' });
    }

    const { data: cvRow } = await supabase
      .from('cv')
      .select('competences_extrait, texte_complet')
      .eq('chercheur_id', req.chercheurId)
      .single();

    const limit = Math.min(parseInt(req.query.limit, 10) || 15, 50);
    const { data: offres, error } = await supabase
      .from('offres_emploi')
      .select(`
        id,
        titre,
        description,
        exigences,
        competences_requises,
        salaire_min,
        salaire_max,
        localisation,
        type_contrat,
        domaine,
        date_publication,
        entreprises(nom_entreprise, secteur_activite)
      `)
      .eq('statut', STATUT_OFFRE.ACTIVE)
      .order('date_publication', { ascending: false })
      .limit(limit * 2);

    if (error) {
      logError('GET /offres/suggestions - erreur requête', error);
      return res.status(500).json({ message: 'Erreur lors de la récupération des suggestions' });
    }

    const { computeMatchingScoreAsync } = await import('../services/matchingScore.js');
    const cv = cvRow ? { competences_extrait: cvRow.competences_extrait, texte_complet: cvRow.texte_complet } : {};
    const scored = await Promise.all(
      (offres || []).map(async (o) => ({
        ...o,
        score_compatibilite: await computeMatchingScoreAsync(cv, { exigences: o.exigences, competences_requises: o.competences_requises }),
      }))
    );
    scored.sort((a, b) => (b.score_compatibilite ?? 0) - (a.score_compatibilite ?? 0));
    const suggestions = scored.slice(0, limit);

    res.json({ suggestions });
  } catch (err) {
    logError('GET /offres/suggestions - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * GET /offres/:id
 * Détail d'une offre (avec infos entreprise). Visible si active ou si on est l'entreprise/admin
 */
router.get('/:id', optionalAuth, attachProfileIds, async (req, res) => {
  try {
    const { id } = req.params;

    const { data: offre, error } = await supabase
      .from('offres_emploi')
      .select(`
        *,
        entreprises(id, nom_entreprise, secteur_activite, description, adresse_siege)
      `)
      .eq('id', id)
      .single();

    if (error || !offre) {
      return res.status(404).json({ message: 'Offre non trouvée' });
    }

    // Si pas active, seuls l'entreprise propriétaire ou l'admin peuvent voir
    if (offre.statut !== STATUT_OFFRE.ACTIVE) {
      const isOwner = req.entrepriseId && offre.entreprise_id === req.entrepriseId;
      const isAdmin = req.user?.role === ROLES.ADMIN;
      if (!isOwner && !isAdmin) {
        return res.status(404).json({ message: 'Offre non trouvée' });
      }
    }

    res.json(offre);
  } catch (err) {
    logError('GET /offres/:id - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

/**
 * POST /offres - Créer une offre (entreprise uniquement)
 */
router.post('/',
  authenticate,
  attachProfileIds,
  requireRole(ROLES.ENTREPRISE),
  async (req, res) => {
    try {
      const entrepriseId = req.entrepriseId;
      if (!entrepriseId) {
        return res.status(400).json({ message: 'Profil entreprise introuvable' });
      }

      const {
        titre,
        description,
        exigences,
        competences_requises,
        salaire_min,
        salaire_max,
        devise,
        localisation,
        type_contrat,
        niveau_experience_requis,
        domaine,
        statut,
        nombre_postes,
        date_limite,
      } = req.body;

      if (!titre || !description || !exigences) {
        return res.status(400).json({
          message: 'Champs requis : titre, description, exigences',
        });
      }

      const titreTrim = String(titre).trim();
      const descriptionTrim = String(description).trim();
      const exigencesTrim = String(exigences).trim();
      if (titreTrim.length > 200) {
        return res.status(400).json({ message: 'Le titre ne doit pas dépasser 200 caractères' });
      }
      if (descriptionTrim.length > 8000) {
        return res.status(400).json({ message: 'La description ne doit pas dépasser 8000 caractères' });
      }
      if (exigencesTrim.length > 4000) {
        return res.status(400).json({ message: 'Les exigences ne doivent pas dépasser 4000 caractères' });
      }

      const payload = {
        entreprise_id: entrepriseId,
        titre: titreTrim,
        description: descriptionTrim,
        exigences: exigencesTrim,
        competences_requises: competences_requises || null,
        salaire_min: salaire_min != null ? Number(salaire_min) : null,
        salaire_max: salaire_max != null ? Number(salaire_max) : null,
        devise: devise || 'GNF',
        localisation: localisation?.trim() || null,
        type_contrat: type_contrat?.trim() || null,
        niveau_experience_requis: niveau_experience_requis?.trim() || null,
        domaine: domaine?.trim() || null,
        statut: statut && Object.values(STATUT_OFFRE).includes(statut) ? statut : STATUT_OFFRE.ACTIVE,
        nombre_postes: nombre_postes != null ? Math.max(1, parseInt(nombre_postes, 10)) : 1,
        date_limite: date_limite || null,
      };

      const { data, error } = await supabase
        .from('offres_emploi')
        .insert(payload)
        .select()
        .single();

      if (error) {
        logError('POST /offres - erreur insertion', error);
        return res.status(500).json({ message: 'Erreur lors de la création de l\'offre' });
      }

      res.status(201).json(data);
    } catch (err) {
      logError('POST /offres - erreur inattendue', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  }
);

/**
 * PATCH /offres/:id - Modifier une offre (entreprise propriétaire ou admin)
 */
router.patch('/:id',
  authenticate,
  attachProfileIds,
  async (req, res) => {
    try {
      const { id } = req.params;
      const { role } = req.user;

      const { data: existing } = await supabase
        .from('offres_emploi')
        .select('entreprise_id')
        .eq('id', id)
        .single();

      if (!existing) {
        return res.status(404).json({ message: 'Offre non trouvée' });
      }

      const isAdmin = role === ROLES.ADMIN;
      const isOwner = role === ROLES.ENTREPRISE && req.entrepriseId && existing.entreprise_id === req.entrepriseId;
      if (!isAdmin && !isOwner) {
        return res.status(403).json({ message: 'Droits insuffisants pour modifier cette offre' });
      }

      const allowed = [
        'titre', 'description', 'exigences', 'competences_requises',
        'salaire_min', 'salaire_max', 'devise', 'localisation', 'type_contrat',
        'niveau_experience_requis', 'domaine', 'statut', 'nombre_postes', 'date_limite',
      ];
      const update = {};
      for (const key of allowed) {
        if (req.body[key] !== undefined) {
          if (key === 'statut' && !Object.values(STATUT_OFFRE).includes(req.body[key])) continue;
          update[key] = req.body[key];
        }
      }

      if (update.titre && String(update.titre).trim().length > 200) {
        return res.status(400).json({ message: 'Le titre ne doit pas dépasser 200 caractères' });
      }
      if (update.description && String(update.description).trim().length > 8000) {
        return res.status(400).json({ message: 'La description ne doit pas dépasser 8000 caractères' });
      }
      if (update.exigences && String(update.exigences).trim().length > 4000) {
        return res.status(400).json({ message: 'Les exigences ne doivent pas dépasser 4000 caractères' });
      }

      if (Object.keys(update).length === 0) {
        return res.status(400).json({ message: 'Aucun champ à mettre à jour' });
      }

      const { data, error } = await supabase
        .from('offres_emploi')
        .update(update)
        .eq('id', id)
        .select()
        .single();

      if (error) {
        logError('PATCH /offres - erreur update', error);
        return res.status(500).json({ message: 'Erreur lors de la mise à jour' });
      }

      res.json(data);
    } catch (err) {
      logError('PATCH /offres/:id - erreur inattendue', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  }
);

/**
 * DELETE /offres/:id - Supprimer une offre (entreprise propriétaire ou admin)
 */
router.delete('/:id',
  authenticate,
  attachProfileIds,
  async (req, res) => {
    try {
      const { id } = req.params;
      const { role } = req.user;

      const { data: existing } = await supabase
        .from('offres_emploi')
        .select('entreprise_id')
        .eq('id', id)
        .single();

      if (!existing) {
        return res.status(404).json({ message: 'Offre non trouvée' });
      }

      const isAdmin = role === ROLES.ADMIN;
      const isOwner = role === ROLES.ENTREPRISE && req.entrepriseId && existing.entreprise_id === req.entrepriseId;
      if (!isAdmin && !isOwner) {
        return res.status(403).json({ message: 'Droits insuffisants pour supprimer cette offre' });
      }

      const { error } = await supabase.from('offres_emploi').delete().eq('id', id);

      if (error) {
        logError('DELETE /offres - erreur suppression', error);
        return res.status(500).json({ message: 'Erreur lors de la suppression' });
      }

      res.status(204).send();
    } catch (err) {
      logError('DELETE /offres/:id - erreur inattendue', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  }
);

export default router;
