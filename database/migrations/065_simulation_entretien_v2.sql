-- Sessions de simulation d'entretien immersive (PRD v9.12)
CREATE TABLE IF NOT EXISTS simulation_sessions (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  candidat_id    UUID NOT NULL,
  poste_vise     TEXT NOT NULL,
  domaine        TEXT,
  niveau         TEXT DEFAULT 'junior',
  statut         TEXT DEFAULT 'en_cours',
  messages       JSONB DEFAULT '[]'::jsonb,
  score_final    INTEGER,
  rapport_ia     JSONB,
  duree_secondes INTEGER,
  nb_questions   INTEGER DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  termine_le     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_simulation_candidat
  ON simulation_sessions(candidat_id, created_at DESC);
