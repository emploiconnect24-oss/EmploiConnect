-- Table alertes matching envoyees (anti-spam)
CREATE TABLE IF NOT EXISTS alertes_matching_envoyees (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  candidat_id   UUID,
  offre_id      UUID,
  entreprise_id UUID,
  type_alerte   TEXT NOT NULL,
  score         INTEGER,
  envoye_le     TIMESTAMPTZ DEFAULT NOW()
);

-- Une alerte offre_compatible max par candidat/offre/type
CREATE UNIQUE INDEX IF NOT EXISTS idx_alerte_unique
  ON alertes_matching_envoyees (candidat_id, offre_id, type_alerte)
  WHERE candidat_id IS NOT NULL;

-- Une alerte profil_compatible max pour le meme tuple entreprise/candidat/offre/type
CREATE UNIQUE INDEX IF NOT EXISTS idx_alerte_entreprise
  ON alertes_matching_envoyees (entreprise_id, candidat_id, offre_id, type_alerte)
  WHERE entreprise_id IS NOT NULL;

-- Colonnes d'analyse IA de candidature
ALTER TABLE candidatures
  ADD COLUMN IF NOT EXISTS score_matching INTEGER,
  ADD COLUMN IF NOT EXISTS analyse_ia     JSONB,
  ADD COLUMN IF NOT EXISTS conseils_ia    TEXT;
