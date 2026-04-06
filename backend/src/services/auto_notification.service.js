/**
 * Notifications automatiques pour les administrateurs (ne bloque jamais le flux principal).
 */
import { supabase } from '../config/supabase.js';
import { ROLES } from '../config/constants.js';
import { sendAdminAlertEmail } from './mail.service.js';

async function getAdminIds() {
  const { data } = await supabase
    .from('utilisateurs')
    .select('id')
    .eq('role', ROLES.ADMIN)
    .eq('est_actif', true);
  return (data || []).map((u) => u.id);
}

export async function notifierAdmins({ titre, message, type = 'systeme', lien }) {
  try {
    const adminIds = await getAdminIds();
    if (adminIds.length === 0) return;

    const notifications = adminIds.map((id) => ({
      destinataire_id: id,
      type_destinataire: 'individuel',
      titre,
      message,
      type,
      lien: lien || null,
    }));

    const { error } = await supabase.from('notifications').insert(notifications);
    if (error) {
      console.error('[notifierAdmins]', error.message);
      return;
    }
    void sendAdminAlertEmail({
      titre,
      message,
      lienRelatif: lien || null,
    });
  } catch (err) {
    console.error('[notifierAdmins]', err?.message || err);
  }
}

export async function notifNouvelleInscription(utilisateur) {
  if (!utilisateur?.id || utilisateur.role === ROLES.ADMIN) return;
  await notifierAdmins({
    titre: 'Nouveau compte à valider',
    message: `${utilisateur.nom} vient de s'inscrire en tant que ${utilisateur.role}`,
    type: 'validation_compte',
    lien: `/admin/utilisateurs/${utilisateur.id}`,
  });
}

export async function notifNouvelleOffre(offre, entrepriseNom) {
  if (!offre?.id) return;
  const nom = entrepriseNom || 'Une entreprise';
  const st = String(offre.statut || '').toLowerCase();
  const enModeration = st === 'en_attente' || st === 'brouillon';
  await notifierAdmins({
    titre: enModeration
      ? 'Nouvelle offre en attente de validation'
      : 'Nouvelle offre publiée',
    message: enModeration
      ? `${nom} a soumis l'offre « ${offre.titre} »`
      : `${nom} a publié l'offre « ${offre.titre} » (visible par les candidats).`,
    type: 'offre',
    lien: `/admin/offres/${offre.id}`,
  });
}

export async function notifNouveauSignalement(signalement) {
  if (!signalement?.id) return;
  await notifierAdmins({
    titre: 'Nouveau signalement reçu',
    message: `Un signalement de type « ${signalement.type_objet || 'inconnu'} » vient d'être soumis`,
    type: 'systeme',
    lien: '/admin/moderation',
  });
}
