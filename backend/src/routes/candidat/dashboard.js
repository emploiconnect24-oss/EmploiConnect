import { Router } from 'express';
import { supabase } from '../../config/supabase.js';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { ROLES, STATUT_OFFRE } from '../../config/constants.js';
import { calculerCompletionProfil } from '../../services/profilCompletion.service.js';
import { fetchCitationExterne } from '../../services/citationsExternal.service.js';

const router = Router();
router.use(authenticate, requireRole(ROLES.CHERCHEUR), attachProfileIds);

function isMissingTableError(error) {
  return error?.code === 'PGRST205'
    || (typeof error?.message === 'string' && error.message.includes('Could not find the table'));
}

async function safeCount(queryBuilder) {
  const { count, error } = await queryBuilder;
  if (error) {
    if (isMissingTableError(error)) return 0;
    throw error;
  }
  return count || 0;
}

const EMPTY_MENU_BADGES = {
  candidatures: 0,
  sauvegardes: 0,
  recommandations: 0,
  alertes: 0,
  messages: 0,
  notifications: 0,
};

const CITATIONS_TABLEAU_BORD_DEFAUT = [
  'Le succès appartient à ceux qui commencent.',
  'Chaque candidature est un pas vers votre réussite.',
  'Votre prochaine opportunité est à portée de main.',
  'Les grandes choses commencent par une petite action.',
];

const CITATIONS_PROFIL_FAIBLE = [
  'Complétez votre profil et votre CV : les recruteurs vous repèrent plus vite.',
  'Un profil à jour améliore vos scores de correspondance avec les offres.',
  'Quelques minutes pour renseigner vos compétences peuvent tout changer.',
];

function dayOfYear(d = new Date()) {
  const start = new Date(d.getFullYear(), 0, 0);
  return Math.floor((d - start) / 86400000);
}

function hashSeed(str, n) {
  let h = n;
  const s = String(str || '');
  for (let i = 0; i < s.length; i += 1) {
    h = ((h << 5) - h) + s.charCodeAt(i);
    h |= 0;
  }
  return Math.abs(h);
}

const CITATIONS_PARAM_KEYS = [
  'citations_tableau_bord_candidat',
  'citations_api_active',
  'citations_api_source',
  'citations_api_url_custom',
];

async function citationMotivationPourCandidat(userId, chercheurId, pourcentageProfil) {
  const { data: rows } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .in('cle', CITATIONS_PARAM_KEYS);
  const map = Object.fromEntries((rows || []).map((r) => [r.cle, r.valeur]));

  const apiActive = String(map.citations_api_active ?? '').toLowerCase() === 'true';
  const apiSource = String(map.citations_api_source ?? 'zenquotes').toLowerCase().trim();
  const customUrl = String(map.citations_api_url_custom ?? '').trim();

  if (apiActive && apiSource !== 'off') {
    const externe = await fetchCitationExterne(apiSource, customUrl);
    if (externe) return externe;
  }

  let pool = [...CITATIONS_TABLEAU_BORD_DEFAUT];
  const raw = String(map.citations_tableau_bord_candidat ?? '').trim();
  if (raw) {
    const lines = raw.split(/\r?\n/).map((t) => t.trim()).filter(Boolean);
    if (lines.length) pool = lines;
  }
  const pct = Number(pourcentageProfil);
  if (!Number.isFinite(pct) || pct < 45) {
    pool = [...CITATIONS_PROFIL_FAIBLE, ...pool];
  }
  const seed = hashSeed(chercheurId || userId, dayOfYear());
  const idx = pool.length ? seed % pool.length : 0;
  return pool[idx] || CITATIONS_TABLEAU_BORD_DEFAUT[0];
}

/** Données métriques sidebar + KPIs (GET / et GET /metrics) */
async function buildCandidatMetricsData(req) {
  const userId = req.user.id;
  const chercheurId = req.chercheurId;

  const { data: userFull, error: userErr } = await supabase
    .from('utilisateurs')
    .select('nom, email, telephone, adresse, photo_url')
    .eq('id', userId)
    .maybeSingle();
  if (userErr && !isMissingTableError(userErr)) throw userErr;
  const userRow = userFull || {};

  if (!chercheurId) {
    const completion = calculerCompletionProfil(userRow, {}, null);
    return {
      profile: {
        nom: userRow.nom || '',
        photo_url: userRow.photo_url || '',
        titre_professionnel: '',
      },
      menu_badges: { ...EMPTY_MENU_BADGES },
      kpis: {
        candidatures_total: 0,
        candidatures_en_cours: 0,
        entretiens: 0,
        candidatures_terminees: 0,
        vues_profil: 0,
        profile_completion: completion.pourcentage,
        completion_details: completion,
      },
      cvRow: null,
      _notificationsNonLues: 0,
    };
  }

  const [
    candidaturesTotal,
    candidaturesEnCours,
    candidaturesEntretien,
    candidaturesTerminees,
    notificationsNonLues,
    messagesNonLus,
    alertesEmploi,
    offresSauvegardees,
    recommandationsTotal,
    vuesProfilMois,
    chercheurRow,
    hasCv,
  ] = await Promise.all([
    safeCount(
      supabase.from('candidatures').select('id', { count: 'exact', head: true }).eq('chercheur_id', chercheurId),
    ),
    safeCount(
      supabase.from('candidatures').select('id', { count: 'exact', head: true })
        .eq('chercheur_id', chercheurId)
        .in('statut', ['en_attente', 'en_cours']),
    ),
    safeCount(
      supabase.from('candidatures').select('id', { count: 'exact', head: true })
        .eq('chercheur_id', chercheurId)
        .eq('statut', 'entretien'),
    ),
    safeCount(
      supabase.from('candidatures').select('id', { count: 'exact', head: true })
        .eq('chercheur_id', chercheurId)
        .in('statut', ['acceptee', 'refusee', 'annulee']),
    ),
    safeCount(
      supabase.from('notifications').select('id', { count: 'exact', head: true })
        .eq('destinataire_id', userId)
        .eq('est_lue', false),
    ),
    safeCount(
      supabase.from('notifications').select('id', { count: 'exact', head: true })
        .eq('destinataire_id', userId)
        .eq('est_lue', false)
        .eq('type', 'message'),
    ),
    safeCount(
      supabase.from('alertes_emploi').select('id', { count: 'exact', head: true })
        .eq('chercheur_id', chercheurId)
        .eq('est_active', true),
    ),
    safeCount(
      supabase.from('offres_sauvegardees').select('id', { count: 'exact', head: true }).eq('chercheur_id', chercheurId),
    ),
    safeCount(
      supabase.from('offres_emploi').select('id', { count: 'exact', head: true })
        .in('statut', [STATUT_OFFRE.ACTIVE, 'publiee']),
    ),
    safeCount(
      supabase.from('notifications').select('id', { count: 'exact', head: true })
        .eq('destinataire_id', userId)
        .eq('type', 'profile_view')
        .gte('date_creation', new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString()),
    ),
    supabase.from('chercheurs_emploi').select('competences, niveau_etude, disponibilite, titre_poste, about').eq('id', chercheurId).maybeSingle()
      .then(({ data, error }) => {
        if (error && !isMissingTableError(error)) throw error;
        return data || {};
      }),
    safeCount(
      supabase.from('cv').select('id', { count: 'exact', head: true }).eq('chercheur_id', chercheurId),
    ),
  ]);

  let cvRow = null;
  if ((hasCv || 0) > 0) {
    const { data } = await supabase
      .from('cv')
      .select('fichier_url, nom_fichier, competences_extrait, date_analyse')
      .eq('chercheur_id', chercheurId)
      .maybeSingle();
    cvRow = data || null;
  }
  const completion = calculerCompletionProfil(userRow || {}, chercheurRow || {}, cvRow);
  const profileCompletion = completion.pourcentage;

  return {
    profile: {
      nom: userRow?.nom || '',
      photo_url: userRow?.photo_url || '',
      titre_professionnel: String(chercheurRow?.titre_poste || chercheurRow?.niveau_etude || '').trim(),
    },
    menu_badges: {
      candidatures: candidaturesTotal,
      sauvegardes: offresSauvegardees,
      recommandations: recommandationsTotal,
      alertes: alertesEmploi,
      messages: messagesNonLus,
      notifications: notificationsNonLues,
    },
    kpis: {
      candidatures_total: candidaturesTotal,
      candidatures_en_cours: candidaturesEnCours,
      entretiens: candidaturesEntretien,
      candidatures_terminees: candidaturesTerminees,
      vues_profil: vuesProfilMois,
      profile_completion: profileCompletion,
      completion_details: completion,
    },
    cvRow,
    _notificationsNonLues: notificationsNonLues,
  };
}

function statutLabel(statut) {
  const s = String(statut || '').toLowerCase();
  if (s.includes('refus')) return 'Refusée';
  if (s.includes('accep')) return 'Acceptée';
  if (s.includes('entretien')) return 'Entretien';
  if (s.includes('cours') || s.includes('examen')) return 'En examen';
  if (s.includes('annul')) return 'Annulée';
  if (s === 'en_attente') return 'En attente';
  return 'Envoyée';
}

/** GET /api/candidat/dashboard — Vue d’ensemble (PRD ÉTAPE 3) */
router.get('/', async (req, res) => {
  try {
    const metrics = await buildCandidatMetricsData(req);
    const {
      profile, menu_badges: menuBadges, kpis, cvRow, _notificationsNonLues,
    } = metrics;
    const chercheurId = req.chercheurId;

    if (!chercheurId) {
      const citationMotivation = await citationMotivationPourCandidat(
        req.user.id,
        null,
        kpis.profile_completion,
      );
      return res.json({
        success: true,
        data: {
          candidat: {
            nom: profile.nom || '',
            photo: profile.photo_url || null,
            titre: '',
            dispo: '',
          },
          completion_profil: {
            pourcentage: kpis.profile_completion,
            manquants: kpis.completion_details?.manquants || [],
          },
          stats: {
            total_candidatures: 0,
            en_attente: 0,
            en_cours: 0,
            acceptees: 0,
            entretiens: 0,
            refusees: 0,
          },
          candidatures_recentes: [],
          offres_recommandees: [],
          nb_notifications: _notificationsNonLues ?? 0,
          cv_analyse: false,
          nouvelles_offres_alerte: 0,
          citation_motivation: citationMotivation,
          profile,
          menu_badges: menuBadges,
          kpis,
        },
      });
    }

    const [
      { data: recentCands, error: errRecent },
      { data: tousStatuts, error: errStatuts },
      { data: offresBrutes, error: errOffres },
    ] = await Promise.all([
      supabase
        .from('candidatures')
        .select(`
          id, statut, date_candidature,
          offre:offre_id (
            id, titre,
            entreprise:entreprise_id ( nom_entreprise, logo_url )
          )
        `)
        .eq('chercheur_id', chercheurId)
        .order('date_candidature', { ascending: false })
        .limit(5),
      supabase.from('candidatures').select('statut').eq('chercheur_id', chercheurId),
      supabase
        .from('offres_emploi')
        .select(`
          id, titre, localisation, type_contrat, salaire_min, salaire_max, devise, en_vedette,
          entreprises ( nom_entreprise, logo_url )
        `)
        .in('statut', [STATUT_OFFRE.ACTIVE, 'publiee'])
        .order('date_publication', { ascending: false })
        .limit(6),
    ]);

    if (errRecent && !isMissingTableError(errRecent)) throw errRecent;
    if (errStatuts && !isMissingTableError(errStatuts)) throw errStatuts;
    if (errOffres && !isMissingTableError(errOffres)) throw errOffres;

    const all = tousStatuts || [];
    const stats = {
      total_candidatures: all.length,
      en_attente: all.filter((c) => c.statut === 'en_attente').length,
      en_cours: all.filter((c) => c.statut === 'en_cours').length,
      acceptees: all.filter((c) => c.statut === 'acceptee').length,
      entretiens: all.filter((c) => c.statut === 'entretien').length,
      refusees: all.filter((c) => c.statut === 'refusee').length,
    };

    const { data: chercheurLite } = await supabase
      .from('chercheurs_emploi')
      .select('titre_poste, disponibilite')
      .eq('id', chercheurId)
      .maybeSingle();

    const offreIds = (offresBrutes || []).map((o) => o.id).filter(Boolean);
    const scoresMap = {};
    if (offreIds.length) {
      const { data: cached } = await supabase
        .from('offres_scores_cache')
        .select('offre_id, score')
        .eq('chercheur_id', chercheurId)
        .in('offre_id', offreIds);
      for (const row of cached || []) scoresMap[row.offre_id] = row.score;
    }

    const offres_recommandees = (offresBrutes || []).map((o) => ({
      ...o,
      score_compatibilite: scoresMap[o.id] ?? null,
      _score: scoresMap[o.id] ?? 0,
    }));

    const candidatures_recentes = (recentCands || []).map((row) => {
      const offre = row.offre;
      const titre = offre?.titre || 'Offre';
      const ent = offre?.entreprise;
      const company = ent?.nom_entreprise || 'Entreprise';
      const logoUrl = ent?.logo_url || null;
      return {
        id: row.id,
        statut: row.statut,
        statut_label: statutLabel(row.statut),
        date_candidature: row.date_candidature,
        offre: { titre, entreprise: { nom_entreprise: company, logo_url: logoUrl } },
      };
    });

    const citationMotivation = await citationMotivationPourCandidat(
      req.user.id,
      chercheurId,
      kpis.profile_completion,
    );

    return res.json({
      success: true,
      data: {
        candidat: {
          nom: profile.nom || '',
          photo: profile.photo_url || null,
          titre: String(chercheurLite?.titre_poste || '').trim(),
          dispo: String(chercheurLite?.disponibilite || '').trim(),
        },
        completion_profil: {
          pourcentage: kpis.profile_completion,
          manquants: kpis.completion_details?.manquants || [],
        },
        stats,
        candidatures_recentes,
        offres_recommandees,
        nb_notifications: _notificationsNonLues ?? 0,
        cv_analyse: !!cvRow?.date_analyse,
        nouvelles_offres_alerte: menuBadges.alertes || 0,
        citation_motivation: citationMotivation,
        profile,
        menu_badges: menuBadges,
        kpis,
      },
    });
  } catch (err) {
    console.error('[candidat/dashboard GET /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.get('/metrics', async (req, res) => {
  try {
    const m = await buildCandidatMetricsData(req);
    return res.json({
      success: true,
      data: {
        profile: m.profile,
        menu_badges: m.menu_badges,
        kpis: m.kpis,
      },
    });
  } catch (err) {
    console.error('[candidat/dashboard/metrics]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
