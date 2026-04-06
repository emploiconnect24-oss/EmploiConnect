-- Témoignages candidats recrutés (affichage vitrine après acceptation + formulaire volontaire).
CREATE TABLE IF NOT EXISTS temoignages_recrutement (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  candidature_id UUID NOT NULL REFERENCES candidatures(id) ON DELETE CASCADE,
  entreprise_id UUID NOT NULL REFERENCES entreprises(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  est_publie BOOLEAN NOT NULL DEFAULT TRUE,
  date_creation TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT temoignages_recrutement_message_len CHECK (
    char_length(trim(message)) >= 20 AND char_length(message) <= 800
  ),
  CONSTRAINT temoignages_recrutement_candidature_unique UNIQUE (candidature_id)
);

CREATE INDEX IF NOT EXISTS idx_temoignages_publie_date
  ON temoignages_recrutement (est_publie, date_creation DESC);

CREATE INDEX IF NOT EXISTS idx_temoignages_utilisateur
  ON temoignages_recrutement (utilisateur_id);
