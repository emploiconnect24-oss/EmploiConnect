/**
 * Témoignage après recrutement (candidat authentifié).
 */
import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { supabase } from '../../config/supabase.js';
import { ROLES } from '../../config/constants.js';

const router = Router();
router.use(authenticate, requireRole(ROLES.CHERCHEUR), attachProfileIds);

/** Candidatures acceptées sans témoignage encore déposé. */
router.get('/eligible', async (req, res) => {
  try {
    if (!req.chercheurId) {
      return res.json({ success: true, data: { items: [] } });
    }

    const { data: cands, error: e1 } = await supabase
      .from('candidatures')
      .select(
        `
        id,
        offre_id,
        offres_emploi ( titre, entreprise_id, entreprises ( id, nom_entreprise ) )
      `,
      )
      .eq('chercheur_id', req.chercheurId)
      .eq('statut', 'acceptee');

    if (e1) throw e1;

    const { data: existing, error: e2 } = await supabase
      .from('temoignages_recrutement')
      .select('candidature_id')
      .eq('utilisateur_id', req.user.id);

    if (e2) throw e2;
    const done = new Set((existing || []).map((x) => x.candidature_id));

    const items = [];
    for (const c of cands || []) {
      if (done.has(c.id)) continue;
      const off = c.offres_emploi;
      const oRow = Array.isArray(off) ? off[0] : off;
      const ent = oRow?.entreprises;
      const eRow = Array.isArray(ent) ? ent[0] : ent;
      items.push({
        candidature_id: c.id,
        offre_titre: oRow?.titre || '',
        entreprise_id: eRow?.id || oRow?.entreprise_id || null,
        entreprise_nom: eRow?.nom_entreprise || '',
      });
    }

    return res.json({ success: true, data: { items } });
  } catch (err) {
    console.error('[candidat/temoignages/eligible]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/', async (req, res) => {
  try {
    if (!req.chercheurId) {
      return res.status(403).json({ success: false, message: 'Profil candidat requis' });
    }

    const candidatureId = String(req.body?.candidature_id || '').trim();
    const message = String(req.body?.message || '').trim();

    if (!candidatureId) {
      return res.status(400).json({ success: false, message: 'candidature_id requis' });
    }
    if (message.length < 20 || message.length > 800) {
      return res.status(400).json({
        success: false,
        message: 'Le témoignage doit contenir entre 20 et 800 caractères.',
      });
    }

    const { data: cand, error: e1 } = await supabase
      .from('candidatures')
      .select(
        `
        id,
        chercheur_id,
        statut,
        offre_id,
        offres_emploi ( entreprise_id )
      `,
      )
      .eq('id', candidatureId)
      .maybeSingle();

    if (e1) throw e1;
    if (!cand || cand.chercheur_id !== req.chercheurId) {
      return res.status(404).json({ success: false, message: 'Candidature introuvable' });
    }
    if (cand.statut !== 'acceptee') {
      return res.status(400).json({
        success: false,
        message: 'Seules les candidatures acceptées peuvent faire l’objet d’un témoignage.',
      });
    }

    const off = cand.offres_emploi;
    const oRow = Array.isArray(off) ? off[0] : off;
    const entrepriseId = oRow?.entreprise_id;
    if (!entrepriseId) {
      return res.status(400).json({ success: false, message: 'Entreprise introuvable pour cette offre' });
    }

    const { data: dup } = await supabase
      .from('temoignages_recrutement')
      .select('id')
      .eq('candidature_id', candidatureId)
      .maybeSingle();
    if (dup) {
      return res.status(409).json({ success: false, message: 'Un témoignage existe déjà pour cette candidature.' });
    }

    const { data: inserted, error: e2 } = await supabase
      .from('temoignages_recrutement')
      .insert({
        utilisateur_id: req.user.id,
        candidature_id: candidatureId,
        entreprise_id: entrepriseId,
        message,
        est_publie: false,
        statut_moderation: 'en_attente',
      })
      .select('id')
      .single();

    if (e2) throw e2;

    return res.status(201).json({
      success: true,
      message:
        'Merci ! Votre témoignage a été transmis. Il sera visible sur la page d’accueil après validation par un administrateur.',
      data: inserted,
    });
  } catch (err) {
    console.error('[candidat/temoignages POST]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
