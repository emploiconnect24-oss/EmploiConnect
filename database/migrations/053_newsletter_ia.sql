-- Newsletter IA automatique + journal des campagnes.

INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('newsletter_ia_actif', 'false', 'boolean',
   'Activer la newsletter IA automatique', 'email'),
  ('newsletter_ia_seuil_offres', '3', 'string',
   'Nb nouvelles offres pour déclencher une newsletter IA', 'email'),
  ('newsletter_prompt_base',
   'Tu es le responsable communication d''EmploiConnect, la plateforme N1 de l''emploi en Guinee. Redige des newsletters professionnelles basees uniquement sur les donnees reelles de la plateforme : offres publiees, entreprises partenaires, candidats inscrits. Ne jamais inventer d''offres ou d''entreprises. Adapte le contenu au contexte guineen et africain. Toujours encourager les candidats a postuler et les entreprises a publier leurs offres.',
   'string',
   'Prompt de base pour toutes les newsletters IA', 'email'),
  ('newsletter_feature_semaine', '', 'string',
   'Fonctionnalité IA à mettre en avant dans la newsletter', 'email'),
  ('newsletter_ia_dernier_envoi', '', 'string',
   'Date ISO du dernier envoi automatique newsletter IA', 'email')
ON CONFLICT (cle) DO NOTHING;

CREATE TABLE IF NOT EXISTS newsletter_envois (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sujet TEXT,
  contenu TEXT,
  nb_destinataires INTEGER DEFAULT 0,
  source TEXT DEFAULT 'manuel'
    CHECK (source IN ('manuel', 'ia_auto', 'hebdo')),
  declencheur TEXT,
  date_envoi TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_newsletter_envois_date
  ON newsletter_envois (date_envoi DESC);

CREATE INDEX IF NOT EXISTS idx_newsletter_envois_source
  ON newsletter_envois (source);
