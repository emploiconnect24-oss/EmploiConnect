-- ═══════════════════════════════════════════════════════════
-- MIGRATION 006 : Vue statistiques admin (agrégats scalaires)
-- Alignée sur statuts offres : active, brouillon, fermee, suspendue
-- Candidatures : en_attente, en_cours, acceptee, refusee, annulee
-- Signalements : en_attente, traite, rejete
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW v_stats_admin AS
SELECT
  (SELECT COUNT(*)::bigint FROM utilisateurs WHERE role = 'chercheur') AS total_chercheurs,
  (SELECT COUNT(*)::bigint FROM utilisateurs WHERE role = 'entreprise') AS total_entreprises,
  (SELECT COUNT(*)::bigint FROM utilisateurs WHERE role = 'admin') AS total_admins,
  (SELECT COUNT(*)::bigint FROM utilisateurs
    WHERE date_creation >= NOW() - INTERVAL '30 days') AS nouveaux_users_30j,
  (SELECT COUNT(*)::bigint FROM utilisateurs WHERE NOT est_valide) AS comptes_en_attente,
  (SELECT COUNT(*)::bigint FROM utilisateurs WHERE NOT est_actif AND est_valide) AS comptes_bloques,

  (SELECT COUNT(*)::bigint FROM offres_emploi WHERE statut = 'active') AS offres_actives,
  (SELECT COUNT(*)::bigint FROM offres_emploi WHERE statut = 'brouillon') AS offres_en_attente,
  (SELECT COUNT(*)::bigint FROM offres_emploi
    WHERE statut = 'suspendue' AND raison_refus IS NOT NULL) AS offres_refusees,
  (SELECT COUNT(*)::bigint FROM offres_emploi WHERE statut = 'fermee') AS offres_expirees,
  (SELECT COUNT(*)::bigint FROM offres_emploi
    WHERE date_publication >= NOW() - INTERVAL '30 days') AS nouvelles_offres_30j,

  (SELECT COUNT(*)::bigint FROM candidatures) AS total_candidatures,
  (SELECT COUNT(*)::bigint FROM candidatures WHERE statut = 'acceptee') AS candidatures_acceptees,
  (SELECT COUNT(*)::bigint FROM candidatures
    WHERE date_candidature >= NOW() - INTERVAL '30 days') AS nouvelles_candidatures_30j,

  (SELECT COUNT(*)::bigint FROM signalements WHERE statut = 'en_attente') AS signalements_en_attente,
  (SELECT 0::bigint) AS signalements_urgents,

  (SELECT COUNT(*)::bigint FROM cv) AS total_cv;
