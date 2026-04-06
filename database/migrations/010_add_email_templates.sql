-- ═══════════════════════════════════════════════════════════
-- MIGRATION 010 : Templates emails + paramètres SMTP
-- ═══════════════════════════════════════════════════════════

INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('email_service_actif', 'false', 'boolean', 'Activer l''envoi d''emails (SMTP requis)', 'notifications'),
  ('email_smtp_host', '', 'string', 'Hôte SMTP (ex: smtp.gmail.com)', 'notifications'),
  ('email_smtp_port', '587', 'integer', 'Port SMTP', 'notifications'),
  ('email_smtp_user', '', 'string', 'Email expéditeur SMTP', 'notifications'),
  ('email_smtp_password', '', 'string', 'Mot de passe SMTP (chiffré)', 'notifications'),
  ('email_nom_expediteur', 'EmploiConnect', 'string', 'Nom expéditeur visible', 'notifications'),
  ('template_bienvenue_sujet', 'Bienvenue sur EmploiConnect !', 'string', 'Sujet email de bienvenue', 'notifications'),
  (
    'template_bienvenue_corps',
    'Bonjour {{nom}},\n\nBienvenue sur EmploiConnect !\n\nVotre compte a été créé avec succès.\nCommencez dès maintenant à explorer les offres d''emploi.\n\nBonne chance !\nL''équipe EmploiConnect',
    'string',
    'Corps de l''email de bienvenue',
    'notifications'
  ),
  ('template_candidature_sujet', 'Nouvelle candidature reçue pour "{{poste}}"', 'string', 'Sujet email candidature', 'notifications'),
  ('template_validation_sujet', 'Votre compte EmploiConnect a été validé', 'string', 'Sujet email validation compte', 'notifications')
ON CONFLICT (cle) DO NOTHING;

