-- Modération des témoignages : publication uniquement après validation admin.
ALTER TABLE temoignages_recrutement
  ADD COLUMN IF NOT EXISTS statut_moderation VARCHAR(20);

UPDATE temoignages_recrutement
SET statut_moderation = CASE WHEN est_publie IS TRUE THEN 'approuve' ELSE 'en_attente' END
WHERE statut_moderation IS NULL;

ALTER TABLE temoignages_recrutement
  ALTER COLUMN statut_moderation SET NOT NULL,
  ALTER COLUMN statut_moderation SET DEFAULT 'en_attente';

ALTER TABLE temoignages_recrutement
  ADD COLUMN IF NOT EXISTS note_moderation TEXT,
  ADD COLUMN IF NOT EXISTS date_moderation TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS moderateur_user_id UUID REFERENCES utilisateurs(id) ON DELETE SET NULL;

ALTER TABLE temoignages_recrutement
  ALTER COLUMN est_publie SET DEFAULT FALSE;

ALTER TABLE temoignages_recrutement DROP CONSTRAINT IF EXISTS temoignages_statut_moderation_check;
ALTER TABLE temoignages_recrutement ADD CONSTRAINT temoignages_statut_moderation_check
  CHECK (statut_moderation IN ('en_attente', 'approuve', 'refuse'));

CREATE INDEX IF NOT EXISTS idx_temoignages_statut_date
  ON temoignages_recrutement (statut_moderation, date_creation DESC);
