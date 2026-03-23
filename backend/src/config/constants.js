/**
 * Constantes métier (rôles, statuts) alignées sur le schéma Supabase
 */
export const ROLES = Object.freeze({
  CHERCHEUR: 'chercheur',
  ENTREPRISE: 'entreprise',
  ADMIN: 'admin',
});

export const STATUT_OFFRE = Object.freeze({
  ACTIVE: 'active',
  BROUILLON: 'brouillon',
  FERMEE: 'fermee',
  SUSPENDUE: 'suspendue',
});

export const STATUT_CANDIDATURE = Object.freeze({
  EN_ATTENTE: 'en_attente',
  EN_COURS: 'en_cours',
  ACCEPTEE: 'acceptee',
  REFUSEE: 'refusee',
  ANNULEE: 'annulee',
});
