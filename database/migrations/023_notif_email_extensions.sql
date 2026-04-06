-- Options email transactionnel (lue par le backend mailSettings.js)
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('notif_email_messages', 'true', 'boolean',
   'Envoyer un email pour les nouveaux messages (respecte aussi notif_messages_recus par utilisateur)', 'notifications'),
  ('notif_email_offre_moderation', 'true', 'boolean',
   'Email au recruteur lorsque l’admin valide / refuse / met en vedette une offre', 'notifications'),
  ('notif_email_alertes_admin', 'true', 'boolean',
   'Email aux comptes admin : nouvelle inscription à valider, offre en attente, signalement', 'notifications'),
  ('notif_email_confirmation_candidature', 'true', 'boolean',
   'Email de confirmation au candidat après une candidature', 'notifications'),
  ('notif_email_compte_rejete', 'true', 'boolean',
   'Email à l’utilisateur si son compte est rejeté par un administrateur', 'notifications')
ON CONFLICT (cle) DO NOTHING;
