-- ═══════════════════════════════════════════════════════════
-- MIGRATION 001 : Table notifications
-- Exécuter dans Supabase SQL Editor (après supabase_schema.sql)
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS notifications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  destinataire_id   UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
  type_destinataire VARCHAR(20) CHECK (
    type_destinataire IN ('tous', 'chercheurs', 'entreprises', 'individuel')
  ) DEFAULT 'individuel',
  titre             VARCHAR(255) NOT NULL,
  message           TEXT NOT NULL,
  type              VARCHAR(50) CHECK (
    type IN (
      'candidature', 'offre', 'message', 'systeme',
      'alerte_emploi', 'validation_compte', 'autre'
    )
  ) DEFAULT 'systeme',
  lien              VARCHAR(500),
  est_lue           BOOLEAN DEFAULT FALSE,
  envoye_par        UUID REFERENCES utilisateurs(id) ON DELETE SET NULL,
  date_envoi_prevu  TIMESTAMP WITH TIME ZONE,
  date_envoi_reel   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  date_creation     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_destinataire
  ON notifications(destinataire_id);
CREATE INDEX IF NOT EXISTS idx_notifications_est_lue
  ON notifications(est_lue);
CREATE INDEX IF NOT EXISTS idx_notifications_type
  ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_date
  ON notifications(date_creation DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
