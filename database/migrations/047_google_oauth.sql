-- OAuth Google : colonnes utilisateurs, catégorie auth, paramètres admin.

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS google_id TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS google_email TEXT,
  ADD COLUMN IF NOT EXISTS google_photo TEXT,
  ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email'
    CHECK (auth_provider IN ('email', 'google', 'both'));

ALTER TABLE utilisateurs
  ALTER COLUMN mot_de_passe DROP NOT NULL;

CREATE INDEX IF NOT EXISTS idx_utilisateurs_google_id
  ON utilisateurs(google_id);

ALTER TABLE parametres_plateforme
  DROP CONSTRAINT IF EXISTS parametres_plateforme_categorie_check;

ALTER TABLE parametres_plateforme
  ADD CONSTRAINT parametres_plateforme_categorie_check
  CHECK (categorie IN (
    'general', 'api', 'email', 'securite',
    'apparence', 'notifications', 'paiement',
    'ia', 'rapidapi', 'anthropic', 'openai',
    'comptes', 'ia_matching', 'maintenance', 'footer',
    'auth'
  ));

INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('google_client_id', '', 'string',
   'Google OAuth Client ID (xxx.apps.googleusercontent.com)', 'auth'),
  ('google_client_secret', '', 'string',
   'Google OAuth Client Secret (GOCSPX-xxx)', 'auth'),
  ('google_oauth_actif', 'true', 'boolean',
   'Activer la connexion avec Google', 'auth'),
  ('google_roles_defaut', 'chercheur', 'string',
   'Rôle par défaut pour les nouveaux comptes Google (chercheur | entreprise)', 'auth')
ON CONFLICT (cle) DO NOTHING;
