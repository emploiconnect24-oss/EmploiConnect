-- ═══════════════════════════════════════════════════════════
-- MIGRATION 003 : Journal d'audit des actions admin
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS activite_admin (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id        UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
  action          VARCHAR(100) NOT NULL,
  type_objet      VARCHAR(50),
  objet_id        UUID,
  details         JSONB,
  ip_address      VARCHAR(45),
  user_agent      TEXT,
  date_action     TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activite_admin_id
  ON activite_admin(admin_id);
CREATE INDEX IF NOT EXISTS idx_activite_admin_date
  ON activite_admin(date_action DESC);
CREATE INDEX IF NOT EXISTS idx_activite_admin_action
  ON activite_admin(action);
