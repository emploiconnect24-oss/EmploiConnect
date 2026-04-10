-- ═══════════════════════════════════════════════════════════
-- MIGRATION 002 : Table paramètres plateforme
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parametres_plateforme (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cle                   VARCHAR(100) UNIQUE NOT NULL,
  valeur                TEXT NOT NULL,
  type_valeur           VARCHAR(20) CHECK (
    type_valeur IN ('string', 'boolean', 'integer', 'json')
  ) DEFAULT 'string',
  description           TEXT,
  categorie             VARCHAR(50) CHECK (
    categorie IN (
      'general', 'comptes', 'notifications', 'ia_matching',
      'maintenance', 'securite'
    )
  ) DEFAULT 'general',
  modifiable_admin      BOOLEAN DEFAULT TRUE,
  date_modification     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  modifie_par           UUID REFERENCES utilisateurs(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_parametres_cle ON parametres_plateforme(cle);
CREATE INDEX IF NOT EXISTS idx_parametres_categorie
  ON parametres_plateforme(categorie);

INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('nom_plateforme',
   'EmploiConnect', 'string',
   'Nom de la plateforme', 'general'),
  ('description_plateforme',
   'Plateforme intelligente d''offres et de recherche d''emploi en Guinée',
   'string', 'Description courte', 'general'),
  ('email_contact',
   'contact@example.com', 'string',
   'Email de contact public', 'general'),
  ('telephone_contact',
   '+224 620 00 00 00', 'string',
   'Téléphone public', 'general'),
  ('inscription_libre',
   'true', 'boolean',
   'Autoriser l''inscription libre', 'comptes'),
  ('validation_manuelle_comptes',
   'false', 'boolean',
   'Validation manuelle des nouveaux comptes', 'comptes'),
  ('max_offres_gratuit',
   '5', 'integer',
   'Nombre max d''offres actives pour compte gratuit', 'comptes'),
  ('duree_validite_offre_jours',
   '30', 'integer',
   'Durée de validité d''une offre en jours', 'comptes'),
  ('notif_email_candidature',
   'true', 'boolean',
   'Envoyer email à chaque candidature', 'notifications'),
  ('notif_email_validation',
   'true', 'boolean',
   'Envoyer email de validation de compte', 'notifications'),
  ('notif_resume_hebdo',
   'true', 'boolean',
   'Résumé hebdomadaire par email', 'notifications'),
  ('seuil_matching_minimum',
   '40', 'integer',
   'Score minimum pour suggérer une offre (%)', 'ia_matching'),
  ('suggestions_automatiques',
   'true', 'boolean',
   'Activer suggestions IA automatiques', 'ia_matching'),
  ('mode_maintenance',
   'false', 'boolean',
   'Mode maintenance actif', 'maintenance'),
  ('message_maintenance',
   'La plateforme est en cours de maintenance. Revenez bientôt.',
   'string', 'Message affiché en maintenance', 'maintenance'),
  ('duree_session_minutes',
   '1440', 'integer',
   'Durée de session en minutes (1440 = 24h)', 'securite'),
  ('max_tentatives_connexion',
   '5', 'integer',
   'Nombre max de tentatives avant blocage', 'securite')
ON CONFLICT (cle) DO NOTHING;
