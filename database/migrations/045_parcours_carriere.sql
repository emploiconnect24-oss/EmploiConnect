-- ═══════════════════════════════════════════════════════════
-- MIGRATION 045 : Parcours Carrière (ressources, vues, simulateur)
-- ═══════════════════════════════════════════════════════════

-- Type notification « ressource » (publication Parcours Carrière)
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (
  type IN (
    'candidature', 'offre', 'message', 'systeme',
    'alerte_emploi', 'validation_compte', 'autre', 'ressource'
  )
);

-- Bucket fichiers Parcours (PDF, vidéos, couvertures) — lecture publique
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'ressources',
  'ressources',
  true,
  52428800,
  ARRAY[
    'application/pdf',
    'video/mp4', 'video/webm', 'video/quicktime',
    'image/jpeg', 'image/png', 'image/webp'
  ]::text[]
)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Lecture publique ressources'
  ) THEN
    CREATE POLICY "Lecture publique ressources"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'ressources');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS ressources_carrieres (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  titre            TEXT NOT NULL,
  description      TEXT,
  contenu          TEXT,
  type_ressource   TEXT NOT NULL
    CHECK (type_ressource IN (
      'article', 'pdf', 'video_youtube', 'video_interne', 'conseil_ia'
    )),
  categorie        TEXT NOT NULL
    CHECK (categorie IN (
      'cv', 'entretien', 'salaire',
      'reconversion', 'entrepreneuriat', 'general'
    )),
  niveau           TEXT DEFAULT 'tous'
    CHECK (niveau IN ('debutant', 'intermediaire', 'avance', 'tous')),
  url_externe      TEXT,
  fichier_url      TEXT,
  image_couverture TEXT,
  duree_minutes    INTEGER,
  tags             TEXT[],
  est_publie       BOOLEAN DEFAULT FALSE,
  est_mis_en_avant BOOLEAN DEFAULT FALSE,
  nb_vues          INTEGER DEFAULT 0,
  auteur_id        UUID REFERENCES utilisateurs(id),
  date_creation    TIMESTAMPTZ DEFAULT NOW(),
  date_publication TIMESTAMPTZ,
  ordre_affichage  INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS ressources_vues (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ressource_id     UUID NOT NULL REFERENCES ressources_carrieres(id) ON DELETE CASCADE,
  utilisateur_id   UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  date_vue         TIMESTAMPTZ DEFAULT NOW(),
  progression      INTEGER DEFAULT 0,
  UNIQUE (ressource_id, utilisateur_id)
);

CREATE TABLE IF NOT EXISTS simulations_entretien (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  utilisateur_id   UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
  poste_vise       TEXT,
  domaine          TEXT,
  niveau           TEXT,
  questions        JSONB,
  score_global     INTEGER,
  duree_minutes    INTEGER,
  statut           TEXT DEFAULT 'en_cours'
    CHECK (statut IN ('en_cours', 'termine')),
  date_creation    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ressources_categorie
  ON ressources_carrieres(categorie);
CREATE INDEX IF NOT EXISTS idx_ressources_publie
  ON ressources_carrieres(est_publie);
CREATE INDEX IF NOT EXISTS idx_ressources_ordre
  ON ressources_carrieres(ordre_affichage, date_publication DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_ressources_vues_user
  ON ressources_vues(utilisateur_id);
CREATE INDEX IF NOT EXISTS idx_simulations_entretien_user
  ON simulations_entretien(utilisateur_id);
