-- Pièces jointes messagerie recruteur/candidat (URL stockage public).

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS piece_jointe_url TEXT;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS piece_jointe_nom TEXT;
