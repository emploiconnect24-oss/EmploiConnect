-- Ajout/alignement permissions sections contenu + nouveau rôle Gestionnaire Contact.

-- Community Manager : contenu (newsletter + contact + equipe + apropos)
INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT r.id, p.section, p.voir, p.modifier, p.supprimer
FROM admin_roles r,
(VALUES
  ('messages_contact', true,  true,  false),
  ('newsletter',       true,  true,  false),
  ('newsletter_envoi', true,  true,  false),
  ('equipe',           true,  true,  false),
  ('apropos',          true,  true,  false)
) AS p(section, voir, modifier, supprimer)
WHERE r.nom = 'Community Manager'
ON CONFLICT (role_id, section)
DO UPDATE SET
  peut_voir      = EXCLUDED.peut_voir,
  peut_modifier  = EXCLUDED.peut_modifier,
  peut_supprimer = EXCLUDED.peut_supprimer;

-- Support Client : lecture/réponse messages contact + dashboard
INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT r.id, p.section, p.voir, p.modifier, p.supprimer
FROM admin_roles r,
(VALUES
  ('messages_contact', true, true,  false),
  ('dashboard',        true, false, false)
) AS p(section, voir, modifier, supprimer)
WHERE r.nom = 'Support Client'
ON CONFLICT (role_id, section)
DO UPDATE SET
  peut_voir      = EXCLUDED.peut_voir,
  peut_modifier  = EXCLUDED.peut_modifier,
  peut_supprimer = EXCLUDED.peut_supprimer;

-- Rôle dédié gestion contact
INSERT INTO admin_roles
  (nom, description, couleur, icone)
VALUES
  ('Gestionnaire Contact',
   'Répond aux messages de contact et gère l''équipe',
   '#10B981', 'support_agent')
ON CONFLICT (nom) DO NOTHING;

INSERT INTO admin_permissions
  (role_id, section, peut_voir, peut_modifier, peut_supprimer)
SELECT r.id, p.section, p.voir, p.modifier, p.supprimer
FROM admin_roles r,
(VALUES
  ('dashboard',        true,  false, false),
  ('messages_contact', true,  true,  false),
  ('equipe',           true,  true,  false),
  ('apropos',          true,  true,  false)
) AS p(section, voir, modifier, supprimer)
WHERE r.nom = 'Gestionnaire Contact'
ON CONFLICT (role_id, section)
DO UPDATE SET
  peut_voir      = EXCLUDED.peut_voir,
  peut_modifier  = EXCLUDED.peut_modifier,
  peut_supprimer = EXCLUDED.peut_supprimer;
