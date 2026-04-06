-- ═══════════════════════════════════════════════════════════
-- MIGRATION 011 : IA — Host RapidAPI Topic Tagging
-- ═══════════════════════════════════════════════════════════

INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('rapidapi_topic_tagging_host',
   '', 'string',
   'Host API RapidAPI Topic Tagging (ex: twinword-topic-tagging1.p.rapidapi.com)',
   'ia_matching')
ON CONFLICT (cle) DO NOTHING;

