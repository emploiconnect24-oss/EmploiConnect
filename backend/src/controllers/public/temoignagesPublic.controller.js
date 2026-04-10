/**
 * GET /temoignages/public — témoignages publiés (vitrine accueil).
 */
import { supabase } from '../../config/supabase.js';

export async function getTemoignagesPublic(req, res) {
  try {
    const lim = Math.min(Math.max(parseInt(req.query.limit, 10) || 12, 1), 24);

    // Deux FK vers utilisateurs → PostgREST exige le nom de contrainte (PGRST201) :
    // - temoignages_recrutement_utilisateur_id_fkey (auteur / candidat)
    // - temoignages_recrutement_moderateur_user_id_fkey (modérateur — non utilisé ici)
    const { data, error } = await supabase
      .from('temoignages_recrutement')
      .select(
        `
        id,
        message,
        date_creation,
        auteur:utilisateurs!temoignages_recrutement_utilisateur_id_fkey (
          nom,
          photo_url
        ),
        entreprises ( nom_entreprise, logo_url )
      `,
      )
      .eq('statut_moderation', 'approuve')
      .eq('est_publie', true)
      .order('date_creation', { ascending: false })
      .limit(lim);

    if (error) throw error;

    const rows = (data || []).map((row) => {
      const u = row.auteur;
      const uRow = Array.isArray(u) ? u[0] : u;
      const e = row.entreprises;
      const eRow = Array.isArray(e) ? e[0] : e;
      return {
        id: row.id,
        message: row.message,
        date_creation: row.date_creation,
        candidat_nom: uRow?.nom || 'Candidat',
        candidat_photo_url: uRow?.photo_url || null,
        entreprise_nom: eRow?.nom_entreprise || 'Entreprise',
        entreprise_logo_url: eRow?.logo_url || null,
      };
    });

    return res.json({ success: true, data: rows });
  } catch (err) {
    console.error('[getTemoignagesPublic]', err);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
}
