-- Paramètres alertes matching (admin configurable)
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('matching_alertes_actif', 'true', 'boolean', 'Activer les alertes email matching', 'ia'),
  ('matching_seuil_alerte_candidat', '65', 'integer', 'Score minimum (0-100) pour alerter un candidat sur une offre compatible', 'ia'),
  ('matching_seuil_alerte_entreprise', '70', 'integer', 'Score minimum (0-100) pour alerter une entreprise sur un profil compatible', 'ia'),
  ('matching_alertes_pause_ms', '600', 'integer', 'Pause (ms) entre deux emails d alertes matching pour eviter le spam', 'ia'),
  ('matching_alertes_max_par_execution', '25', 'integer', 'Nombre max d emails matching envoyes par execution', 'ia')
ON CONFLICT (cle) DO NOTHING;
