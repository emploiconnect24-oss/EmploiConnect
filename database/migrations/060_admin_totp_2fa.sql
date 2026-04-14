-- TOTP 2FA par administrateur (secret stocké côté serveur uniquement)
ALTER TABLE administrateurs
  ADD COLUMN IF NOT EXISTS totp_secret TEXT,
  ADD COLUMN IF NOT EXISTS totp_secret_temp TEXT,
  ADD COLUMN IF NOT EXISTS twofa_actif BOOLEAN NOT NULL DEFAULT FALSE;
