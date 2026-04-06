INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('notif_email_reset_mdp', 'true', 'boolean',
   'Email de réinitialisation de mot de passe (lien sécurisé)', 'notifications'),
  ('notif_email_alerte_emploi', 'true', 'boolean',
   'Email aux candidats dont une alerte emploi correspond à une nouvelle offre publiée', 'notifications'),
  ('notif_email_resume_hebdo', 'true', 'boolean',
   'Résumé hebdomadaire par email (candidats ayant activé l’option)', 'notifications'),
  ('notif_email_analyse_cv', 'true', 'boolean',
   'Email au candidat lorsque l’analyse IA du CV est terminée', 'notifications'),
  ('url_application_publique', 'http://localhost:8080', 'string',
   'URL du site (liens dans les emails : reset MDP, offres). Ex. https://app.emploiconnect.gn', 'general'),
  ('email_template_wrapper_html', '', 'string',
   'Enveloppe HTML des emails : inclure {{CONTENU}} pour le corps. Vide = modèle par défaut EmploiConnect.', 'notifications'),
  ('email_couleur_primaire', '#1A56DB', 'string', 'Couleur accent des emails HTML (si wrapper par défaut)', 'notifications'),
  ('template_reset_mdp_sujet', '', 'string', 'Sujet email reset MDP (vide = défaut). Variables: {{plateforme}}', 'notifications'),
  ('template_alerte_offre_sujet', '', 'string', 'Sujet alerte offre. {{titre_offre}}, {{plateforme}}', 'notifications'),
  ('template_resume_hebdo_sujet', '', 'string', 'Sujet résumé hebdo. {{plateforme}}', 'notifications'),
  ('template_analyse_cv_sujet', '', 'string', 'Sujet fin analyse CV. {{plateforme}}', 'notifications')
ON CONFLICT (cle) DO NOTHING;
