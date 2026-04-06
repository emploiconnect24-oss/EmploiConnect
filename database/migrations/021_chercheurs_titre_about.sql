-- Profil candidat : champs utilisés par complétion + PATCH /users/me (PRD étape 4)
ALTER TABLE chercheurs_emploi
  ADD COLUMN IF NOT EXISTS titre_poste VARCHAR(200),
  ADD COLUMN IF NOT EXISTS about TEXT;
