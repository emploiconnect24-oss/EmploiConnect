/**
 * Données entreprises exposées sans authentification (vitrine).
 */
import { supabase } from '../../config/supabase.js';
import { STATUT_OFFRE } from '../../config/constants.js';

/**
 * GET /entreprises/top-public
 * Entreprises avec le plus d’offres actuellement publiées (active / publiee).
 */
export async function getTopEntreprisesPublic(req, res) {
  try {
    const lim = Math.min(Math.max(parseInt(req.query.limit, 10) || 12, 1), 24);

    const { data: offres, error } = await supabase
      .from('offres_emploi')
      .select(
        `
        entreprise_id,
        entreprises ( nom_entreprise, logo_url )
      `,
      )
      .in('statut', [STATUT_OFFRE.ACTIVE, 'publiee']);

    if (error) throw error;

    const counts = {};
    for (const o of offres || []) {
      const eid = o.entreprise_id;
      if (!eid) continue;
      const ent = o.entreprises;
      const row = Array.isArray(ent) ? ent[0] : ent;
      const nom = row?.nom_entreprise || 'Entreprise';
      if (!counts[eid]) {
        counts[eid] = {
          id: eid,
          nom_entreprise: nom,
          logo_url: row?.logo_url ?? null,
          nb_offres: 0,
        };
      }
      counts[eid].nb_offres += 1;
    }

    const top = Object.values(counts)
      .sort((a, b) => b.nb_offres - a.nb_offres)
      .slice(0, lim);

    return res.json({ success: true, data: top });
  } catch (err) {
    console.error('[getTopEntreprisesPublic]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
