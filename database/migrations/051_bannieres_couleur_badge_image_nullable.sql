-- Couleur d’accent pour le badge / CTA (section pub) + image optionnelle pour les tickers (texte seul).
ALTER TABLE bannieres_homepage
  ADD COLUMN IF NOT EXISTS couleur_badge TEXT DEFAULT '#1A56DB';

ALTER TABLE bannieres_homepage
  ALTER COLUMN image_url DROP NOT NULL;
