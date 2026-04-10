-- Resume Parser RapidAPI : hôte ai-resume-parser (à exécuter dans Supabase SQL Editor si besoin)
UPDATE parametres_plateforme
SET valeur = 'ai-resume-parser.p.rapidapi.com'
WHERE cle = 'rapidapi_resume_parser_host';

-- Vérification (résultat attendu : une ligne rapidapi_resume_parser_host + autres clés rapidapi)
SELECT cle, valeur
FROM parametres_plateforme
WHERE cle LIKE '%rapidapi%'
ORDER BY cle;
