INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('gemini_api_key', '', 'string', 'Cle API Google Gemini (AI Studio)', 'ia'),
  ('illustration_provider', 'dalle', 'string', 'Provider images : dalle ou gemini', 'ia')
ON CONFLICT (cle) DO NOTHING;
