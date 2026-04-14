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
import { notifNouvelleOffre } from '../services/auto_notification.service.js';
import { calculerMatchingScore, extraireMotsCles } from '../services/ia.service.js';
import { getRapidApiKeys } from '../config/rapidApi.js';
import { loadProfilMatchingPourChercheur } from '../services/matchingProfil.service.js';

const router = Router();

function mapOffreListeRow(o) {
  if (!o || typeof o !== 'object') return o;
  const ent = o.entreprise ?? o.entreprises ?? null;
  const rel = o.candidatures;
  let nb = 0;
  if (Array.isArray(rel) && rel.length && rel[0]?.count != null) {
    nb = Number(rel[0].count) || 0;
  }
  const {
    entreprises: _e,
    candidatures: _c,
    ...rest
  } = o;
  return {
    ...rest,
    entreprise: ent,
    nb_candidatures: nb,
    date_expiration: rest.date_limite ?? null,
    niveau_experience: rest.niveau_experience_requis ?? null,
  };
}

/**
 * GET /offres
 * Liste des offres. Par défaut : statut=active. Filtres : statut, domaine, localisation, type_contrat, ville, niveau, categorie
 * Pagination : ?page=&limit= ou ?offset=&limit=
 * Si authentifié en tant qu'entreprise et ?mes=1 : uniquement les offres de mon entreprise
 */
router.get('/', optionalAuth, attachProfileIds, async (req, res) => {
  try {
    const {
      statut,
      domaine,
      localisation,
      ville,
      type_contrat,
      mes,
      recherche,
      q,
      entreprise_id,
      niveau,
      categorie,
    } = req.query;
    const searchText = String(recherche || q || '').trim();

    const limitRaw = parseInt(req.query.limit, 10);
    const pageRaw = parseInt(req.query.page, 10);
    const offsetRaw = parseInt(req.query.offset, 10);
    const limit = Number.isFinite(limitRaw) && limitRaw > 0 ? Math.min(limitRaw, 100) : 20;
    const hasPage = Number.isFinite(pageRaw) && pageRaw > 0;
    const from = hasPage
      ? (pageRaw - 1) * limit
      : (Number.isFinite(offsetRaw) && offsetRaw >= 0 ? offsetRaw : 0);
    const to = from + limit - 1;
    const currentPage = hasPage ? pageRaw : Math.floor(from / limit) + 1;

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
        competences_requises,
        entreprise:entreprises (
          id,
          nom_entreprise,
          logo_url,
          secteur_activite,
          adresse_siege
        ),
        candidatures ( count )
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
      if (!statut && !isAdmin) query = query.in('statut', [STATUT_OFFRE.ACTIVE, 'publiee']);
    }

    if (statut) query = query.eq('statut', statut);
    if (domaine) query = query.ilike('domaine', `%${domaine}%`);
    const lieuFiltre = String(ville || localisation || '').trim();
    if (lieuFiltre) {
      const safe = lieuFiltre.replace(/[%_,()]/g, ' ').trim().slice(0, 120);
      if (safe.length) query = query.ilike('localisation', `%${safe}%`);
    }
    if (type_contrat) query = query.eq('type_contrat', type_contrat);
    const niv = String(niveau || '').trim();
    if (niv) query = query.eq('niveau_experience_requis', niv);
    const cat = String(categorie || '').trim();
    if (cat) {
      const safe = cat.replace(/[%_,()]/g, ' ').trim().slice(0, 100);
      if (safe.length) query = query.ilike('domaine', `%${safe}%`);
    }
    const eid = String(entreprise_id || '').trim();
    if (eid) query = query.eq('entreprise_id', eid);
    if (searchText) {
      const safe = searchText.replace(/[%_,()]/g, ' ').trim().slice(0, 120);
      if (safe.length) {
        const pattern = `%${safe}%`;
        query = query.or(`titre.ilike.${pattern},description.ilike.${pattern},exigences.ilike.${pattern}`);
      }
    }

    const { data, error, count } = await query.range(from, to);

    if (error) {
      logError('GET /offres - erreur requête', error);
      return res.status(500).json({ message: 'Erreur lors de la récupération des offres' });
    }

    const rowsMapped = (data || []).map(mapOffreListeRow);

    let scoresMap = {};
    if (req.user?.role === ROLES.CHERCHEUR && req.chercheurId && rowsMapped.length) {
      const offreIds = rowsMapped.map((o) => o.id).filter(Boolean);
      try {
        const { data: cached } = await supabase
          .from('offres_scores_cache')
          .select('offre_id, score')
          .eq('chercheur_id', req.chercheurId)
          .in('offre_id', offreIds);
        for (const row of cached || []) scoresMap[row.offre_id] = row.score;

        const missingIds = offreIds.filter((id) => scoresMap[id] === undefined);
        if (missingIds.length) {
          setImmediate(async () => {
            try {
              const wrap = await loadProfilMatchingPourChercheur(req.chercheurId);
              if (!wrap) return;
              const { profil } = wrap;
              const toScore = rowsMapped.filter((o) => missingIds.includes(o.id)).slice(0, 12);
              for (const offre of toScore) {
                const score = await calculerMatchingScore(profil, offre);
                await supabase.from('offres_scores_cache').upsert({
                  chercheur_id: req.chercheurId,
                  offre_id: offre.id,
                  score: Number.isFinite(score) ? Math.round(score) : 0,
                  calcule_le: new Date().toISOString(),
                }, { onConflict: 'chercheur_id,offre_id' });
              }
            } catch (e) {
              console.warn('[offres scores cache bg]', e?.message || e);
            }
          });
        }
      } catch (scoreErr) {
        console.warn('[offres scores cache]', scoreErr?.message || scoreErr);
      }
    }

    const offresAvecScore = rowsMapped.map((o) => ({
      ...o,
      score_compatibilite: scoresMap[o.id] ?? o.score_compatibilite ?? null,
    }));

    const total = count ?? offresAvecScore.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));

    res.json({
      success: true,
      data: {
        offres: offresAvecScore,
        total,
        page: currentPage,
        limit,
        total_pages: totalPages,
      },
    });
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

    const limite = Math.min(parseInt(req.query.limite || req.query.limit, 10) || 10, 50);
    const keys = await getRapidApiKeys();
    const seuil = Number.isFinite(keys.seuilMatching) ? keys.seuilMatching : 40;

    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('id', req.chercheurId)
      .maybeSingle();

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
        niveau_experience_requis,
        date_publication,
        entreprises(nom_entreprise, secteur_activite, logo_url)
      `)
      .in('statut', [STATUT_OFFRE.ACTIVE, 'publiee'])
      .order('date_publication', { ascending: false })
      .limit(50);

    if (error) {
      logError('GET /offres/suggestions - erreur requête', error);
      return res.status(500).json({ message: 'Erreur lors de la récupération des suggestions' });
    }

    if (!chercheur) {
      return res.json({
        success: true,
        data: (offres || []).slice(0, limite).map((o) => ({
          ...o,
          score_compatibilite: null,
          ia_active: false,
        })),
      });
    }

    const wrap = await loadProfilMatchingPourChercheur(req.chercheurId);
    const profil = wrap?.profil;
    if (!profil) {
      return res.json({
        success: true,
        data: (offres || []).slice(0, limite).map((o) => ({
          ...o,
          score_compatibilite: null,
          ia_active: false,
        })),
      });
    }

    const scored = await Promise.all(
      (offres || []).map(async (o) => ({
        ...o,
        score_compatibilite: await calculerMatchingScore(profil, o),
        ia_active: true,
      }))
    );

    const cacheRows = scored
      .filter((o) => o.id)
      .map((o) => ({
        chercheur_id: req.chercheurId,
        offre_id: o.id,
        score: Number.isFinite(o.score_compatibilite) ? Math.round(o.score_compatibilite) : 0,
        calcule_le: new Date().toISOString(),
      }));
    if (cacheRows.length) {
      await supabase.from('offres_scores_cache').upsert(cacheRows, { onConflict: 'chercheur_id,offre_id' });
    }

    const suggestions = scored
      .filter((o) => (o.score_compatibilite ?? 0) >= seuil)
      .sort((a, b) => (b.score_compatibilite ?? 0) - (a.score_compatibilite ?? 0));

    if (suggestions.length < 3) {
      const comp = scored
        .filter((o) => (o.score_compatibilite ?? 0) < seuil)
        .sort((a, b) => (b.score_compatibilite ?? 0) - (a.score_compatibilite ?? 0))
        .slice(0, 5);
      suggestions.push(...comp);
    }

    return res.json({
      success: true,
      data: suggestions.slice(0, limite),
      meta: {
        seuil_utilise: seuil,
        total_analyse: scored.length,
        total_suggestions: Math.min(suggestions.length, limite),
      },
    });
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
        entreprises(
          id, nom_entreprise, secteur_activite, description, adresse_siege,
          logo_url, banniere_url, site_web, slogan, mission,
          email_public, telephone_public, linkedin, facebook
        )
      `)
      .eq('id', id)
      .single();

    if (error || !offre) {
      return res.status(404).json({ message: 'Offre non trouvée' });
    }

    // Si pas active, seuls l'entreprise propriétaire ou l'admin peuvent voir
    if (offre.statut !== STATUT_OFFRE.ACTIVE && offre.statut !== 'publiee') {
      const isOwner = req.entrepriseId && offre.entreprise_id === req.entrepriseId;
      const isAdmin = req.user?.role === ROLES.ADMIN;
      if (!isOwner && !isAdmin) {
        return res.status(404).json({ message: 'Offre non trouvée' });
      }
    }

    setImmediate(async () => {
      try {
        const userId = req.user?.id || null;
        const fwd = req.headers['x-forwarded-for'];
        const rawIp = (typeof fwd === 'string' ? fwd.split(',')[0] : null)
          || req.socket?.remoteAddress
          || req.ip
          || 'unknown';
        const ipAddress = String(rawIp).trim() || 'unknown';
        const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
        let q = supabase
          .from('offres_vues')
          .select('id')
          .eq('offre_id', id)
          .gte('date_vue', since)
          .limit(1);
        if (userId) q = q.eq('user_id', userId);
        else q = q.eq('ip_address', ipAddress);
        const { data: seen } = await q;
        if (!seen || !seen.length) {
          await supabase.from('offres_vues').insert({
            offre_id: id,
            user_id: userId,
            ip_address: ipAddress,
            date_vue: new Date().toISOString(),
          });
          const { error: rpcErr } = await supabase.rpc('increment_vues', { offre_uuid: id });
          if (rpcErr) {
            await supabase.rpc('increment_offre_vues', { offre_id_input: id }).catch(async () => {
              const current = Number(offre.nb_vues || 0) + 1;
              await supabase.from('offres_emploi').update({ nb_vues: current }).eq('id', id);
            });
          }
        }
      } catch (e) {
        console.warn('[vues] Erreur non bloquante:', e?.message || e);
      }
    });

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

      // Limite d'offres actives (plan gratuit) — paramètre max_offres_gratuit
      const { data: paramLimite } = await supabase
        .from('parametres_plateforme')
        .select('valeur')
        .eq('cle', 'max_offres_gratuit')
        .maybeSingle();

      const limite = parseInt(paramLimite?.valeur || '5', 10);

      const { count: nbActives } = await supabase
        .from('offres_emploi')
        .select('id', { count: 'exact', head: true })
        .eq('entreprise_id', entrepriseId)
        .in('statut', [STATUT_OFFRE.ACTIVE, 'publiee']);

      if ((nbActives ?? 0) >= limite) {
        return res.status(403).json({
          success: false,
          message: `Limite atteinte. Votre plan gratuit permet ${limite} offres actives simultanément.`,
        });
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

      // Appliquer automatiquement date_limite si offre publiée (statut active) et pas de date_limite fournie
      if (payload.statut === STATUT_OFFRE.ACTIVE && !payload.date_limite) {
        const { data: p } = await supabase
          .from('parametres_plateforme')
          .select('valeur')
          .eq('cle', 'duree_validite_offre_jours')
          .maybeSingle();
        const nbJours = parseInt(p?.valeur || '30', 10);
        const dt = new Date();
        dt.setDate(dt.getDate() + nbJours);
        payload.date_limite = dt.toISOString().split('T')[0];
      }

      const { data, error } = await supabase
        .from('offres_emploi')
        .insert(payload)
        .select()
        .single();

      if (error) {
        logError('POST /offres - erreur insertion', error);
        return res.status(500).json({ message: 'Erreur lors de la création de l\'offre' });
      }

      const { data: entRow } = await supabase
        .from('entreprises')
        .select('nom_entreprise')
        .eq('id', entrepriseId)
        .single();
      void notifNouvelleOffre(data, entRow?.nom_entreprise);

      setImmediate(async () => {
        try {
          const texteOffre = [data.titre, data.description, data.exigences]
            .filter(Boolean)
            .join(' ');
          if (texteOffre.length < 20) return;

          const motsCles = await extraireMotsCles(texteOffre);
          if (!Array.isArray(motsCles) || motsCles.length === 0) return;

          const competencesExistantes = Array.isArray(data.competences_requises)
            ? data.competences_requises
            : Object.values(data.competences_requises || {});
          const competencesEnrichies = [...new Set([...competencesExistantes, ...motsCles])].slice(0, 20);

          await supabase
            .from('offres_emploi')
            .update({ competences_requises: competencesEnrichies })
            .eq('id', data.id);
          console.log('[IA/offre] Mots-clés ajoutés à l\'offre:', motsCles.join(', '));
        } catch (e) {
          console.warn('[IA/offre] Enrichissement échoué (non bloquant):', e.message);
        }
      });

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
