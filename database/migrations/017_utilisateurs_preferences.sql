-- Préférences compte entreprise (paramètres)
-- À exécuter dans Supabase SQL Editor.

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS langue_interface VARCHAR(30) DEFAULT 'Français';

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS fuseau_horaire VARCHAR(60) DEFAULT 'Africa/Conakry';

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS notif_nouvelles_candidatures BOOLEAN DEFAULT TRUE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS notif_messages_recus BOOLEAN DEFAULT TRUE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS notif_offres_expiration BOOLEAN DEFAULT TRUE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS notif_resume_hebdo BOOLEAN DEFAULT FALSE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS notif_push BOOLEAN DEFAULT TRUE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS privacy_profile_visible BOOLEAN DEFAULT TRUE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS privacy_show_salary_default BOOLEAN DEFAULT TRUE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS privacy_allow_direct_contact BOOLEAN DEFAULT TRUE;
