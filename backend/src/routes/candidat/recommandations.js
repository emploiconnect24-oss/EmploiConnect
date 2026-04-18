/**
 * GET /candidat/recommandations — offres + score profil + conseils (PRD §6)
 */
import { Router } from 'express';
import { supabase } from '../../config/supabase.js';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { ROLES, STATUT_OFFRE } from '../../config/constants.js';
import { getRapidApiKeys } from '../../config/rapidApi.js';
import { calculerMatchingScore } from '../../services/ia.service.js';
import { loadProfilMatchingPourChercheur } from '../../services/matchingProfil.service.js';
import { analyserCompatibilite } from '../../services/matchingAvance.service.js';

const router = Router();

router.use(authenticate);
router.use(requireRole(ROLES.CHERCHEUR));
router.use(attachProfileIds);

router.get('/offres/:offreId/analyse', async (req, res) => {
  try {
    const { offreId } = req.params;
    if (!req.chercheurId) {
      return res.status(403).json({ success: false, message: 'Profil candidat requis' });
    }
    console.log('[analyse] Candidat:', req.chercheurId, '| Offre:', offreId);
    const resultat = await analyserCompatibilite(req.chercheurId, offreId);
    console.log('[analyse] Resultat brut:', JSON.stringify(resultat?.analyse || null));
    if (!resultat?.analyse) {
      return res.json({
        success: true,
        data: {
          score: null,
          niveau: 'inconnu',
          message_court: 'Analyse temporairement indisponible. Vous pouvez quand meme postuler.',
          points_forts: [],
          points_faibles: [],
          conseils: [],
          recommande_parcours: false,
        },
      });
    }
    const a = resultat.analyse;
    const score = Number.isFinite(Number(a?.score ?? a?.score_matching))
      ? Number(a.score ?? a.score_matching)
      : null;
    const niveau = a?.niveau
      ?? (score == null
        ? 'inconnu'
        : (score >= 80 ? 'excellent' : score >= 60 ? 'bon' : score >= 40 ? 'moyen' : 'faible'));
    const messageCourt = a?.message_court ?? a?.raison ?? 'Analyse effectuee';
    const pointsForts = Array.isArray(a?.points_forts)
      ? a.points_forts
      : (Array.isArray(a?.competences_communes) ? a.competences_communes : []);
    const pointsFaibles = Array.isArray(a?.points_faibles)
      ? a.points_faibles
      : (Array.isArray(a?.competences_manquantes) ? a.competences_manquantes : []);
    const conseils = Array.isArray(a?.conseils)
      ? a.conseils
      : [
        'Completez votre profil pour ameliorer vos chances',
        'Consultez le Parcours Carriere pour developper vos competences',
      ];
    return res.json({
      success: true,
      data: {
        score,
        niveau,
        message_court: messageCourt,
        points_forts: pointsForts,
        points_faibles: pointsFaibles,
        conseils,
        recommande_parcours: a?.recommande_parcours ?? ((score ?? 0) < 60),
      },
    });
  } catch (err) {
    console.error('[analyse] Erreur:', err?.message || err);
    return res.json({
      success: true,
      data: {
        score: null,
        niveau: 'inconnu',
        message_court: 'Analyse indisponible.',
        points_forts: [],
        points_faibles: [],
        conseils: [],
        recommande_parcours: false,
      },
    });
  }
});

function calculerScoreProfilEtConseils(user, chercheur, cv) {
  let score = 0;
  const conseils = [];

  if (user?.photo_url) score += 5;
  else conseils.push('Ajoutez une photo de profil pour rassurer les recruteurs');

  if (chercheur?.titre_poste) score += 15;
  else conseils.push('Renseignez votre titre professionnel');

  if (String(chercheur?.about || '').trim()) score += 15;
  else conseils.push('Complétez votre section « À propos »');

  const comps = Array.isArray(chercheur?.competences) ? chercheur.competences : [];
  const compsCv = Array.isArray(cv?.competences_extrait?.competences)
    ? cv.competences_extrait.competences
    : [];
  if (comps.length > 0 || compsCv.length > 0) score += 20;
  else conseils.push('Ajoutez vos compétences techniques à votre profil ou analysez votre CV');

  const exps = Array.isArray(chercheur?.experiences) ? chercheur.experiences : [];
  const expsCv = Array.isArray(cv?.competences_extrait?.experience)
    ? cv.competences_extrait.experience
    : [];
  if (exps.length > 0 || expsCv.length > 0) score += 15;
  else conseils.push('Ajoutez au moins une expérience professionnelle');

  const fmts = Array.isArray(chercheur?.formations) ? chercheur.formations : [];
  const fmtsCv = Array.isArray(cv?.competences_extrait?.formation)
    ? cv.competences_extrait.formation
    : [];
  if (fmts.length > 0 || fmtsCv.length > 0) score += 10;
  else conseils.push('Indiquez vos formations ou diplômes');

  if (cv?.fichier_url || cv?.nom_fichier) {
    const analyseOk = Boolean(cv?.competences_extrait?.competences?.length)
      || Boolean(cv?.competences_extrait?.source);
    if (analyseOk) score += 20;
    else score += 10;
  } else {
    conseils.push('Uploadez votre CV pour une meilleure analyse IA');
  }

  if (String(chercheur?.disponibilite || '').trim()) score += 5;
  else conseils.push('Indiquez votre disponibilité');

  return {
    score_profil: Math.min(100, Math.max(0, score)),
    conseils: [...new Set(conseils)].slice(0, 6),
  };
}

router.get('/recommandations', async (req, res) => {
  try {
    const chercheurId = req.chercheurId;
    if (!chercheurId) {
      return res.status(403).json({ success: false, message: 'Profil candidat requis' });
    }

    const limite = Math.min(parseInt(req.query.limite || req.query.limit, 10) || 24, 50);
    const keys = await getRapidApiKeys();
    const seuil = Number.isFinite(keys.seuilMatching) ? keys.seuilMatching : 40;

    const { data: user } = await supabase
      .from('utilisateurs')
      .select('photo_url, nom, adresse')
      .eq('id', req.user.id)
      .single();

    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id, competences, experiences, formations, titre_poste, about, disponibilite')
      .eq('id', chercheurId)
      .single();

    const { data: cv } = await supabase
      .from('cv')
      .select('fichier_url, nom_fichier, competences_extrait, date_analyse')
      .eq('chercheur_id', chercheurId)
      .maybeSingle();

    const { score_profil, conseils } = calculerScoreProfilEtConseils(user, chercheur, cv);

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
        en_vedette,
        entreprises(nom_entreprise, secteur_activite, logo_url)
      `)
      .in('statut', [STATUT_OFFRE.ACTIVE, 'publiee'])
      .order('date_publication', { ascending: false })
      .limit(50);

    if (error) {
      console.error('[GET /candidat/recommandations]', error);
      return res.status(500).json({ success: false, message: 'Erreur chargement des offres' });
    }

    const wrap = await loadProfilMatchingPourChercheur(chercheurId);
    const profil = wrap?.profil;

    if (!profil) {
      return res.json({
        success: true,
        data: {
          offres: (offres || []).slice(0, limite).map((o) => ({
            ...o,
            score_compatibilite: null,
            ia_active: false,
          })),
          score_profil,
          conseils,
        },
      });
    }

    const scored = await Promise.all(
      (offres || []).map(async (o) => {
        const raw = await calculerMatchingScore(profil, o);
        const rounded = Number.isFinite(raw) ? Math.round(raw) : 0;
        return {
          ...o,
          score_compatibilite: rounded,
          ia_active: true,
        };
      }),
    );

    const cacheRows = scored
      .filter((o) => o.id)
      .map((o) => ({
        chercheur_id: chercheurId,
        offre_id: o.id,
        score: o.score_compatibilite ?? 0,
        calcule_le: new Date().toISOString(),
      }));
    if (cacheRows.length) {
      await supabase.from('offres_scores_cache').upsert(cacheRows, { onConflict: 'chercheur_id,offre_id' });
    }

    const tri = [...scored].sort((a, b) => (b.score_compatibilite ?? 0) - (a.score_compatibilite ?? 0));
    let suggestions = tri.filter((o) => (o.score_compatibilite ?? 0) >= seuil);
    if (suggestions.length < 3) {
      const comp = tri
        .filter((o) => (o.score_compatibilite ?? 0) < seuil)
        .slice(0, Math.max(0, 5 - suggestions.length));
      suggestions = [...suggestions, ...comp];
    }

    return res.json({
      success: true,
      data: {
        offres: suggestions.slice(0, limite),
        score_profil,
        conseils,
        meta: { seuil_utilise: seuil, total_analyse: scored.length },
      },
    });
  } catch (err) {
    console.error('[GET /candidat/recommandations]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

export default router;
