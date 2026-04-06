import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';

export async function requireRecruteur(req, res, next) {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentification requise',
      });
    }

    if (req.user.role !== ROLES.ENTREPRISE) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé. Compte entreprise requis.',
      });
    }

    const { data: entreprise, error } = await supabase
      .from('entreprises')
      .select('id, nom_entreprise, logo_url')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (error || !entreprise) {
      return res.status(403).json({
        success: false,
        message: 'Profil entreprise non trouvé. Complétez votre inscription.',
      });
    }

    req.entreprise = entreprise;
    return next();
  } catch (err) {
    console.error('[requireRecruteur]', err);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la vérification',
    });
  }
}

