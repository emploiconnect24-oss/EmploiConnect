-- Vérification par code envoyé sur la nouvelle adresse avant changement d’e-mail (admin)

CREATE TABLE IF NOT EXISTS admin_email_change_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  new_email VARCHAR(255) NOT NULL,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  tentatives_echouees SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (utilisateur_id)
);

CREATE INDEX IF NOT EXISTS idx_admin_email_change_expires
  ON admin_email_change_codes (expires_at);
