-- PRD v5.3 — Compteur de vues réel (offres_vues + nb_vues + RPC)
-- À exécuter dans Supabase SQL Editor ou via votre chaîne de migrations.

CREATE TABLE IF NOT EXISTS offres_vues (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offre_id   UUID NOT NULL REFERENCES offres_emploi(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES utilisateurs(id) ON DELETE SET NULL,
  ip_address VARCHAR(45),
  date_vue   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_offres_vues_offre_date
  ON offres_vues(offre_id, date_vue DESC);

CREATE INDEX IF NOT EXISTS idx_offres_vues_user
  ON offres_vues(user_id);

ALTER TABLE offres_emploi
  ADD COLUMN IF NOT EXISTS nb_vues INTEGER NOT NULL DEFAULT 0;

-- Fonction attendue par le PRD (nom canonique)
CREATE OR REPLACE FUNCTION increment_vues(offre_uuid UUID)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE offres_emploi
  SET nb_vues = COALESCE(nb_vues, 0) + 1
  WHERE id = offre_uuid;
END;
$$;

-- Compatibilité avec l’ancien nom utilisé par le backend Node
CREATE OR REPLACE FUNCTION increment_offre_vues(offre_id_input UUID)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM increment_vues(offre_id_input);
END;
$$;

-- Recalcul initial depuis l’historique des vues (si la table était vide avant)
UPDATE offres_emploi o
SET nb_vues = COALESCE((
  SELECT COUNT(*)::INTEGER FROM offres_vues v WHERE v.offre_id = o.id
), 0)
WHERE EXISTS (SELECT 1 FROM offres_vues LIMIT 1);
