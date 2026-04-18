-- PRD v9.10 — Équipe À propos + messages de contact

CREATE TABLE IF NOT EXISTS equipe_membres (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom         TEXT NOT NULL,
  poste       TEXT,
  description TEXT,
  photo_url   TEXT,
  linkedin    TEXT,
  ordre       INTEGER DEFAULT 0,
  est_actif   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages_contact (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom         TEXT NOT NULL,
  email       TEXT NOT NULL,
  sujet       TEXT,
  message     TEXT NOT NULL,
  est_lu      BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_equipe_ordre
  ON equipe_membres(ordre, est_actif);

CREATE INDEX IF NOT EXISTS idx_contact_lu
  ON messages_contact(est_lu, created_at DESC);

INSERT INTO equipe_membres
  (nom, poste, description, ordre)
VALUES
  (
    'BARRY YOUSSOUF',
    'Fondateur & Développeur Full Stack',
    'Étudiant en Licence Professionnelle Génie Logiciel. Développeur et architecte de la plateforme EmploiConnect.',
    1
  ),
  (
    'DIALLO ISMAILA',
    'Co-Fondateur & Designer',
    'Étudiant en Licence Professionnelle Génie Logiciel. Co-développeur et responsable design de la plateforme.',
    2
  )
ON CONFLICT DO NOTHING;
