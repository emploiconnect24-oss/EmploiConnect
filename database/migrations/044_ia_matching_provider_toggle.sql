-- Paramètres IA matching (même configuration admin que l'amélioration de texte).
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  (
    'ia_matching_provider',
    'anthropic',
    'string',
    'Provider IA pour le scoring de compatibilité offres/candidats',
    'ia'
  ),
  (
    'ia_matching_actif',
    'true',
    'boolean',
    'Activer l analyse sémantique IA pour le matching',
    'ia'
  )
ON CONFLICT (cle) DO UPDATE
SET
  description = EXCLUDED.description,
  categorie = EXCLUDED.categorie;
