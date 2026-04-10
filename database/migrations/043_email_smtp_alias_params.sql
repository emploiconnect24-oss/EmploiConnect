-- Ajoute des clés email/smtp génériques (alias) pour compatibilité admin/backend.
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('email_from', '', 'string', 'Adresse email expéditeur', 'notifications'),
  ('email_nom', 'EmploiConnect', 'string', 'Nom affiché dans les emails', 'notifications'),
  ('smtp_host', 'smtp.gmail.com', 'string', 'Serveur SMTP', 'notifications'),
  ('smtp_port', '587', 'string', 'Port SMTP', 'notifications'),
  ('smtp_user', '', 'string', 'Utilisateur SMTP (adresse email)', 'notifications'),
  ('smtp_password', '', 'string', 'Mot de passe SMTP / App password', 'notifications')
ON CONFLICT (cle) DO NOTHING;
