-- Ajoute les champs nécessaires aux actions recruteur sur candidatures
-- (planifier entretien / refuser avec raison).

ALTER TABLE candidatures
  ADD COLUMN IF NOT EXISTS date_entretien TIMESTAMPTZ;

ALTER TABLE candidatures
  ADD COLUMN IF NOT EXISTS raison_refus TEXT;

