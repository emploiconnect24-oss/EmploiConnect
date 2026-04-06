-- PRD_CANDIDAT_FIX - Section 2 + Section 6
-- 1) Cache des scores IA par paire (chercheur, offre)
-- 2) Upgrade de alertes_emploi pour couvrir tous les champs attendus

CREATE TABLE IF NOT EXISTS offres_scores_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id) ON DELETE CASCADE,
  offre_id UUID NOT NULL REFERENCES offres_emploi(id) ON DELETE CASCADE,
  score INTEGER NOT NULL DEFAULT 0,
  calcule_le TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (chercheur_id, offre_id)
);

CREATE INDEX IF NOT EXISTS idx_scores_chercheur ON offres_scores_cache(chercheur_id);
CREATE INDEX IF NOT EXISTS idx_scores_offre ON offres_scores_cache(offre_id);
CREATE INDEX IF NOT EXISTS idx_scores_chercheur_offre ON offres_scores_cache(chercheur_id, offre_id);

-- Compatibilité ascendante avec la migration 019 déjà en place
ALTER TABLE alertes_emploi
  ADD COLUMN IF NOT EXISTS nom VARCHAR(100),
  ADD COLUMN IF NOT EXISTS localisation VARCHAR(100),
  ADD COLUMN IF NOT EXISTS type_contrat VARCHAR(50),
  ADD COLUMN IF NOT EXISTS domaine VARCHAR(100),
  ADD COLUMN IF NOT EXISTS derniere_notif TIMESTAMPTZ;

-- Harmonisation des valeurs et fallback nom
UPDATE alertes_emploi
SET nom = COALESCE(NULLIF(TRIM(nom), ''), 'Alerte emploi')
WHERE nom IS NULL OR TRIM(nom) = '';

UPDATE alertes_emploi
SET localisation = COALESCE(localisation, ville)
WHERE localisation IS NULL AND ville IS NOT NULL;

UPDATE alertes_emploi
SET type_contrat = COALESCE(type_contrat, (types_contrat->>0))
WHERE type_contrat IS NULL
  AND jsonb_typeof(types_contrat) = 'array'
  AND jsonb_array_length(types_contrat) > 0;

-- Rendre nom obligatoire après backfill
ALTER TABLE alertes_emploi
  ALTER COLUMN nom SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_alertes_emploi_chercheur_active
  ON alertes_emploi(chercheur_id, est_active, date_creation DESC);
CREATE INDEX IF NOT EXISTS idx_alertes_emploi_nom
  ON alertes_emploi(chercheur_id, nom);
