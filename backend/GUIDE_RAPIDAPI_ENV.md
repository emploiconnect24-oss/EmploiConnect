# Guide : Obtenir les clés RapidAPI et remplir le fichier .env

Ce guide vous permet d’obtenir **étape par étape** les valeurs à mettre dans le fichier `backend/.env` pour activer le NLP (analyse de CV et score de compatibilité).

---

## Étape 0 : Créer un compte RapidAPI

1. Allez sur **https://rapidapi.com**
2. Cliquez sur **Sign Up** (ou **Log In** si vous avez déjà un compte)
3. Inscrivez-vous (email, Google, GitHub, etc.)
4. Une fois connecté, vous avez **une clé API** valable pour toutes les APIs auxquelles vous vous abonnez

---

## Étape 1 : Récupérer votre clé API (RAPIDAPI_KEY)

Cette clé est **la même** pour toutes les APIs RapidAPI que vous utilisez.

1. Allez sur **https://rapidapi.com/developer/dashboard**
2. Dans la page **Dashboard**, repérez la section **Apps** (ou **Applications**)
3. Cliquez sur votre application par défaut (ou créez-en une : **Create App** → donnez un nom, ex. "EmploiConnect")
4. Ouvrez l’onglet **Security** (ou **API Keys**)
5. Vous voyez une clé du type : `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8`
6. **Copiez cette clé**

Dans votre fichier **`backend/.env`**, collez-la sur la ligne `RAPIDAPI_KEY=` :

```env
RAPIDAPI_KEY=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8
```

*(Remplacez par votre vraie clé.)*

---

## Étape 2 : API Text Similarity (score de compatibilité)

Cette API sert à calculer la **similarité sémantique** entre le CV du candidat et l’offre d’emploi.

### 2.1 Aller sur l’API

1. Ouvrez : **https://rapidapi.com/twinword/api/text-similarity**
2. Si une autre API "Text Similarity" vous convient sur RapidAPI, vous pouvez l’utiliser à la place (il faudra alors adapter le **Host** dans le .env)

### 2.2 S’abonner (plan gratuit)

1. Cliquez sur l’onglet **Pricing**
2. Choisissez le plan **Basic** (gratuit, souvent 9 000 requêtes/mois)
3. Cliquez sur **Subscribe**
4. Validez

### 2.3 Récupérer le Host

1. Restez sur la page de l’API
2. Allez dans l’onglet **Endpoints** (ou **Code Snippets**)
3. Sélectionnez l’endpoint qui compare deux textes (souvent **GET** avec `text1` et `text2`)
4. Dans l’exemple de requête (ou dans l’onglet **Headers**), vous voyez :
   - **X-RapidAPI-Host** : une valeur du type `twinword-text-similarity.p.rapidapi.com`
5. **Copiez cette valeur** (uniquement le host, sans `https://`)

Dans **`backend/.env`** :

```env
RAPIDAPI_SIMILARITY_HOST=twinword-text-similarity.p.rapidapi.com
```

*(Si votre API affiche un host différent, mettez exactement celui indiqué.)*

---

## Étape 3 : API Resume Parser (extraction du CV)

Cette API permet d’extraire **compétences, expérience, formation** depuis un fichier CV (PDF/DOCX).

### 3.1 Trouver une API Resume Parser sur RapidAPI

1. Allez sur **https://rapidapi.com**
2. Dans la barre de recherche, tapez : **resume parser** ou **CV parser**
3. Choisissez une API qui propose un **plan gratuit** (ex. "Resume Parser API", "Resume Parser", etc.)
4. Exemples de liens possibles (les noms peuvent changer) :
   - https://rapidapi.com/hiteshw02/api/resumeparser1
   - https://rapidapi.com/elcaiseri-elcaiseri-default/api/resume-parser-api2
   - Ou toute autre API dont la description indique "parse resume", "extract skills from CV", etc.

### 3.2 S’abonner (plan gratuit)

1. Sur la page de l’API, ouvrez l’onglet **Pricing**
2. Sélectionnez le plan **gratuit** (souvent limité en nombre de requêtes par jour/mois)
3. Cliquez sur **Subscribe**

### 3.3 Récupérer le Host et le chemin (Path)

1. Allez dans l’onglet **Endpoints** (ou **Code Snippets**)
2. Repérez l’endpoint qui permet d’**envoyer un fichier** (souvent **POST** avec un formulaire multipart)
3. Dans les **Headers** ou dans l’exemple de code, notez :
   - **X-RapidAPI-Host** : par ex. `resumeparser-api.p.rapidapi.com` ou `resume-parser-api2.p.rapidapi.com`
   - L’**URL** de l’endpoint : par ex. `https://resumeparser-api.p.rapidapi.com/` ou `https://xxx.p.rapidapi.com/api/resume`
4. **Host** : copiez la partie "host" (sans `https://` et sans chemin), ex. `resumeparser-api.p.rapidapi.com`
5. **Path** : si l’URL se termine par un chemin (ex. `/api/resume`), c’est le **path**. Sinon laissez vide.

Dans **`backend/.env`** :

```env
RAPIDAPI_RESUME_PARSER_HOST=resumeparser-api.p.rapidapi.com
RAPIDAPI_RESUME_PARSER_PATH=
```

Si l’API utilise par exemple `https://xxx.p.rapidapi.com/api/resume` :

```env
RAPIDAPI_RESUME_PARSER_HOST=xxx.p.rapidapi.com
RAPIDAPI_RESUME_PARSER_PATH=/api/resume
```

*(Adaptez selon exactement ce que l’interface RapidAPI vous affiche.)*

---

## Récapitulatif : à quoi doit ressembler votre .env

À la fin, la partie RapidAPI de votre fichier **`backend/.env`** peut ressembler à ceci (avec **vos** valeurs) :

```env
# Clé unique (Dashboard RapidAPI → App → Security)
RAPIDAPI_KEY=votre_cle_longue_ici

# Host de l’API Text Similarity (onglet Endpoints de l’API)
RAPIDAPI_SIMILARITY_HOST=twinword-text-similarity.p.rapidapi.com

# Host de l’API Resume Parser (onglet Endpoints de l’API)
RAPIDAPI_RESUME_PARSER_HOST=resumeparser-api.p.rapidapi.com

# Chemin de l’endpoint Resume Parser (souvent vide ou /api/resume)
RAPIDAPI_RESUME_PARSER_PATH=
```

- **RAPIDAPI_KEY** : obligatoire pour activer le NLP ; une seule clé pour tout.
- **RAPIDAPI_SIMILARITY_HOST** : obligatoire si vous utilisez la similarité texte.
- **RAPIDAPI_RESUME_PARSER_HOST** : obligatoire si vous utilisez le parsing de CV.
- **RAPIDAPI_RESUME_PARSER_PATH** : à remplir seulement si l’URL de l’API contient un chemin (ex. `/api/resume`).

---

## Vérification

1. Enregistrez le fichier **`.env`**
2. Redémarrez le serveur backend : `npm run dev` (dans le dossier `backend`)
3. Uploadez un CV : si la clé et les hosts sont corrects, les compétences peuvent être enrichies par l’API Resume Parser
4. Postulez à une offre ou consultez les suggestions d’offres : le score utilise l’API Text Similarity si elle est configurée

Si une API renvoie une erreur (401, 403, 404), vérifiez :
- que vous êtes bien **abonné** au plan gratuit de cette API ;
- que le **Host** (et le **Path** pour le Resume Parser) correspondent **exactement** à ce qui est affiché sur la page RapidAPI de l’endpoint.

---

## Liens utiles

| Étape              | Lien |
|--------------------|------|
| Compte & clé API   | https://rapidapi.com/developer/dashboard |
| Text Similarity    | https://rapidapi.com/twinword/api/text-similarity |
| Recherche Resume Parser | https://rapidapi.com → rechercher "resume parser" |

Une fois ces valeurs correctement remplacées dans le fichier `.env`, le projet utilisera le NLP RapidAPI pour un comportement plus pertinent.
