-- Correction contrainte categorie + paramètres IA (admin amélioration textes).

-- Étape 1 : (debug optionnel)
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'parametres_plateforme'::regclass
--   AND conname LIKE '%categorie%';

-- Étape 2 : inclure 'ia' dans la contrainte CHECK.
ALTER TABLE parametres_plateforme
  DROP CONSTRAINT IF EXISTS parametres_plateforme_categorie_check;

ALTER TABLE parametres_plateforme
  ADD CONSTRAINT parametres_plateforme_categorie_check
  CHECK (categorie IN (
    'general', 'api', 'email', 'securite',
    'apparence', 'notifications', 'paiement',
    'ia', 'rapidapi', 'anthropic', 'openai',
    'comptes', 'ia_matching', 'maintenance', 'footer'
  ));

-- Étape 3 : upsert paramètres IA.
INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  (
    'anthropic_api_key',
    '',
    'string',
    'Clé API Anthropic (amélioration texte À propos)',
    'ia'
  ),
  (
    'anthropic_model',
    'claude-haiku-4-5-20251001',
    'string',
    'Modèle Claude utilisé',
    'ia'
  ),
  (
    'openai_api_key',
    '',
    'string',
    'Clé API OpenAI (optionnel)',
    'ia'
  ),
  (
    'ia_amelioration_provider',
    'anthropic',
    'string',
    'Provider IA pour amélioration textes',
    'ia'
  )
ON CONFLICT (cle) DO UPDATE
SET
  valeur = EXCLUDED.valeur,
  description = EXCLUDED.description,
  categorie = EXCLUDED.categorie;

-- Vérification
-- SELECT cle, valeur, categorie
-- FROM parametres_plateforme
-- WHERE categorie = 'ia';
