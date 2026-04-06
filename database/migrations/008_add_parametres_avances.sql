-- ═══════════════════════════════════════════════════════════
-- MIGRATION 008 : Paramètres avancés (logo, footer, IA, sécurité)
-- ═══════════════════════════════════════════════════════════

ALTER TABLE parametres_plateforme
  DROP CONSTRAINT IF EXISTS parametres_plateforme_categorie_check;

ALTER TABLE parametres_plateforme
  ADD CONSTRAINT parametres_plateforme_categorie_check
  CHECK (categorie IN (
    'general', 'comptes', 'notifications', 'ia_matching',
    'maintenance', 'securite', 'footer'
  ));

INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('adresse_contact', '', 'string', 'Adresse contact / siège (admin)', 'general'),
  ('logo_url', '', 'string', 'URL du logo principal de la plateforme', 'general'),
  ('favicon_url', '', 'string', 'URL du favicon', 'general'),
  ('couleur_primaire', '#1A56DB', 'string', 'Couleur primaire de la plateforme (hex)', 'general'),
  ('footer_linkedin', '', 'string', 'URL page LinkedIn', 'footer'),
  ('footer_facebook', '', 'string', 'URL page Facebook', 'footer'),
  ('footer_twitter', '', 'string', 'URL compte Twitter/X', 'footer'),
  ('footer_instagram', '', 'string', 'URL compte Instagram', 'footer'),
  ('footer_whatsapp', '', 'string', 'Numéro WhatsApp Business', 'footer'),
  ('footer_email', 'contact@emploiconnect.gn', 'string', 'Email affiché dans le footer', 'footer'),
  ('footer_telephone', '+224 620 00 00 00', 'string', 'Téléphone affiché dans le footer', 'footer'),
  ('footer_adresse', 'Conakry, République de Guinée', 'string', 'Adresse affichée dans le footer', 'footer'),
  ('footer_tagline', 'La plateforme intelligente de l''emploi en Guinée', 'string', 'Tagline sous le logo dans le footer', 'footer'),
  ('rapidapi_key', '', 'string', 'Clé API principale RapidAPI (chiffrée)', 'ia_matching'),
  ('rapidapi_similarity_host', '', 'string', 'Host API de similarité texte (RapidAPI)', 'ia_matching'),
  ('rapidapi_resume_parser_host', '', 'string', 'Host API de parsing CV (RapidAPI)', 'ia_matching'),
  ('ia_provider', 'rapidapi', 'string', 'Provider IA utilisé: rapidapi | openai | local', 'ia_matching'),
  ('openai_api_key', '', 'string', 'Clé API OpenAI (alternative à RapidAPI)', 'ia_matching'),
  ('ia_api_testee', 'false', 'boolean', 'Indique si la connexion API IA a été testée avec succès', 'ia_matching'),
  ('twofa_admin_actif', 'false', 'boolean', 'Activer l''authentification 2FA pour les admins', 'securite'),
  ('ips_bloquees', '[]', 'json', 'Liste des IPs bloquées (JSON array)', 'securite'),
  ('jwt_expiration_heures', '24', 'integer', 'Durée d''expiration du token JWT en heures', 'securite')
ON CONFLICT (cle) DO NOTHING;
