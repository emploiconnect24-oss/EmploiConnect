-- Bootstrap défensif pour routes publiques de config/bannières.
-- À exécuter si la base distante n'a pas encore reçu les migrations précédentes.

CREATE TABLE IF NOT EXISTS parametres_plateforme (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cle                   VARCHAR(100) UNIQUE NOT NULL,
  valeur                TEXT NOT NULL DEFAULT '',
  type_valeur           VARCHAR(20) DEFAULT 'string',
  description           TEXT,
  categorie             VARCHAR(50) DEFAULT 'general',
  modifiable_admin      BOOLEAN DEFAULT TRUE,
  date_modification     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  modifie_par           UUID
);

INSERT INTO parametres_plateforme (cle, valeur, type_valeur, categorie, description)
VALUES
  ('nom_plateforme', 'EmploiConnect', 'string', 'general', 'Nom de la plateforme'),
  ('logo_url', '', 'string', 'general', 'URL du logo'),
  ('couleur_primaire', '#1A56DB', 'string', 'general', 'Couleur principale'),
  ('footer_email', 'contact@example.com', 'string', 'footer', 'Email footer'),
  ('footer_telephone', '+224 620 00 00 00', 'string', 'footer', 'Tel footer'),
  ('footer_adresse', 'Conakry, Guinée', 'string', 'footer', 'Adresse footer'),
  ('footer_tagline', 'Plateforme intelligente emploi Guinée', 'string', 'footer', 'Tagline footer'),
  ('footer_linkedin', '', 'string', 'footer', 'LinkedIn'),
  ('footer_facebook', '', 'string', 'footer', 'Facebook'),
  ('footer_twitter', '', 'string', 'footer', 'Twitter'),
  ('mode_maintenance', 'false', 'boolean', 'maintenance', 'Mode maintenance')
ON CONFLICT (cle) DO NOTHING;

CREATE TABLE IF NOT EXISTS bannieres_homepage (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre         VARCHAR(255),
  sous_titre    TEXT,
  texte_badge   VARCHAR(100),
  image_url     TEXT NOT NULL,
  label_cta_1   VARCHAR(100),
  lien_cta_1    VARCHAR(500),
  label_cta_2   VARCHAR(100),
  lien_cta_2    VARCHAR(500),
  ordre         INTEGER DEFAULT 0,
  est_actif     BOOLEAN DEFAULT TRUE,
  date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO bannieres_homepage
  (titre, sous_titre, texte_badge, image_url, label_cta_1, lien_cta_1, label_cta_2, lien_cta_2, ordre)
VALUES
  (
    'Trouvez l''Emploi de Vos Rêves',
    'Des milliers d''offres vérifiées vous attendent.',
    '🇬🇳 Plateforme N°1 en Guinée',
    'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1920&q=80',
    'Trouver un Emploi', '/offres',
    'Recruter des Talents', '/inscription-entreprise',
    1
  ),
  (
    'Recrutez les Meilleurs Talents',
    'Accédez à une base de candidats qualifiés.',
    '🏢 Espace Recruteurs',
    'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=1920&q=80',
    'Espace Recruteur', '/inscription-entreprise',
    'Voir les offres', '/offres',
    2
  )
ON CONFLICT DO NOTHING;
