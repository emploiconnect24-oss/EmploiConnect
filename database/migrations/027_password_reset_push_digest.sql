-- Réinitialisation mot de passe (lien email), push (tokens FCM), suivi résumé hebdo

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_hash
  ON password_reset_tokens (token_hash) WHERE used_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user
  ON password_reset_tokens (utilisateur_id, created_at DESC);

CREATE TABLE IF NOT EXISTS device_push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  plateforme VARCHAR(20) NOT NULL DEFAULT 'android',
  date_mise_a_jour TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (utilisateur_id, token)
);

CREATE INDEX IF NOT EXISTS idx_device_push_tokens_user
  ON device_push_tokens (utilisateur_id);

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS dernier_resume_hebdo_envoye_at TIMESTAMPTZ;
