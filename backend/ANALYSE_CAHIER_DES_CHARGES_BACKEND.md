# Analyse du cahier des charges – Backend EmploiConnect

Document de référence avant le développement du backend. Synthèse du cahier des charges, des diagrammes et du schéma de base de données.

---

## 1. Vue d’ensemble du projet

**EmploiConnect** est une plateforme web intelligente de mise en relation entre **chercheurs d’emploi** et **entreprises** (recruteurs), avec intégration d’**IA/NLP** pour l’analyse de CV et le matching.

- **Contexte** : Marché de l’emploi en Guinée, faible digitalisation, besoin de centralisation et de matching intelligent.
- **Problématique** : Absence d’un système centralisé et intelligent pour mettre en correspondance offres et profils.
- **Objectif général** : Développer une plateforme permettant une meilleure valorisation des compétences, une recherche d’opportunités plus rapide et une simplification du recrutement grâce à l’IA.

---

## 2. Stack technique (cahier des charges + fichiers projet)

| Couche        | Technologie retenue |
|---------------|----------------------|
| **Frontend**  | Flutter              |
| **Backend**   | Node.js              |
| **Base de données** | Supabase (PostgreSQL) |
| **Stockage fichiers** | Supabase Storage (bucket `cv-files`) |
| **IA / NLP**  | Modèle NLP (spaCy, BERT ou similaire) pour extraction de compétences et scoring |

*Note : `supabase_config.md` mentionne NestJS ; le fichier "Technologies à utiliser" impose Node.js. Le backend peut être en Node.js (Express, Fastify ou NestJS).*

---

## 3. Objectifs spécifiques et traduction backend

| # | Objectif | Implication backend |
|---|----------|----------------------|
| 1 | Faciliter l’accès des chercheurs aux opportunités | Comptes sécurisés, espace personnel, filtres sur offres, **suggestions d’offres** (IA). |
| 2 | Permettre aux entreprises de publier et gérer les offres | CRUD offres, tableau de bord candidatures, **suggestions de profils** (IA). |
| 3 | Automatiser l’analyse des CV (IA) | Upload CV (PDF/DOCX), **extraction compétences/expérience/domaine** (NLP), stockage JSONB. |
| 4 | Optimiser le matching candidats / recruteurs | **Score de compatibilité** (candidat–offre), **algorithme de recommandation** (suggestions offres / profils). |
| 5 | Gestion centralisée et modérée par l’admin | Validation/suppression comptes et annonces, modération, **statistiques globales**. |
| 6 | Digitalisation du marché de l’emploi | API REST, authentification, données structurées (Supabase). |

---

## 4. Acteurs et fonctionnalités (extrait cahier des charges)

### 4.1 Chercheur d’emploi

- Création de compte, gestion de profil.
- **Téléversement du CV** (PDF ou DOCX).
- **Extraction automatique des compétences** par IA.
- **Suggestions personnalisées d’offres**.
- Consultation et recherche filtrée d’annonces.
- **Postulation directe** aux offres (avec score IA).
- Être contacté par les entreprises.

**Backend** : Auth, CRUD profil, upload CV + appel module IA, recherche/filtres offres, API de suggestions, création candidature + calcul score.

### 4.2 Entreprise / Recruteur

- Création et gestion compte entreprise.
- **Publication d’offres** (titre, description, exigences, salaire, localisation…).
- Réception et gestion des candidatures.
- **Recommandation de CV pertinents** (IA).
- Consultation profils et CV.

**Backend** : Auth, CRUD entreprise/offres, liste candidatures par offre, API de suggestions de profils (matching inverse), accès CV (Storage + métadonnées).

### 4.3 Administrateur

- Supervision du système.
- **Validation ou suppression** des comptes et des offres.
- **Modération** des contenus.
- **Statistiques globales** (offres, CV, candidatures, etc.).

**Backend** : Auth admin, endpoints modération (comptes, offres, signalements), agrégation statistiques (table `statistiques` ou requêtes dédiées).

---

## 5. Composante IA (cahier des charges)

### 5.1 Analyse automatique des CV (NLP)

- **Entrée** : Fichier CV (PDF/DOCX) ou texte extrait.
- **Sortie** : Compétences clés, domaine d’activité, niveau d’expérience, mots-clés.
- **Stockage** : Champs `competences_extrait`, `experience`, `domaine_activite`, `niveau_experience`, `texte_complet` dans la table `cv`.

### 5.2 Matching automatisé

- **Comparaison** : Compétences candidat ↔ exigences de l’offre.
- **Score de compatibilité** : 0–100 (stocké dans `candidatures.score_compatibilite`).
- **Suggestions** : Offres les plus adaptées au chercheur ; profils les plus adaptés à l’offre pour l’entreprise.
- **Techniques possibles** : Similarité cosinus (embeddings), matching par mots-clés, pondération, scoring personnalisé.

---

## 6. Flux métier (diagrammes de séquence)

### 6.1 Postuler à une offre

1. Chercheur consulte les offres (API liste offres, filtres).
2. Chercheur postule (API créer candidature).
3. Plateforme vérifie auth + présence d’un CV.
4. **Plateforme → IA** : Analyser CV + exigences de l’offre.
5. **IA → Plateforme** : Score de compatibilité.
6. Plateforme enregistre candidature (avec score).
7. Entreprise reçoit la candidature (notification / liste candidatures).
8. Plateforme confirme au chercheur.

**Backend** : Endpoint “postuler” qui enchaîne : vérifications → appel module IA → calcul score → insert `candidatures`.

### 6.2 Matching IA (suggestions)

1. Déclenchement : téléversement CV, consultation offres, ou recommandations automatiques.
2. **Plateforme → IA** : Demande de matching (CV + offres ou offre + profils).
3. **IA** : Extraction compétences (CV), lecture exigences (offre), calcul score, classement.
4. **IA → Plateforme** : Score + liste de suggestions.
5. Plateforme : affichage, enregistrement, notifications.

**Backend** : Services “analyse CV” et “matching” appelés par les endpoints candidature et suggestions.

---

## 7. Base de données (schéma Supabase)

### 7.1 Tables principales

| Table | Rôle |
|-------|------|
| `utilisateurs` | Comptes (chercheur, entreprise, admin) – nom, email, mot_de_passe, role, est_actif, est_valide |
| `chercheurs_emploi` | Profil chercheur – lien 1:1 utilisateur, competences (JSONB), niveau_etude, disponibilite |
| `entreprises` | Profil entreprise – lien 1:1 utilisateur, nom_entreprise, secteur, etc. |
| `administrateurs` | Lien 1:1 utilisateur, niveau_acces |
| `cv` | Fichier (Storage), competences_extrait, experience (JSONB), domaine_activite, texte_complet |
| `offres_emploi` | titre, description, exigences, competences_requises (JSONB), salaire, localisation, statut |
| `candidatures` | chercheur_id, offre_id, cv_id, score_compatibilite, statut (en_attente, acceptee, refusee…) |
| `statistiques` | Agrégats par date (nombre chercheurs, entreprises, offres, candidatures, etc.) |
| `signalements` | Modération (type_objet, objet_id, raison, statut) |

### 7.2 Vues utiles

- `v_offres_completes` : Offres actives + entreprise + nombre de candidatures.
- `v_candidatures_completes` : Candidatures + chercheur + offre + entreprise.

### 7.3 Points d’attention

- **RLS** : Politiques actuelles sur `utilisateurs` avec `auth.uid()`. À aligner avec le choix d’auth (Supabase Auth vs JWT custom avec table `utilisateurs`).
- **Mots de passe** : Si auth custom, hasher avec bcrypt avant insertion.
- **Storage** : Bucket `cv-files` privé ; politiques pour upload (chercheur) et lecture (entreprise pour ses candidatures, admin).

---

## 8. Périmètre fonctionnel backend (checklist)

### Authentification et utilisateurs

- [ ] Inscription / connexion (chercheur, entreprise, admin).
- [ ] Gestion du profil (GET/PATCH) selon le rôle.
- [ ] Gestion des rôles et champs `est_actif` / `est_valide` (admin).

### Chercheur d’emploi

- [ ] Upload CV (PDF/DOCX) → Storage + enregistrement en table `cv`.
- [ ] Déclenchement analyse IA (extraction compétences, mise à jour `cv`).
- [ ] Liste offres avec filtres (poste, domaine, lieu, salaire, type contrat…).
- [ ] Suggestions d’offres (appel module matching IA).
- [ ] Postuler à une offre (création candidature + calcul score IA).
- [ ] Tableau de bord : mes candidatures, statuts, suggestions.

### Entreprise

- [ ] CRUD offres d’emploi (titre, description, exigences, salaire, localisation, etc.).
- [ ] Liste des candidatures par offre (avec score, CV, profil).
- [ ] Suggestions de profils/CV pour une offre (matching IA inverse).
- [ ] Mise à jour statut candidature (en_cours, acceptee, refusee).
- [ ] Consultation profil/CV (avec contrôle d’accès).

### Administrateur

- [ ] Liste / validation / suppression des comptes (utilisateurs, est_valide, est_actif).
- [ ] Modération des offres (validation, suspension, suppression).
- [ ] Gestion des signalements (liste, traiter, rejeter).
- [ ] Tableau de bord statistiques (utilisation table/vue `statistiques` ou agrégations).

### Module IA (intégration backend)

- [ ] Service d’extraction de compétences à partir du texte du CV (NLP).
- [ ] Service de calcul du score de compatibilité (candidat ↔ offre).
- [ ] Service de recommandation : offres pour un chercheur ; profils pour une offre.
- [ ] Stockage des résultats dans `cv` (competences_extrait, experience, etc.) et `candidatures` (score_compatibilite).

### Technique

- [ ] Variables d’environnement (.env) : SUPABASE_*, JWT_SECRET, DATABASE_URL, bucket CV, etc.
- [ ] API REST (ou GraphQL) documentée.
- [ ] Gestion des erreurs et codes HTTP cohérents.
- [ ] CORS configuré pour le frontend Flutter (origines autorisées).

---

## 9. Synthèse pour le développement backend

1. **Respecter le cahier des charges** : Trois acteurs (chercheur, entreprise, admin), fonctionnalités listées ci-dessus, IA pour analyse CV et matching.
2. **S’appuyer sur le schéma existant** : Tables, vues et relations déjà en place dans Supabase ; pas de changement de schéma sans nécessité.
3. **Clarifier l’authentification** : Soit Supabase Auth (JWT Supabase) + synchronisation avec `utilisateurs`, soit auth custom (JWT émis par le backend, bcrypt sur `mot_de_passe`). Adapter les politiques RLS en conséquence.
4. **Isoler le module IA** : Services “analyse CV” et “matching” appelables par les contrôleurs ; faciliter tests et évolutions (changement de modèle NLP).
5. **Sécurité** : Ne jamais exposer la clé `service_role` au frontend ; l’utiliser uniquement côté backend pour opérations privilégiées (admin, agrégations, etc.).

Ce document peut servir de référence tout au long du développement du backend pour vérifier que les objectifs du cahier des charges sont couverts.

---

## 10. Recommandation : Authentification (choix cohérent)

Pour rester **vraiment cohérent** avec le schéma, le cahier des charges et la stack, le choix recommandé est :

### ✅ Authentification **custom** (backend Node.js)

| Critère | Pourquoi c’est cohérent |
|--------|--------------------------|
| **Schéma actuel** | La table `utilisateurs` contient déjà `mot_de_passe` et `role` ; elle est conçue pour une auth gérée par le backend. |
| **Une seule source de vérité** | Pas de double gestion (Supabase Auth + table utilisateurs) : tout passe par `utilisateurs` et les tables liées. |
| **Métier** | Champs `est_valide`, `est_actif`, `role` sont au cœur de la modération ; les gérer dans une seule table est plus simple. |
| **Documentation** | Le config Supabase mentionne déjà le hash des mots de passe avec **bcrypt** → logique d’auth custom. |
| **Flux** | Flutter appelle **uniquement** le backend Node ; le backend utilise Supabase avec la clé **service_role** pour toutes les opérations base de données. Pas d’accès direct au schéma depuis le client. |
| **Sécurité** | Le client ne reçoit jamais la clé Supabase ; le backend vérifie le JWT et applique les droits (chercheur / entreprise / admin). |

### Architecture retenue

```
Flutter (client)  →  Backend Node.js (JWT custom, bcrypt)  →  Supabase (service_role)
                           ↓
                    Table utilisateurs (mot_de_passe hashé, role, est_valide…)
```

### Rôle des politiques RLS Supabase

- Les politiques actuelles sur `utilisateurs` utilisent `auth.uid()` (Supabase Auth).
- Avec l’auth **custom** : le client ne parle pas à Supabase pour les données métier, seulement au backend.
- Le backend utilise la clé **service_role**, qui **contourne RLS**. Les politiques RLS ne s’appliquent donc pas aux requêtes du backend.
- On peut laisser les politiques en place (elles ne gênent pas) ou les désactiver si vous préférez simplifier le schéma.

### À implémenter côté backend

- **Inscription** : hash du mot de passe (bcrypt), insertion dans `utilisateurs` + création du profil selon le rôle (`chercheurs_emploi` ou `entreprises` ou `administrateurs`).
- **Connexion** : vérification email + mot de passe (bcrypt.compare), émission d’un **JWT** contenant par exemple `{ userId, email, role }` et une durée de vie (ex. 7j).
- **Middleware** : sur les routes protégées, vérification du JWT et injection de l’utilisateur (id, role) dans la requête.
- **Storage CV** : le backend génère des URLs signées Supabase Storage (ou upload proxy) pour que le client envoie le fichier sans exposer la clé.

### Alternative non retenue : Supabase Auth

- Nécessiterait de maintenir **auth.users** (Supabase) et **public.utilisateurs** en synchronisation (trigger ou appel après signup).
- Deux sources d’identité, gestion des rôles et de `est_valide` plus complexe.
- Intéressant si vous voulez plus tard OAuth (Google, etc.) sans tout coder côté Node ; pour une cohérence maximale avec le schéma actuel, l’auth custom reste le meilleur choix.
