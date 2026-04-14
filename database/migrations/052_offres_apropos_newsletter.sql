-- Page À propos (CMS sections) + Newsletter abonnés + paramètres associés.

-- ── Page À propos ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS page_a_propos (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  section         TEXT NOT NULL UNIQUE,
  titre           TEXT,
  contenu         TEXT,
  icone           TEXT,
  ordre           INTEGER DEFAULT 0,
  est_actif       BOOLEAN DEFAULT TRUE,
  meta_donnees    JSONB
);

CREATE INDEX IF NOT EXISTS idx_page_a_propos_ordre
  ON page_a_propos (ordre);

CREATE INDEX IF NOT EXISTS idx_page_a_propos_actif
  ON page_a_propos (est_actif);

INSERT INTO page_a_propos (section, titre, contenu, icone, ordre)
VALUES
  ('hero',    'À propos d''EmploiConnect',
   'La première plateforme intelligente de l''emploi en Guinée, '
   'connectant les talents aux meilleures opportunités.',
   '🏢', 1),
  ('mission', 'Notre Mission',
   'EmploiConnect a pour mission de révolutionner le marché '
   'de l''emploi en Guinée en utilisant l''intelligence '
   'artificielle pour connecter efficacement les candidats '
   'qualifiés aux entreprises qui recrutent.',
   '🎯', 2),
  ('vision',  'Notre Vision',
   'Devenir la référence incontournable de l''emploi en '
   'Afrique de l''Ouest, en offrant une plateforme '
   'technologique qui valorise les talents locaux.',
   '🔭', 3),
  ('valeurs', 'Nos Valeurs',
   'Innovation · Excellence · Intégrité · Inclusion · Impact',
   '💎', 4),
  ('equipe',  'Notre Équipe',
   'Fondée par des professionnels guinéens passionnés, '
   'notre équipe combine expertise technologique et '
   'connaissance approfondie du marché local.',
   '👥', 5),
  ('contact', 'Nous Contacter',
   'Conakry, Guinée · contact@emploiconnect.gn · +224 XX XX XX XX',
   '📞', 6)
ON CONFLICT (section) DO NOTHING;

-- ── Newsletter ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS newsletter_abonnes (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email              TEXT NOT NULL UNIQUE,
  nom                TEXT,
  est_actif          BOOLEAN DEFAULT TRUE,
  date_inscription   TIMESTAMPTZ DEFAULT NOW(),
  source             TEXT DEFAULT 'footer',
  token_desabo       TEXT NOT NULL DEFAULT (gen_random_uuid()::TEXT)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_newsletter_token_desabo
  ON newsletter_abonnes (token_desabo);

CREATE INDEX IF NOT EXISTS idx_newsletter_email
  ON newsletter_abonnes (email);

CREATE INDEX IF NOT EXISTS idx_newsletter_actif
  ON newsletter_abonnes (est_actif);

INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('newsletter_actif', 'true', 'boolean',
   'Activer l''inscription newsletter', 'email'),
  ('newsletter_sujet_defaut', 'Nouvelles offres EmploiConnect', 'string',
   'Sujet par défaut des newsletters', 'email'),
  ('newsletter_nb_abonnes', '0', 'string',
   'Nombre d''abonnés actifs (cache)', 'email')
ON CONFLICT (cle) DO NOTHING;
