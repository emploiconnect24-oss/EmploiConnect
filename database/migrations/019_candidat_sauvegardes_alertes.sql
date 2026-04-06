-- Tables candidat: offres sauvegardées + alertes emploi

CREATE TABLE IF NOT EXISTS offres_sauvegardees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id) ON DELETE CASCADE,
  offre_id UUID NOT NULL REFERENCES offres_emploi(id) ON DELETE CASCADE,
  date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (chercheur_id, offre_id)
);

CREATE INDEX IF NOT EXISTS idx_offres_sauvegardees_chercheur
  ON offres_sauvegardees (chercheur_id, date_creation DESC);

CREATE TABLE IF NOT EXISTS alertes_emploi (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id) ON DELETE CASCADE,
  mots_cles TEXT,
  secteur TEXT,
  ville TEXT,
  salaire_min NUMERIC,
  types_contrat JSONB NOT NULL DEFAULT '[]'::jsonb,
  frequence VARCHAR(30) NOT NULL DEFAULT 'Immédiatement',
  est_active BOOLEAN NOT NULL DEFAULT TRUE,
  date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  date_modification TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alertes_emploi_chercheur
  ON alertes_emploi (chercheur_id, est_active, date_creation DESC);

