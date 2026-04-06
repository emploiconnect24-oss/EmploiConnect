-- Détails entretien (PRD recruteur) : lien visio, type, lieu, notes internes affichées côté recruteur.

ALTER TABLE candidatures
  ADD COLUMN IF NOT EXISTS lien_visio TEXT;

ALTER TABLE candidatures
  ADD COLUMN IF NOT EXISTS type_entretien TEXT;

ALTER TABLE candidatures
  ADD COLUMN IF NOT EXISTS lieu_entretien TEXT;

ALTER TABLE candidatures
  ADD COLUMN IF NOT EXISTS notes_entretien TEXT;
