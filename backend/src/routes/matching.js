import { Router } from 'express';
import { supabase } from '../config/supabase.js';
import { authenticate } from '../middleware/auth.js';
import { attachProfileIds } from '../helpers/userProfile.js';
import { ROLES } from '../config/constants.js';
import { calculerMatchingScore } from '../services/ia.service.js';
import { loadProfilMatchingPourChercheur } from '../services/matchingProfil.service.js';

const router = Router();

function buildScoreDetail(score) {
  if (score >= 80) {
    return {
      label: 'Excellent match',
      couleur: '#10B981',
      description: 'Votre profil correspond tres bien a cette offre',
    };
  }
  if (score >= 60) {
    return {
      label: 'Bon match',
      couleur: '#1A56DB',
      description: 'Votre profil correspond bien a cette offre',
    };
  }
  if (score >= 40) {
    return {
      label: 'Match moyen',
      couleur: '#F59E0B',
      description: 'Votre profil correspond partiellement a cette offre',
    };
  }
  return {
    label: 'Faible match',
    couleur: '#EF4444',
    description: 'Votre profil ne correspond pas bien a cette offre',
  };
}

router.use(authenticate);
router.use(attachProfileIds);

router.post('/score', async (req, res) => {
  try {
    if (req.user?.role !== ROLES.CHERCHEUR || !req.chercheurId) {
      return res.status(403).json({ success: false, message: 'Reserve aux candidats' });
    }

    const { offre_id: offreId } = req.body || {};
    if (!offreId) {
      return res.status(400).json({ success: false, message: 'offre_id requis' });
    }

    const profileData = await loadProfilMatchingPourChercheur(req.chercheurId);
    if (!profileData) {
      return res.json({ success: true, data: { score: 0, message: 'Profil candidat incomplet' } });
    }

    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('id, titre, description, exigences, competences_requises, localisation, niveau_experience_requis, domaine')
      .eq('id', offreId)
      .single();

    if (!offre) {
      return res.status(404).json({ success: false, message: 'Offre non trouvee' });
    }

    const score = await calculerMatchingScore(profileData.profil, offre);
    const rounded = Number.isFinite(score) ? Math.round(score) : 0;
    await supabase.from('offres_scores_cache').upsert({
      chercheur_id: profileData.chercheurId,
      offre_id: offreId,
      score: rounded,
      calcule_le: new Date().toISOString(),
    }, { onConflict: 'chercheur_id,offre_id' });

    await supabase
      .from('candidatures')
      .update({ score_compatibilite: score })
      .eq('chercheur_id', profileData.chercheurId)
      .eq('offre_id', offreId);

    const detail = buildScoreDetail(score);
    return res.json({
      success: true,
      data: {
        score,
        label: detail.label,
        couleur: detail.couleur,
        description: detail.description,
        offre_id: offreId,
      },
    });
  } catch (err) {
    console.error('[POST /matching/score]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.get('/scores-offres', async (req, res) => {
  try {
    if (req.user?.role !== ROLES.CHERCHEUR || !req.chercheurId) {
      return res.status(403).json({ success: false, message: 'Reserve aux candidats' });
    }

    const rawIds = String(req.query.offre_ids || '');
    if (!rawIds) return res.json({ success: true, data: {} });
    const ids = rawIds.split(',').map((x) => x.trim()).filter(Boolean).slice(0, 30);
    if (!ids.length) return res.json({ success: true, data: {} });

    const { data: cached } = await supabase
      .from('offres_scores_cache')
      .select('offre_id, score')
      .eq('chercheur_id', req.chercheurId)
      .in('offre_id', ids);

    const scoreByOffre = {};
    for (const row of cached || []) scoreByOffre[row.offre_id] = row.score;

    const missing = ids.filter((id) => scoreByOffre[id] === undefined);
    const profileData = await loadProfilMatchingPourChercheur(req.chercheurId);

    if (missing.length && profileData) {
      const { data: offres } = await supabase
        .from('offres_emploi')
        .select('id, titre, description, exigences, competences_requises, localisation, niveau_experience_requis, domaine')
        .in('id', missing);

      for (const offre of offres || []) {
        const score = await calculerMatchingScore(profileData.profil, offre);
        const rounded = Number.isFinite(score) ? Math.round(score) : 0;
        await supabase.from('offres_scores_cache').upsert({
          chercheur_id: req.chercheurId,
          offre_id: offre.id,
          score: rounded,
          calcule_le: new Date().toISOString(),
        }, { onConflict: 'chercheur_id,offre_id' });
        scoreByOffre[offre.id] = rounded;
      }
    }

    const scores = {};
    for (const id of ids) {
      if (scoreByOffre[id] !== undefined) {
        const s = scoreByOffre[id];
        scores[id] = { score: s, ...buildScoreDetail(s) };
      }
    }

    return res.json({ success: true, data: scores });
  } catch (err) {
    console.error('[GET /matching/scores-offres]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;

