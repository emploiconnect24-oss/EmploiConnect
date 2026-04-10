-- Listes profil candidat persistées (PATCH /users/me, sync après suppression)
ALTER TABLE chercheurs_emploi
  ADD COLUMN IF NOT EXISTS experiences JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS formations JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS langues JSONB DEFAULT '[]'::jsonb;
