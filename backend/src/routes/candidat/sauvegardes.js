import { Router } from 'express';
import { supabase } from '../../config/supabase.js';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { attachProfileIds } from '../../helpers/userProfile.js';
import { ROLES, STATUT_OFFRE } from '../../config/constants.js';

const router = Router();
router.use(authenticate, requireRole(ROLES.CHERCHEUR), attachProfileIds);

function isMissingSavedTable(err) {
  return err?.code === 'PGRST205'
    && typeof err?.message === 'string'
    && err.message.includes("Could not find the table 'public.offres_sauvegardees'");
}

router.get('/', async (req, res) => {
  try {
    const chercheurId = req.chercheurId;
    if (!chercheurId) return res.status(400).json({ success: false, message: 'Profil chercheur introuvable' });

    const { data, error } = await supabase
      .from('offres_sauvegardees')
      .select(`
        id, date_creation, offre_id,
        offre:offre_id (
          id, titre, localisation, type_contrat, statut, date_limite,
          entreprises(nom_entreprise)
        )
      `)
      .eq('chercheur_id', chercheurId)
      .order('date_creation', { ascending: false });

    if (error) {
      if (isMissingSavedTable(error)) {
        return res.json({
          success: true,
          data: [],
          warning: 'offres_sauvegardees_table_missing',
          message: 'La table offres_sauvegardees est absente. Appliquez la migration SQL 019.',
        });
      }
      throw error;
    }

    return res.json({ success: true, data: data || [] });
  } catch (err) {
    console.error('[candidat/sauvegardes GET /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.post('/', async (req, res) => {
  try {
    const chercheurId = req.chercheurId;
    const { offre_id: offreId } = req.body || {};
    if (!chercheurId) return res.status(400).json({ success: false, message: 'Profil chercheur introuvable' });
    if (!offreId) return res.status(400).json({ success: false, message: 'offre_id requis' });

    const { data: offre, error: offErr } = await supabase
      .from('offres_emploi')
      .select('id, statut')
      .eq('id', offreId)
      .maybeSingle();
    if (offErr) throw offErr;
    if (!offre) return res.status(404).json({ success: false, message: 'Offre non trouvée' });
    if (![STATUT_OFFRE.ACTIVE, 'publiee'].includes(offre.statut)) {
      return res.status(400).json({ success: false, message: 'Offre non sauvegardable (non publiée)' });
    }

    const { data, error } = await supabase
      .from('offres_sauvegardees')
      .upsert(
        { chercheur_id: chercheurId, offre_id: offreId },
        { onConflict: 'chercheur_id,offre_id' },
      )
      .select('id, chercheur_id, offre_id, date_creation')
      .maybeSingle();
    if (error) {
      if (isMissingSavedTable(error)) {
        return res.status(503).json({
          success: false,
          message: 'Sauvegardes indisponibles: table offres_sauvegardees absente. Appliquez la migration SQL 019.',
          code: 'offres_sauvegardees_table_missing',
        });
      }
      throw error;
    }
    return res.status(201).json({ success: true, data: data ?? { chercheur_id: chercheurId, offre_id: offreId } });
  } catch (err) {
    console.error('[candidat/sauvegardes POST /]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

router.delete('/:offreId', async (req, res) => {
  try {
    const chercheurId = req.chercheurId;
    const { offreId } = req.params;
    if (!chercheurId) return res.status(400).json({ success: false, message: 'Profil chercheur introuvable' });

    const { data, error } = await supabase
      .from('offres_sauvegardees')
      .delete()
      .eq('chercheur_id', chercheurId)
      .eq('offre_id', offreId)
      .select('id');
    if (error) {
      if (isMissingSavedTable(error)) {
        return res.status(503).json({
          success: false,
          message: 'Sauvegardes indisponibles: table offres_sauvegardees absente. Appliquez la migration SQL 019.',
          code: 'offres_sauvegardees_table_missing',
        });
      }
      throw error;
    }
    if (!data?.length) return res.status(404).json({ success: false, message: 'Offre non trouvée dans vos sauvegardes' });
    return res.json({ success: true });
  } catch (err) {
    console.error('[candidat/sauvegardes DELETE /:offreId]', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

export default router;

