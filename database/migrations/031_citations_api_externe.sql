-- API de citations externes (tableau de bord candidat) — pilotée depuis l’admin.

INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  (
    'citations_api_active',
    'false',
    'boolean',
    'Si true, le tableau de bord candidat tente de récupérer une citation via une API HTTP (sinon textes locaux).',
    'general'
  ),
  (
    'citations_api_source',
    'zenquotes',
    'string',
    'Fournisseur : zenquotes | quotable | custom (URL dans citations_api_url_custom).',
    'general'
  ),
  (
    'citations_api_url_custom',
    '',
    'string',
    'URL GET renvoyant du JSON (ex. tableau [{q,a}] ou objet {content,author}) — utilisée si source = custom.',
    'general'
  )
ON CONFLICT (cle) DO NOTHING;
