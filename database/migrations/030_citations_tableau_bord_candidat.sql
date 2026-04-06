-- Citations du bandeau motivation sur le tableau de bord candidat (une phrase par ligne).
-- Le backend choisit une citation par jour + utilisateur ; si profil < 45 %, mélange avec des messages d'encouragement.

INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES (
  'citations_tableau_bord_candidat',
  E'Le succès appartient à ceux qui commencent.\nChaque candidature est un pas vers votre réussite.\nVotre prochaine opportunité est à portée de main.\nLes grandes choses commencent par une petite action.',
  'string',
  'Citations tableau de bord candidat (une par ligne). Laisser vide pour utiliser les textes par défaut serveur.',
  'general'
)
ON CONFLICT (cle) DO NOTHING;
