# Migrations SQL — module Admin (PRD_BACKEND_ADMIN)

Exécuter **dans l’ordre** dans le **SQL Editor** du projet Supabase (après `database/supabase_schema.sql`).

| Ordre | Fichier | Description |
|-------|---------|-------------|
| 1 | `001_add_notifications.sql` | Table `notifications` |
| 2 | `002_add_parametres_plateforme.sql` | Table `parametres_plateforme` + données par défaut |
| 3 | `003_add_activite_admin.sql` | Table `activite_admin` (audit) |
| 4 | `004_alter_offres_add_featured.sql` | Colonnes `en_vedette`, `raison_refus`, `valide_par`, etc. |
| 5 | `005_alter_utilisateurs_add_fields.sql` | Colonnes `raison_blocage`, `derniere_connexion`, `traite_par` |
| 6 | `006_add_stats_view.sql` | Vue `v_stats_admin` (optionnelle ; le backend utilise aussi des comptages directs) |

PostgreSQL 13+ : `gen_random_uuid()` est requis (disponible sur Supabase).

Après exécution, redémarrer le backend si besoin. Aucun fichier `.env` supplémentaire n’est requis pour ces scripts.
