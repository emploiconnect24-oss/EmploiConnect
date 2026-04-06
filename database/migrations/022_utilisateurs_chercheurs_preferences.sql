-- PRD_CANDIDAT_STEPBYSTEP ÉTAPE 10 — préférences candidat / notifications
ALTER TABLE chercheurs_emploi
  ADD COLUMN IF NOT EXISTS profil_visible BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS recevoir_propositions BOOLEAN DEFAULT TRUE;

ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS preferences_notif JSONB;
