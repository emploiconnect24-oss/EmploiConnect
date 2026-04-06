import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase } from '../../config/supabase.js';

const router = Router();
router.use(authenticate, requireRecruteur);

function ymd(d) {
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(d.getUTCDate()).padStart(2, '0')}`;
}

function asInt(v) {
  if (v == null) return 0;
  if (typeof v === 'number') return Math.round(v);
  return parseInt(String(v), 10) || 0;
}

function isMissingOffresVues(err) {
  return err?.code === 'PGRST205'
    && typeof err?.message === 'string'
    && err.message.includes("Could not find the table 'public.offres_vues'");
}

router.get('/', async (req, res) => {
  try {
    const { periode = '30d' } = req.query;
    const jours = ({ '7d': 7, '30d': 30, '3m': 90 })[periode] || 30;
    const now = Date.now();
    const dateDebutObj = new Date(now - jours * 24 * 60 * 60 * 1000);
    const dateDebut = dateDebutObj.toISOString();
    const prevDebut = new Date(now - (jours * 2) * 24 * 60 * 60 * 1000).toISOString();

    const { data: offres } = await supabase
      .from('offres_emploi')
      .select('id, titre, statut, nb_vues, date_limite')
      .eq('entreprise_id', req.entreprise.id);

    const ids = (offres || []).map((o) => o.id);
    if (!ids.length) {
      return res.json({
        success: true,
        data: {
          periode,
          kpis: {
            candidatures: { valeur: 0, tendance: 0 },
            vues: { valeur: 0, tendance: 0 },
            taux_reponse: { valeur: 0 },
            score_ia_moyen: { valeur: 0 },
          },
          evolution_par_jour: [],
          performance_par_offre: [],
          repartition_statuts: { en_attente: 0, en_cours: 0, entretien: 0, acceptees: 0, refusees: 0 },
          insights: { meilleures_offres: [], alertes: [] },
        },
      });
    }

    const { data: cands, error: candErr } = await supabase
      .from('candidatures')
      .select('offre_id, statut, score_compatibilite, date_candidature')
      .in('offre_id', ids)
      .gte('date_candidature', prevDebut);
    if (candErr) throw candErr;

    const { data: vuesRows, error: vuesErr } = await supabase
      .from('offres_vues')
      .select('offre_id, date_vue')
      .in('offre_id', ids)
      .gte('date_vue', prevDebut);

    let vueMapByOffre = {};
    let vuesCurrent = 0;
    let vuesPrevious = 0;
    const dayMap = {};

    if (!vuesErr) {
      for (const v of vuesRows || []) {
        vueMapByOffre[v.offre_id] = (vueMapByOffre[v.offre_id] || 0) + 1;
        const key = ymd(new Date(v.date_vue));
        dayMap[key] = dayMap[key] || { candidatures: 0, vues: 0 };
        dayMap[key].vues += 1;
        if (new Date(v.date_vue) >= dateDebutObj) vuesCurrent += 1;
        else vuesPrevious += 1;
      }
    } else if (isMissingOffresVues(vuesErr)) {
      vueMapByOffre = Object.fromEntries((offres || []).map((o) => [o.id, asInt(o.nb_vues)]));
      vuesCurrent = (offres || []).reduce((s, o) => s + asInt(o.nb_vues), 0);
      vuesPrevious = 0;
    } else {
      throw vuesErr;
    }

    const candsAll = cands || [];
    const currentCands = candsAll.filter((c) => new Date(c.date_candidature) >= dateDebutObj);
    const previousCands = candsAll.filter((c) => new Date(c.date_candidature) < dateDebutObj);

    for (const c of currentCands) {
      const key = ymd(new Date(c.date_candidature));
      dayMap[key] = dayMap[key] || { candidatures: 0, vues: 0 };
      dayMap[key].candidatures += 1;
    }

    const traitees = currentCands.filter((c) => ['acceptee', 'refusee', 'entretien'].includes(c.statut));
    const scoreValues = currentCands.map((c) => Number(c.score_compatibilite || 0)).filter((s) => s > 0);
    const scoreMoyen = scoreValues.length ? Math.round(scoreValues.reduce((a, b) => a + b, 0) / scoreValues.length) : 0;

    const candidTendance = previousCands.length
      ? Math.round(((currentCands.length - previousCands.length) / previousCands.length) * 100)
      : (currentCands.length > 0 ? 100 : 0);
    const vuesTendance = vuesPrevious
      ? Math.round(((vuesCurrent - vuesPrevious) / vuesPrevious) * 100)
      : (vuesCurrent > 0 ? 100 : 0);

    const rep = {
      en_attente: currentCands.filter((c) => c.statut === 'en_attente').length,
      en_cours: currentCands.filter((c) => c.statut === 'en_cours').length,
      entretien: currentCands.filter((c) => c.statut === 'entretien').length,
      acceptees: currentCands.filter((c) => c.statut === 'acceptee').length,
      refusees: currentCands.filter((c) => c.statut === 'refusee').length,
    };

    const perf = (offres || []).map((o) => {
      const candsOffre = currentCands.filter((c) => c.offre_id === o.id);
      const nbCands = candsOffre.length;
      const nbVues = asInt(vueMapByOffre[o.id] || 0);
      const tauxConv = nbVues > 0 ? Math.round((nbCands / nbVues) * 100) : 0;
      const avgScoreVals = candsOffre.map((c) => Number(c.score_compatibilite || 0)).filter((s) => s > 0);
      return {
        id: o.id,
        titre: o.titre,
        statut: o.statut,
        nb_vues: nbVues,
        nb_candidatures: nbCands,
        taux_conversion: tauxConv,
        score_ia_moyen: avgScoreVals.length
          ? Math.round(avgScoreVals.reduce((a, b) => a + b, 0) / avgScoreVals.length)
          : 0,
        date_limite: o.date_limite || null,
      };
    }).sort((a, b) => b.nb_candidatures - a.nb_candidatures);

    const evolution = [];
    for (let i = jours - 1; i >= 0; i -= 1) {
      const d = new Date(now - i * 24 * 60 * 60 * 1000);
      const key = ymd(d);
      evolution.push({
        date: key,
        candidatures: dayMap[key]?.candidatures || 0,
        vues: dayMap[key]?.vues || 0,
      });
    }

    const alertes = [];
    const enAttente = rep.en_attente;
    if (enAttente > 0) {
      alertes.push(`${enAttente} candidature(s) en attente de traitement.`);
    }
    const offresBientotExpirees = (offres || [])
      .filter((o) => o.date_limite && new Date(o.date_limite).getTime() - now <= 3 * 24 * 60 * 60 * 1000)
      .length;
    if (offresBientotExpirees > 0) {
      alertes.push(`${offresBientotExpirees} offre(s) arrivent à expiration sous 3 jours.`);
    }

    return res.json({
      success: true,
      data: {
        periode,
        kpis: {
          candidatures: { valeur: currentCands.length, tendance: candidTendance },
          vues: { valeur: vuesCurrent || 0, tendance: vuesTendance },
          taux_reponse: { valeur: currentCands.length ? Math.round((traitees.length / currentCands.length) * 100) : 0 },
          score_ia_moyen: { valeur: scoreMoyen },
        },
        evolution_par_jour: evolution,
        performance_par_offre: perf,
        repartition_statuts: rep,
        insights: {
          meilleures_offres: perf.slice(0, 3),
          alertes,
        },
      },
    });
  } catch (err) {
    console.error('[recruteur/stats]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;

