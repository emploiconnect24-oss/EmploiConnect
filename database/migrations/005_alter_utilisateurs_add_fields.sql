-- ═══════════════════════════════════════════════════════════
-- MIGRATION 005 : Colonnes admin sur utilisateurs
-- ═══════════════════════════════════════════════════════════

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS raison_blocage TEXT;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMP WITH TIME ZONE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS traite_par UUID
    REFERENCES utilisateurs(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_utilisateurs_role
  ON utilisateurs(role);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_est_actif
  ON utilisateurs(est_actif);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_est_valide
  ON utilisateurs(est_valide);
CREATE INDEX IF NOT EXISTS idx_utilisateurs_date_creation
  ON utilisateurs(date_creation DESC);
