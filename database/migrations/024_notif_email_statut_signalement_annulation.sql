-- Emails : évolution candidature, résolution signalement, annulation côté candidat
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('notif_email_statut_candidature', 'true', 'boolean',
   'Email au candidat lorsque le recruteur (ou admin) modifie le statut de sa candidature', 'notifications'),
  ('notif_email_signalement_resolution', 'true', 'boolean',
   'Email au signalant lorsque l’admin traite ou rejette un signalement', 'notifications'),
  ('notif_email_annulation_candidature_recruteur', 'true', 'boolean',
   'Email au recruteur lorsque le candidat retire sa candidature', 'notifications')
ON CONFLICT (cle) DO NOTHING;
