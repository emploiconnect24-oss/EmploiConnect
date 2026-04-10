import { Router } from 'express';
import { authenticate, requireRole } from '../../middleware/auth.js';
import { ROLES } from '../../config/constants.js';
import { supabase } from '../../config/supabase.js';
import { ameliorerAproposAvecConfig } from '../../services/ameliorerAproposIa.service.js';

const router = Router();

router.use(authenticate);
router.use(requireRole(ROLES.CHERCHEUR));

/**
 * PUT /candidat/profil — mise à jour champs chercheur (tableaux vides = suppression)
 */
router.put('/profil', async (req, res) => {
  try {
    const userId = req.user.id;
    const body = req.body || {};
    const { data: ch, error: chErr } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', userId)
      .maybeSingle();

    if (chErr || !ch) {
      return res.status(404).json({ success: false, message: 'Profil non trouvé' });
    }

    const updateData = {};
    const scalarKeys = ['titre_poste', 'about', 'disponibilite', 'niveau_etude'];
    const arrayKeys = new Set(['competences', 'experiences', 'formations', 'langues']);

    for (const k of scalarKeys) {
      if (body[k] !== undefined) updateData[k] = body[k];
    }

    const about = String(body.about ?? '').trim();
    if (about && about.length > 800) {
      return res.status(400).json({
        success: false,
        message: 'Le texte À propos ne doit pas dépasser 800 caractères',
      });
    }
    for (const k of arrayKeys) {
      if (body[k] === undefined) continue;
      if (!Array.isArray(body[k])) {
        return res.status(400).json({
          success: false,
          message: `Le champ « ${k} » doit être un tableau (utilisez [] pour vider).`,
        });
      }
      updateData[k] = body[k];
    }

    if (Object.keys(updateData).length === 0) {
      return res.json({ success: true, message: 'Profil mis à jour avec succès' });
    }

    const { error: uErr } = await supabase
      .from('chercheurs_emploi')
      .update(updateData)
      .eq('id', ch.id);

    if (uErr) {
      console.error('[PUT /candidat/profil]', uErr);
      return res.status(500).json({ success: false, message: 'Erreur mise à jour' });
    }

    return res.json({ success: true, message: 'Profil mis à jour avec succès' });
  } catch (err) {
    console.error('[PUT /candidat/profil]', err?.message || err);
    return res.status(500).json({ success: false, message: err.message || 'Erreur serveur' });
  }
});

router.post('/ameliorer-apropos', async (req, res) => {
  try {
    const out = await ameliorerAproposAvecConfig(req.body || {});
    if (out.error) {
      return res.status(400).json({ success: false, message: out.error });
    }
    return res.json({ success: true, data: out.data });
  } catch (err) {
    console.error('[ameliorer-apropos]', err?.message || err);
    return res.status(500).json({ success: false, message: err?.message || 'Erreur serveur' });
  }
});

export default router;
