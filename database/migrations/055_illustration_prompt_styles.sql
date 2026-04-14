INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('illustration_prompt_base', '', 'string',
   'Prompt de base pour DALL-E (vide = prompt auto)',
   'ia'),
  ('illustration_mode_affiche', 'true', 'boolean',
   'Generer des affiches pub style reseaux sociaux', 'ia'),
  ('illustration_dernier_style', '0', 'string',
   'Index du dernier style genere (rotation)', 'ia')
ON CONFLICT (cle) DO NOTHING;
