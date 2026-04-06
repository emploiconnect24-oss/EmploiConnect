import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { supabase } from '../../config/supabase.js';
import { ROLES } from '../../config/constants.js';

const router = Router();
router.use(authenticate, requireRole(ROLES.CHERCHEUR), attachProfileIds);

router.get('/', async (req, res) => {
  try {
    const {
      statut,
      page = 1,
      limite = 20,
      ordre = 'date_candidature',
      direction = 'desc',
    } = req.query;
    if (!req.chercheurId) {
      return res.json({ success: true, data: { candidatures: [], stats: {}, pagination: {} } });
    }

    const p = Math.max(1, parseInt(page, 10) || 1);
    const l = Math.min(100, Math.max(1, parseInt(limite, 10) || 20));
    const offset = (p - 1) * l;

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite, date_candidature, date_modification, lettre_motivation, raison_refus,
        offre:offre_id (
          id, titre, localisation, type_contrat, salaire_min, salaire_max, devise, date_limite, en_vedette,
          entreprise:entreprise_id (id, nom_entreprise, logo_url, secteur_activite)
        )
      `, { count: 'exact' })
      .eq('chercheur_id', req.chercheurId)
      .order(ordre, { ascending: String(direction).toLowerCase() === 'asc' })
      .range(offset, offset + l - 1);

    if (statut && statut !== 'all') query = query.eq('statut', statut);

    const { data, count, error } = await query;
    if (error) throw error;

    const { data: allRows, error: statsErr } = await supabase
      .from('candidatures')
      .select('statut')
      .eq('chercheur_id', req.chercheurId);
    if (statsErr) throw statsErr;

    const all = allRows || [];
    const stats = {
      total: all.length,
      en_attente: all.filter((x) => x.statut === 'en_attente').length,
      en_cours: all.filter((x) => x.statut === 'en_cours').length,
      entretien: all.filter((x) => x.statut === 'entretien').length,
      acceptees: all.filter((x) => x.statut === 'acceptee').length,
      refusees: all.filter((x) => x.statut === 'refusee').length,
    };

    return res.json({
      success: true,
      data: {
        candidatures: data || [],
        stats,
        pagination: {
          total: count || 0,
          page: p,
          limite: l,
          total_pages: Math.ceil((count || 0) / l),
        },
      },
    });
  } catch (err) {
    console.error('[candidat/candidatures GET /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;
