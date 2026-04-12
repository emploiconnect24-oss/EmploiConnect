-- Type de bannière : hero (carousel), ticker (bandeau défilant), pub (sidebar / futur)
ALTER TABLE bannieres_homepage
  ADD COLUMN IF NOT EXISTS type_banniere TEXT DEFAULT 'hero';

UPDATE bannieres_homepage SET type_banniere = 'hero' WHERE type_banniere IS NULL;
