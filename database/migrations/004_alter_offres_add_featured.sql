-- ═══════════════════════════════════════════════════════════
-- MIGRATION 004 : Colonnes admin sur offres_emploi
-- (statuts existants : active, brouillon, fermee, suspendue)
-- ═══════════════════════════════════════════════════════════

ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS en_vedette BOOLEAN DEFAULT FALSE;

ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS raison_refus TEXT;

ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS valide_par UUID
    REFERENCES utilisateurs(id) ON DELETE SET NULL;

ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS date_validation TIMESTAMP WITH TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_offres_en_vedette
  ON offres_emploi(en_vedette) WHERE en_vedette = TRUE;

CREATE INDEX IF NOT EXISTS idx_offres_statut_admin
  ON offres_emploi(statut);
