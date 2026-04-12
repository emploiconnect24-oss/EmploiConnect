-- PRD Homepage v2 — Section 6 : dimensions & lien bannières pub
ALTER TABLE bannieres_homepage
  ADD COLUMN IF NOT EXISTS largeur_px INTEGER DEFAULT 320,
  ADD COLUMN IF NOT EXISTS hauteur_px INTEGER DEFAULT 180,
  ADD COLUMN IF NOT EXISTS lien_externe TEXT,
  ADD COLUMN IF NOT EXISTS ordre_pub INTEGER DEFAULT 0;
