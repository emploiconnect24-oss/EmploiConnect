-- Messagerie: soft delete + métadonnées fichier/type pour UI avancée.

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS type_message VARCHAR(20) DEFAULT 'texte';

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS fichier_url TEXT;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS fichier_nom TEXT;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS fichier_taille INTEGER;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS fichier_type VARCHAR(80);

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS est_supprime_exp BOOLEAN DEFAULT FALSE;

ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS est_supprime_dest BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_messages_conv_non_lus
  ON messages(conversation_id, destinataire_id, est_lu);
