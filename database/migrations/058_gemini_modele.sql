INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('gemini_modele', 'imagen-3', 'string', 'Modele Gemini pour les images', 'ia')
ON CONFLICT (cle) DO NOTHING;
