-- PRD Illustration IA v9.2 — table + paramètres (049 = bannières pub dans ce dépôt).
CREATE TABLE IF NOT EXISTS illustrations_ia (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  url_image       TEXT NOT NULL,
  prompt_utilise  TEXT,
  source          TEXT DEFAULT 'dalle'
    CHECK (source IN ('dalle', 'upload', 'unsplash')),
  est_active      BOOLEAN DEFAULT TRUE,
  date_generation TIMESTAMPTZ DEFAULT NOW(),
  heure_affichage INTEGER,
  meta_donnees    JSONB
);

CREATE INDEX IF NOT EXISTS idx_illustrations_active
  ON illustrations_ia(est_active, date_generation DESC);

INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('illustration_ia_actif', 'false', 'boolean',
   'Activer la génération IA quotidienne', 'ia'),
  ('illustration_nb_par_jour', '4', 'string',
   'Nombre d''images générées par jour', 'ia'),
  ('illustration_heure_generation', '6', 'string',
   'Heure de génération cron (0-23)', 'ia'),
  ('illustration_url_manuelle', '', 'string',
   'URL image manuelle (fallback si pas d''illustration active)', 'ia')
ON CONFLICT (cle) DO NOTHING;
