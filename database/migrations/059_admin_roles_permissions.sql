-- PRD v9.8 — Rôles & permissions admin

CREATE TABLE IF NOT EXISTS admin_roles (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom         TEXT NOT NULL UNIQUE,
  description TEXT,
  couleur     TEXT DEFAULT '#1A56DB',
  icone       TEXT DEFAULT 'admin_panel_settings',
  est_actif   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_permissions (
  id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  role_id  UUID NOT NULL REFERENCES admin_roles(id) ON DELETE CASCADE,
  section  TEXT NOT NULL,
  peut_voir     BOOLEAN DEFAULT FALSE,
  peut_modifier BOOLEAN DEFAULT FALSE,
  peut_supprimer BOOLEAN DEFAULT FALSE,
  UNIQUE(role_id, section)
);

CREATE INDEX IF NOT EXISTS idx_admin_permissions_role ON admin_permissions(role_id);

ALTER TABLE administrateurs
  ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES admin_roles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS est_super_admin BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS cree_par UUID REFERENCES administrateurs(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS est_actif BOOLEAN DEFAULT TRUE;

INSERT INTO admin_roles (nom, description, couleur, icone)
VALUES
  ('Super Admin',
   'Accès complet à toute la plateforme',
   '#EF4444', 'security'),
  ('Modérateur Offres',
   'Gère les offres d''emploi et candidatures',
   '#1A56DB', 'work'),
  ('Gestionnaire Utilisateurs',
   'Gère les candidats et entreprises',
   '#10B981', 'people'),
  ('Community Manager',
   'Gère bannières, newsletter et contenu',
   '#8B5CF6', 'campaign'),
  ('Support Client',
   'Gère les messages et notifications',
   '#F59E0B', 'support_agent')
ON CONFLICT (nom) DO NOTHING;

INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT id, section, voir, modifier, supprimer
FROM admin_roles,
(VALUES
  ('dashboard',      true,  false, false),
  ('offres',         true,  true,  true),
  ('candidatures',   true,  true,  false),
  ('entreprises',    true,  false, false),
  ('utilisateurs',   true,  false, false),
  ('signalements',   true,  true,  false),
  ('temoignages',    true,  true,  false)
) AS p(section, voir, modifier, supprimer)
WHERE nom = 'Modérateur Offres'
ON CONFLICT (role_id, section) DO NOTHING;

INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT id, section, voir, modifier, supprimer
FROM admin_roles,
(VALUES
  ('dashboard',    true, false, false),
  ('utilisateurs', true, true,  true),
  ('entreprises',  true, true,  false),
  ('candidatures', true, false, false)
) AS p(section, voir, modifier, supprimer)
WHERE nom = 'Gestionnaire Utilisateurs'
ON CONFLICT (role_id, section) DO NOTHING;

INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT id, section, voir, modifier, supprimer
FROM admin_roles,
(VALUES
  ('dashboard',         true, false, false),
  ('bannieres',         true, true,  true),
  ('newsletter',        true, true,  false),
  ('newsletter_envoi',  true, true,  false),
  ('illustrations',     true, true,  false)
) AS p(section, voir, modifier, supprimer)
WHERE nom = 'Community Manager'
ON CONFLICT (role_id, section) DO NOTHING;

INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT id, section, voir, modifier, supprimer
FROM admin_roles,
(VALUES
  ('dashboard',    true, false, false),
  ('messages',     true, true,  false),
  ('utilisateurs', true, false, false)
) AS p(section, voir, modifier, supprimer)
WHERE nom = 'Support Client'
ON CONFLICT (role_id, section) DO NOTHING;

-- Tous les administrateurs existants deviennent Super Admin (migration unique).
UPDATE administrateurs
SET
  role_id = (SELECT id FROM admin_roles WHERE nom = 'Super Admin' LIMIT 1),
  est_super_admin = TRUE,
  est_actif = COALESCE(est_actif, TRUE);
