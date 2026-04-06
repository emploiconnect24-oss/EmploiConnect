import { Router } from 'express';
import { authenticate } from '../../middleware/auth.js';
import { requireRecruteur } from '../../middleware/recruteurAuth.js';
import { supabase } from '../../config/supabase.js';

const router = Router();
router.use(authenticate, requireRecruteur);

router.get('/', async (req, res) => {
  try {
    const entrepriseId = req.entreprise.id;
    const now = new Date();
    const debut30j = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const debut7j = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();

    const { data: offres, error: offresErr } = await supabase
      .from('offres_emploi')
      .select('id, titre, statut, nb_vues, date_publication, date_limite, date_creation, localisation')
      .eq('entreprise_id', entrepriseId)
      .order('date_creation', { ascending: false });

    if (offresErr) {
      console.error('[recruteur/dashboard] offres:', offresErr.message);
      return res.status(500).json({ success: false, message: 'Erreur chargement offres' });
    }

    const toutesOffres = offres || [];
    const offresIds = toutesOffres.map((o) => o.id);
    const offresActives = toutesOffres.filter(
      (o) => o.statut === 'publiee' || o.statut === 'active',
    );
    const offresEnAttente = toutesOffres.filter((o) => o.statut === 'en_attente');

    let toutesCandidatures = [];
    if (offresIds.length > 0) {
      const { data: cands, error: cErr } = await supabase
        .from('candidatures')
        .select(`
          id, statut, score_compatibilite, date_candidature, offre_id,
          chercheur:chercheur_id (
            id,
            utilisateur:utilisateur_id (id, nom, email, photo_url)
          ),
          offre:offre_id (id, titre)
        `)
        .in('offre_id', offresIds)
        .order('date_candidature', { ascending: false })
        .limit(500);
      if (cErr) {
        console.warn('[recruteur/dashboard] candidatures embed:', cErr.message);
        const { data: flat } = await supabase
          .from('candidatures')
          .select('id, statut, score_compatibilite, date_candidature, offre_id')
          .in('offre_id', offresIds)
          .order('date_candidature', { ascending: false })
          .limit(500);
        toutesCandidatures = flat || [];
      } else {
        toutesCandidatures = cands || [];
      }
    }

    const { count: nbMessages } = await supabase
      .from('messages')
      .select('id', { count: 'exact', head: true })
      .eq('destinataire_id', req.user.id)
      .eq('est_lu', false);

    let vuesMois = 0;
    if (offresIds.length > 0) {
      const { count } = await supabase
        .from('offres_vues')
        .select('id', { count: 'exact', head: true })
        .in('offre_id', offresIds)
        .gte('date_vue', debut30j);
      vuesMois = count || 0;
      if (vuesMois === 0) {
        vuesMois = toutesOffres.reduce((sum, o) => sum + (Number(o.nb_vues) || 0), 0);
      }
    }

    const candsEnAttente = toutesCandidatures.filter((c) => c.statut === 'en_attente');
    const candsTraitees = toutesCandidatures.filter((c) =>
      ['acceptee', 'refusee', 'entretien'].includes(c.statut),
    );
    const tauxReponse = toutesCandidatures.length > 0
      ? Math.round((candsTraitees.length / toutesCandidatures.length) * 100)
      : 0;

    const candidaturesUrgentes = candsEnAttente.filter(
      (c) => c.date_candidature && String(c.date_candidature) < debut7j,
    );

    const offresActivesAvecStats = offresActives.slice(0, 5).map((o) => ({
      ...o,
      nb_candidatures: toutesCandidatures.filter((c) => c.offre_id === o.id).length,
      nb_non_lues: toutesCandidatures.filter(
        (c) => c.offre_id === o.id && c.statut === 'en_attente',
      ).length,
    }));

    const evolutionSemaine = [];
    for (let i = 6; i >= 0; i -= 1) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const count = toutesCandidatures.filter(
        (c) => c.date_candidature && String(c.date_candidature).startsWith(dateStr),
      ).length;
      evolutionSemaine.push({
        date: dateStr,
        jour: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'][d.getDay()],
        count,
      });
    }

    const nbAcceptees = toutesCandidatures.filter((c) => c.statut === 'acceptee').length;
    const nbRefusees = toutesCandidatures.filter((c) => c.statut === 'refusee').length;

    const stats = {
      offres_actives: offresActives.length,
      offres_en_attente_valid: offresEnAttente.length,
      total_offres: toutesOffres.length,
      total_candidatures: toutesCandidatures.length,
      candidatures_en_attente: candsEnAttente.length,
      candidatures_acceptees: nbAcceptees,
      candidatures_refusees: nbRefusees,
      vues_ce_mois: vuesMois,
      taux_reponse: tauxReponse,
      messages_non_lus: nbMessages || 0,
    };

    return res.json({
      success: true,
      data: {
        stats,
        offres_actives: offresActivesAvecStats,
        candidatures_recentes: toutesCandidatures.slice(0, 5),
        candidatures_urgentes: candidaturesUrgentes.slice(0, 3),
        evolution_semaine: evolutionSemaine,
        entreprise: {
          id: req.entreprise.id,
          nom: req.entreprise.nom_entreprise,
          logo: req.entreprise.logo_url,
        },
      },
    });
  } catch (err) {
    console.error('[recruteur/dashboard]', err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

export default router;
