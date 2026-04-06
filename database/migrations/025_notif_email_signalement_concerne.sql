-- Email + in-app : personne concernée par un signalement (clôture admin)
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('notif_email_signalement_concerne', 'true', 'boolean',
   'Informer par email la personne concernée (offre, profil ou candidature) lorsque la modération clôture le signalement', 'notifications')
ON CONFLICT (cle) DO NOTHING;
