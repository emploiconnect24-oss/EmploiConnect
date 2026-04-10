-- Clés / options IA pour l’amélioration du texte « À propos » (admin + route candidat).
-- Cette migration est auto-suffisante: elle corrige d'abord la contrainte CHECK de categorie.

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

INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, categorie, description)
VALUES
  (
    'anthropic_api_key',
    '',
    'string',
    'ia',
    'Clé API Anthropic (amélioration texte À propos candidats)'
  ),
  (
    'anthropic_model',
    'claude-haiku-4-5-20251001',
    'string',
    'ia',
    'Modèle Claude pour amélioration À propos'
  ),
  (
    'openai_api_key',
    '',
    'string',
    'ia',
    'Clé API OpenAI (optionnel)'
  ),
  (
    'ia_amelioration_provider',
    'anthropic',
    'string',
    'ia',
    'Provider pour amélioration À propos : anthropic | openai | aucun'
  )
ON CONFLICT (cle) DO UPDATE
SET
  valeur = EXCLUDED.valeur,
  description = EXCLUDED.description,
  categorie = EXCLUDED.categorie;
