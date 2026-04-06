-- Table messagerie interne recruteur/candidat
-- À exécuter dans Supabase SQL Editor.

CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  expediteur_id   UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  destinataire_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  contenu         TEXT NOT NULL,
  est_lu          BOOLEAN NOT NULL DEFAULT FALSE,
  offre_id        UUID REFERENCES offres_emploi(id) ON DELETE SET NULL,
  candidature_id  UUID REFERENCES candidatures(id) ON DELETE SET NULL,
  date_envoi      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  date_lecture    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation
  ON messages(conversation_id);

CREATE INDEX IF NOT EXISTS idx_messages_expediteur
  ON messages(expediteur_id);

CREATE INDEX IF NOT EXISTS idx_messages_destinataire
  ON messages(destinataire_id);

CREATE INDEX IF NOT EXISTS idx_messages_non_lus
  ON messages(destinataire_id, est_lu);

CREATE INDEX IF NOT EXISTS idx_messages_date_envoi
  ON messages(date_envoi DESC);
