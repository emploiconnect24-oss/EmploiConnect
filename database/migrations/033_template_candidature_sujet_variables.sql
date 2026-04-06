-- Ancien modèle utilisait {{poste}} alors que le serveur ne substituait que offre_titre.
-- Le backend accepte désormais poste / titre_offre / offre_titre ; on aligne le texte stocké pour clarté admin.
UPDATE parametres_plateforme
SET valeur = REPLACE(valeur, '{{poste}}', '{{titre_offre}}')
WHERE cle = 'template_candidature_sujet'
  AND valeur LIKE '%{{poste}}%';
