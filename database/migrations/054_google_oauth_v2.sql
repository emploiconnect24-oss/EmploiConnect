-- Google OAuth v2: configuration complete depuis l'admin.

INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('google_client_id', '', 'string',
   'Client ID Google OAuth 2.0', 'auth'),
  ('google_client_secret', '', 'string',
   'Client Secret Google OAuth 2.0', 'auth'),
  ('google_oauth_actif', 'false', 'boolean',
   'Activer la connexion Google', 'auth'),
  ('google_redirect_uri', '', 'string',
   'URI de redirection OAuth', 'auth'),
  ('google_roles_defaut', 'chercheur', 'string',
   'Role par defaut nouveaux comptes Google', 'auth'),
  ('google_domaines_autorises', '', 'string',
   'Domaines autorises (vide = tous)', 'auth'),
  ('google_projet_id', '', 'string',
   'ID projet Google Cloud', 'auth'),
  ('app_url_prod', '', 'string',
   'URL du site en production', 'general')
ON CONFLICT (cle) DO NOTHING;
