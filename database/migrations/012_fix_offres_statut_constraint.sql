-- Aligne les statuts offres entre backend/admin/recruteur.
-- Garde compatibilité avec anciens statuts déjà présents en base.

ALTER TABLE offres_emploi
  DROP CONSTRAINT IF EXISTS offres_emploi_statut_check;

ALTER TABLE offres_emploi
  ADD CONSTRAINT offres_emploi_statut_check
  CHECK (
    statut IN (
      'brouillon',
      'en_attente',
      'publiee',
      'refusee',
      'fermee',
      -- Legacy (compat)
      'active',
      'suspendue'
    )
  );
