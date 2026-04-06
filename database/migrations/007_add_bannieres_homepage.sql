-- ═══════════════════════════════════════════════════════════
-- MIGRATION 007 : Table bannières homepage (nom ASCII pour Supabase/JS)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bannieres_homepage (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre         VARCHAR(255),
  sous_titre    TEXT,
  texte_badge   VARCHAR(100),
  image_url     TEXT NOT NULL,
  lien_cta_1    VARCHAR(500),
  label_cta_1   VARCHAR(100),
  lien_cta_2    VARCHAR(500),
  label_cta_2   VARCHAR(100),
  ordre         INTEGER DEFAULT 0,
  est_actif     BOOLEAN DEFAULT TRUE,
  date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  date_modification TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bannieres_homepage_ordre
  ON bannieres_homepage(ordre);
CREATE INDEX IF NOT EXISTS idx_bannieres_homepage_actif
  ON bannieres_homepage(est_actif);

-- Données initiales (une seule fois si la table est vide)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM bannieres_homepage LIMIT 1) THEN
    INSERT INTO bannieres_homepage
      (titre, sous_titre, texte_badge, image_url, label_cta_1,
       lien_cta_1, label_cta_2, lien_cta_2, ordre)
    VALUES
      (
        'Trouvez l''Emploi de Vos Rêves',
        'Des milliers d''offres vérifiées vous attendent. Postulez en un clic.',
        '🇬🇳 Plateforme N°1 en Guinée',
        'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1920&q=80',
        'Trouver un Emploi', '/offres',
        'Recruter des Talents', '/inscription-entreprise',
        1
      ),
      (
        'Votre CV Analysé Par l''Intelligence Artificielle',
        'Notre IA extrait vos compétences et vous recommande les offres les plus pertinentes.',
        '⚡ Matching intelligent par IA',
        'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=1920&q=80',
        'Analyser mon CV', '/inscription',
        'En savoir plus', '/offres',
        2
      ),
      (
        'Recrutez les Meilleurs Talents de Guinée',
        'Accédez à une base de candidats qualifiés. Trouvez le profil idéal en quelques minutes.',
        '🏢 Espace Recruteurs',
        'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=1920&q=80',
        'Espace Recruteur', '/inscription-entreprise',
        'Voir les offres', '/offres',
        3
      );
  END IF;
END $$;
