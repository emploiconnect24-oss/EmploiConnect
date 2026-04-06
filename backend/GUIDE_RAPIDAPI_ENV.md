# Guide : RapidAPI — liens, `.env`, admin et tests réels (EmploiConnect)

Ce guide indique **où cliquer sur RapidAPI**, quoi mettre dans **`backend/.env`** (ou dans l’**admin**), et **comment vérifier dans l’app** que chaque API produit un effet visible.

---

## Liens directs RapidAPI (ouvrir, s’inscrire, s’abonner au plan gratuit)

| API | Rôle dans EmploiConnect | Lien direct |
|-----|------------------------|-------------|
| **Dashboard** (même clé pour tout) | Récupérer `RAPIDAPI_KEY` | [rapidapi.com/developer/dashboard](https://rapidapi.com/developer/dashboard) |
| **Twinword Text Similarity** | Score de compatibilité candidat ↔ offre | [rapidapi.com/twinword/api/text-similarity](https://rapidapi.com/twinword/api/text-similarity) |
| **Twinword Topic Tagging** | Mots-clés / sujets à partir du texte d’une offre | [rapidapi.com/twinword/api/topic-tagging](https://rapidapi.com/twinword/api/topic-tagging) |
| **Recherche « resume parser »** | Parser PDF/DOCX du CV (plusieurs fournisseurs possibles) | [rapidapi.com/search/resume%20parser](https://rapidapi.com/search/resume%20parser) |

**Important :** pour le **Resume Parser**, il n’existe pas une seule URL « officielle » imposée par le projet : vous choisissez une API avec **plan gratuit**, puis vous copiez **exactement** le **`X-RapidAPI-Host`** et le chemin d’endpoint indiqués sous **Endpoints** (voir plus bas).  
Les valeurs **par défaut** dans le code (`backend/src/config/rapidApi.js`) sont :

- Similarité : `twinword-text-similarity-v1.p.rapidapi.com` (vérifiez sur la page Twinword l’host **réel** affiché aujourd’hui — il peut être `…-v1…` ou une variante).
- Topic Tagging : `twinword-topic-tagging1.p.rapidapi.com`
- Parser (exemple historique) : `resume-parser3.p.rapidapi.com` — à confirmer sur **votre** fiche RapidAPI après abonnement.

---

## Étape 0 : Compte RapidAPI

1. Ouvrez [rapidapi.com](https://rapidapi.com) → **Sign Up** / **Log In**.
2. Une fois connecté, la **même** clé sert pour **toutes** les APIs auxquelles vous vous abonnez.

---

## Étape 1 : Clé API (`RAPIDAPI_KEY`)

1. Allez sur [rapidapi.com/developer/dashboard](https://rapidapi.com/developer/dashboard).
2. **Apps** → votre application (ou **Create App**).
3. Onglet **Security** / **API Keys** → copiez la clé.

Dans **`backend/.env`** :

```env
RAPIDAPI_KEY=votre_cle_ici
```

### Priorité **admin** vs **`.env`**

Le backend lit la table **`parametres_plateforme`** puis complète avec le `.env` :

- Si la **clé RapidAPI en admin** est **valide** (texte en clair, ou bien **chiffrée et déchiffrable** avec `ENCRYPTION_KEY` dans le `.env` du serveur), c’est **elle** qui est utilisée.
- Si la clé en base est **absente** ou **illisible** (déchiffrement impossible), le backend utilise **`RAPIDAPI_KEY`** du `.env`.

**Objectif de l’admin :** ne pas avoir à rouvrir le code pour changer la clé — **à condition** que le serveur ait une **`ENCRYPTION_KEY` d’au moins 16 caractères** (même valeur que celle utilisée lors du premier enregistrement de la clé). Sans ça, la clé peut être stockée en clair ; si elle est chiffrée avec une autre machine / autre secret, le déchiffrement échoue et RapidAPI reçoit une « fausse » clé → les tests échouent jusqu’à ce que vous mettiez la bonne clé dans le `.env` ou corrigiez `ENCRYPTION_KEY`.

**Cache :** après enregistrement des paramètres IA dans l’admin, le cache des clés est **invalidé** immédiatement (plus besoin d’attendre 5 minutes ni de redémarrer uniquement pour ça).

---

## Étape 2 : Text Similarity (Twinword)

1. Ouvrez [rapidapi.com/twinword/api/text-similarity](https://rapidapi.com/twinword/api/text-similarity).
2. **Pricing** → plan gratuit (ex. **Basic**) → **Subscribe**.
3. **Endpoints** → repérez l’appel **GET** type `/similarity/` avec `text1` et `text2`.
4. Copiez **`X-RapidAPI-Host`** (sans `https://`).

```env
RAPIDAPI_SIMILARITY_HOST=twinword-text-similarity-v1.p.rapidapi.com
```

*(Remplacez par la valeur **exacte** affichée sur votre écran RapidAPI.)*

---

## Étape 3 : Topic Tagging (Twinword)

1. Ouvrez [rapidapi.com/twinword/api/topic-tagging](https://rapidapi.com/twinword/api/topic-tagging).
2. **Pricing** → **Subscribe** (plan gratuit si disponible).
3. **Endpoints** → endpoint **GET** `/classify/` avec paramètre **`text`**.
4. Copiez **`X-RapidAPI-Host`**.

```env
RAPIDAPI_TOPIC_TAGGING_HOST=twinword-topic-tagging1.p.rapidapi.com
```

---

## Étape 4 : Resume Parser (au choix sur le marketplace)

1. Ouvrez la recherche [rapidapi.com/search/resume%20parser](https://rapidapi.com/search/resume%20parser).
2. Choisissez une API avec **upload fichier** (multipart, champ souvent nommé `file`) et un **plan gratuit**.
3. **Subscribe**, puis **Endpoints** :
   - copiez **`X-RapidAPI-Host`** ;
   - notez l’URL complète du **POST** : si ce n’est pas la racine `/`, renseignez le chemin.

```env
RAPIDAPI_RESUME_PARSER_HOST=votre-host.p.rapidapi.com
RAPIDAPI_RESUME_PARSER_PATH=
```

Exemple si l’URL est `https://xxx.p.rapidapi.com/api/resume` :

```env
RAPIDAPI_RESUME_PARSER_HOST=xxx.p.rapidapi.com
RAPIDAPI_RESUME_PARSER_PATH=/api/resume
```

Le backend envoie le CV en **multipart** avec le champ **`file`** (`backend/src/services/nlpRapidApi.js`). Si votre API attend un autre nom de champ, il faudra adapter le code ou choisir une API compatible.

---

## Récapitulatif `.env`

```env
RAPIDAPI_KEY=...
RAPIDAPI_SIMILARITY_HOST=...
RAPIDAPI_TOPIC_TAGGING_HOST=...
RAPIDAPI_RESUME_PARSER_HOST=...
RAPIDAPI_RESUME_PARSER_PATH=
# Optionnel : seuil matching (admin peut aussi le piloter)
# IA_SEUIL_MATCHING=40
```

Redémarrez le backend après modification : `npm run dev` (dossier `backend`).

---

## Admin : test de connexion des 3 APIs

1. Connectez-vous en **admin**.
2. Paramètres / IA (selon votre écran) → renseignez clé + hosts comme sur RapidAPI.
3. Lancez **Tester la connexion IA** (route qui appelle le test côté serveur).

Interprétation rapide :

- **Similarity OK** : l’API répond avec un score de test.
- **Parser OK** ou message du type **« API répond, URL test invalide — normal »** : le serveur a bien joint l’API ; l’URL de démo peut échouer tout en ayant une config correcte pour un **vrai fichier** uploadé par un candidat.
- **Topic Tagging** : OK ou message indiquant que l’API répond (selon les cas 200 / 404 / 422 gérés dans le test).

---

## Tester les **effets réels** dans la plateforme

Objectif : après activation des clés, chaque API doit se traduire par un **comportement observable** (UI ou données).

### API 1 — Text Similarity → **compte candidat**

| Étape | Action | Si ça a marché, vous voyez… |
|-------|--------|----------------------------|
| 1 | Remplir le **profil** (titre, à propos, compétences) et de préférence avoir **uploadé un CV** (pour enrichir le texte). | Profil cohérent avec le poste recherché. |
| 2 | Menu **Rechercher des offres** ou **Recommandations IA**. | Des **scores / badges de compatibilité** (pourcentage ou libellé type bon match) sur les offres, différents d’une simple liste sans score. |
| 3 | (Optionnel) Logs backend lors d’un calcul de score | Pas d’erreur répétée `RapidAPI Similarity` / timeout. |

**Interprétation :** sans clé ou sans host correct, le backend utilise une **similarité de secours** (mots communs) : les scores existent encore mais sont **moins « sémantiques »**. Avec Twinword activé, les scores tendent à mieux refléter le **sens** des textes.

---

### API 2 — Resume Parser → **compte candidat**

| Étape | Action | Si ça a marché, vous voyez… |
|-------|--------|----------------------------|
| 1 | **Mon Profil & CV** → uploader un **PDF ou DOCX** de CV. | Après traitement / rafraîchissement : **compétences** (ou champs) **enrichis** à partir du fichier, plutôt qu’une liste vide ou uniquement manuelle. |
| 2 | Logs backend | Lignes liées au parsing sans erreur **401/403** persistante sur l’API parser. |

**Interprétation :** le flux d’upload déclenche l’appel dans `cv` via `parseResumeWithApi` (`nlpRapidApi.js`).

---

### API 3 — Topic Tagging → **compte entreprise / recruteur**

| Étape | Action | Si ça a marché, vous voyez… |
|-------|--------|----------------------------|
| 1 | Créer ou **modifier une offre** avec une description riche (ex. *développeur Flutter, Dart, Firebase, REST, Git, Agile*). | Champ **compétences requises** (ou équivalent) **complété ou enrichi** avec des termes extraits du texte (selon l’écran recruteur / BDD). |
| 2 | Logs backend | Messages du type **`[IA/tagging]`** avec des mots-clés extraits, sans erreur bloquante. |

**Interprétation :** `extraireMotsCles` est appelé depuis les routes **offres** (création / mise à jour côté public ou recruteur). Sans Topic Tagging, un **fallback** par fréquence de mots est utilisé : l’offre fonctionne, mais l’enrichissement est **moins pertinent**.

---

### Synthèse « démo » côté candidat

- Menu **Démo IA & matching** (écran dédié dans l’app candidat) : rappel des 3 briques + bouton vers **Recommandations IA**.
- Enchaîner : **upload CV** → **recherche / recommandations** avec **scores** → côté recruteur **nouvelle offre** pour valider le **tagging**.

---

## Dépannage

| Problème | Piste |
|----------|--------|
| Admin rempli mais test IA KO ; `.env` avec la même clé → OK | Vérifier **`ENCRYPTION_KEY`** (≥ 16 car.) dans le `.env` du **serveur** qui exécute le backend. Ré-enregistrer la clé dans l’admin après avoir fixé `ENCRYPTION_KEY`, ou laisser la clé uniquement dans `RAPIDAPI_KEY` du `.env`. |
| 401 / 403 | Clé incorrecte ou **non abonné** au plan de **cette** API sur RapidAPI. |
| Host incorrect | Recopier **tel quel** `X-RapidAPI-Host` depuis **Endpoints**, sans `https://`. |
| Parser ne remplit rien | Vérifier `RAPIDAPI_RESUME_PARSER_PATH`, le champ fichier attendu par l’API, la taille / type PDF. |
| Similarité plate | Textes trop courts ; enrichir profil + description d’offre. |

---

## SMTP — emails transactionnels (100 % admin)

1. **Admin** → **Paramètres** → onglet **Notifications** : remplir **Hôte**, **Port** (souvent 587 TLS ou 465 SSL), **Email expéditeur**, **Mot de passe** (ex. mot de passe d’application Gmail), **Nom expéditeur**.
2. Activer **Activer l’envoi d’emails**, puis **Enregistrer**.
3. Cliquer **Tester SMTP (envoi)** : le backend exécute `verify()` puis envoie un message de test à **l’email du compte admin** connecté (API : `POST /api/admin/parametres/tester-smtp`, body optionnel `{ "destinataire": "..." }`).

**Comportement automatique** (sans toucher au `.env` pour le SMTP ; `ENCRYPTION_KEY` ≥ 16 car. reste requise pour le chiffrement du mot de passe en base) :

| Événement | Email si service SMTP actif |
|-----------|------------------------------|
| **Inscription** | Bienvenue (templates `template_bienvenue_*` ou texte par défaut) ; texte « attente validation » si validation manuelle activée. |
| **Admin valide le compte** | Message « compte validé » si l’option **Email de validation de compte** est activée. |
| **Admin rejette le compte** | Email à l’utilisateur si **Email compte rejeté** est activé (migration `023_notif_email_extensions.sql` + interrupteur admin). |
| **Candidat postule** | Email au **recruteur** si **Email à chaque candidature** ; email de **confirmation au candidat** si **Confirmation candidature** est activé. |
| **Messagerie** (candidat ↔ entreprise, ou contact talent) | Email au destinataire si **Email pour nouveaux messages** est activé (sauf si l’utilisateur a désactivé les emails de messages dans son profil). |
| **Modération offre** (admin) | Email au recruteur (validation / refus / mise en vedette) si **Email modération des offres** est activé. |
| **Alertes admin** | Email à chaque admin actif pour inscription à valider, offre en attente, signalement — si **Emails d’alerte aux administrateurs** est activé. |
| **Statut candidature** (examen, entretien, acceptée, refusée) | Email + notification in-app au **candidat** si **Email évolution candidature** est activé (recruteur via `/recruteur/candidatures` ou entreprise/admin via `PATCH /candidatures`). |
| **Candidat annule sa candidature** | Email + notification in-app au **recruteur** si **Email annulation candidature (recruteur)** est activé. |
| **Signalement traité / classé** | Email + notification in-app à l’**auteur du signalement** si **Email résolution signalement** est activé. |
| **Signalement — personne concernée** | Email + notification in-app au **propriétaire de l’offre**, du **profil** signalé ou au **candidat** (candidature) si **Email personne concernée** est activé — pas de doublon si signalant = concerné. |

Appliquer sur Supabase les migrations **`023_notif_email_extensions.sql`**, **`024_notif_email_statut_signalement_annulation.sql`**, **`025_notif_email_signalement_concerne.sql`** et **`026_signalements_note_admin.sql`** (colonne `note_admin`, message modération à la clôture).

Les **notifications in-app** (table `notifications`) sont aussi créées pour les évolutions de candidature et la clôture des signalements ; le SMTP **ajoute** l’envoi par email lorsque les interrupteurs admin le permettent.

---

## Liens utiles (copier-coller)

- Tableau de bord clés : [https://rapidapi.com/developer/dashboard](https://rapidapi.com/developer/dashboard)
- Text Similarity (Twinword) : [https://rapidapi.com/twinword/api/text-similarity](https://rapidapi.com/twinword/api/text-similarity)
- Topic Tagging (Twinword) : [https://rapidapi.com/twinword/api/topic-tagging](https://rapidapi.com/twinword/api/topic-tagging)
- Recherche Resume Parser : [https://rapidapi.com/search/resume%20parser](https://rapidapi.com/search/resume%20parser)

Une fois les trois APIs souscrites et les hosts alignés sur RapidAPI, enregistrez dans l’**admin** (le cache se rafraîchit tout seul) ou **redémarrez le backend** si vous ne modifiez que le fichier **`.env`**. Ensuite testez depuis l’**admin**, puis enchaînez les scénarios **candidat** et **recruteur** ci-dessus pour valider les effets visibles.
