/**
 * Routes signalements - Création par tout utilisateur authentifié
 */
import { Router } from 'express';
import { supabase } from '../config/supabase.js';
import { authenticate } from '../middleware/auth.js';
import { logError } from '../utils/logger.js';

const router = Router();
const TYPES_OBJET = ['offre', 'profil', 'candidature'];

router.use(authenticate);

/**
 * POST /signalements - Signaler un contenu (offre, profil, candidature)
 * Body: { type_objet, objet_id, raison }
 */
router.post('/', async (req, res) => {
  try {
    const { type_objet, objet_id, raison } = req.body;

    if (!type_objet || !objet_id || !raison) {
      return res.status(400).json({
        message: 'Champs requis : type_objet (offre | profil | candidature), objet_id, raison',
      });
    }

    if (!TYPES_OBJET.includes(type_objet)) {
      return res.status(400).json({
        message: 'type_objet doit être : offre, profil ou candidature',
      });
    }

    const raisonTrim = String(raison).trim();
    if (raisonTrim.length < 10) {
      return res.status(400).json({ message: 'La raison doit contenir au moins 10 caractères' });
    }
    if (raisonTrim.length > 1000) {
      return res.status(400).json({ message: 'La raison ne doit pas dépasser 1000 caractères' });
    }

    const { data, error } = await supabase
      .from('signalements')
      .insert({
        utilisateur_signalant_id: req.user.id,
        type_objet,
        objet_id,
        raison: raisonTrim,
        statut: 'en_attente',
      })
      .select('id, type_objet, objet_id, statut, date_signalement')
      .single();

    if (error) {
      logError('POST /signalements - erreur insertion', error);
      return res.status(500).json({ message: 'Erreur lors du signalement' });
    }

    res.status(201).json(data);
  } catch (err) {
    logError('POST /signalements - erreur inattendue', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

export default router;
