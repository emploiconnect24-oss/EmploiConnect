-- Si true : les offres soumises « pour publication » passent directement en publiee (entreprise déjà validée).
-- Si false (défaut) : en_attente comme aujourd’hui (modération admin).

INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES (
  'offres_publication_auto',
  'false',
  'boolean',
  'Les nouvelles offres des entreprises validées sont publiées sans passage par la modération admin',
  'comptes'
)
ON CONFLICT (cle) DO NOTHING;
