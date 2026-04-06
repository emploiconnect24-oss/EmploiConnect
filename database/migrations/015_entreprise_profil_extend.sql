-- Champs étendus profil entreprise (page recruteur + PATCH /users/me)
-- Exécuter dans Supabase SQL Editor.

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS date_modification TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS slogan VARCHAR(200);

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS email_public VARCHAR(255);

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS telephone_public VARCHAR(50);

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS mission TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS annee_fondation VARCHAR(10);

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS banniere_url TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS linkedin TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS facebook TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS twitter TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS instagram TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS whatsapp_business TEXT;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS valeurs JSONB DEFAULT '[]'::jsonb;

ALTER TABLE entreprises
  ADD COLUMN IF NOT EXISTS avantages JSONB DEFAULT '[]'::jsonb;
