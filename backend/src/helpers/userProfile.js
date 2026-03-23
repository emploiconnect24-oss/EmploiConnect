/**
 * Récupère l'id du profil (chercheur_emploi.id ou entreprises.id) à partir de l'utilisateur connecté
 */
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';

export async function getChercheurId(utilisateurId) {
  const { data, error } = await supabase
    .from('chercheurs_emploi')
    .select('id')
    .eq('utilisateur_id', utilisateurId)
    .single();
  if (error || !data) return null;
  return data.id;
}

export async function getEntrepriseId(utilisateurId) {
  const { data, error } = await supabase
    .from('entreprises')
    .select('id')
    .eq('utilisateur_id', utilisateurId)
    .single();
  if (error || !data) return null;
  return data.id;
}

/**
 * Attache chercheurId et/ou entrepriseId à req selon le rôle
 */
export async function attachProfileIds(req, res, next) {
  if (!req.user) return next();
  const { id, role } = req.user;
  if (role === ROLES.CHERCHEUR) {
    req.chercheurId = await getChercheurId(id);
  } else if (role === ROLES.ENTREPRISE) {
    req.entrepriseId = await getEntrepriseId(id);
  }
  next();
}
