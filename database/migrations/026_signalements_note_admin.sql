-- Message rédigé par l’admin à la clôture (emails / notifs : prioritaire sur la raison brute)
ALTER TABLE signalements
  ADD COLUMN IF NOT EXISTS note_admin TEXT;

COMMENT ON COLUMN signalements.note_admin IS 'Message modération affiché aux parties (signalé, concerné) ; optionnel.';
