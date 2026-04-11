-- Toggles admin : simulateur entretien & calculateur salaire (Parcours Carrière)
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  (
    'ia_simulateur_actif',
    'true',
    'boolean',
    'Activer le simulateur d''entretien IA (Parcours Carrière)',
    'ia'
  ),
  (
    'ia_calculateur_actif',
    'true',
    'boolean',
    'Activer le calculateur de salaire IA (Parcours Carrière)',
    'ia'
  )
ON CONFLICT (cle) DO NOTHING;
