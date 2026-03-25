# Workflow Git & sécurité — EmploiConnect

## Principes

1. **Ne jamais committer** `.env`, clés Supabase, RapidAPI, JWT réels.
2. **Branches** : `main` = stable ; développer sur `feature/nom` puis merge (PR) si équipe.
3. **Hooks** : vérifications automatiques avant commit (secrets, fichiers sensibles).

## Pourquoi pas de `git push` automatique après chaque commit ?

Un hook **post-commit** qui lance `git push` à chaque commit est **déconseillé** car :

- Risque de **boucles** ou d’échecs répétés (réseau, conflits).
- Vous pouvez pousser du **code non testé** ou des **secrets** par erreur.
- Les commits **WIP** (travail en cours) ne doivent pas toujours aller sur `origin`.

**Alternative pro** : commit local souvent ; push **manuel** ou script **`scripts/save-and-push.ps1`** quand une fonctionnalité est prête.

## Installation des hooks Git (une fois par clone)

```powershell
cd C:\Users\barry\OneDrive\Documents\PROJET_SOUTENNCE
git config core.hooksPath .githooks
```

Sous Git Bash / Linux :

```bash
chmod +x .githooks/pre-commit .githooks/commit-msg
```

## Messages de commit (Conventional Commits)

Format recommandé :

```
type(scope): description courte

Types: feat, fix, docs, chore, refactor, test
Exemples:
  feat(auth): ajout connexion JWT
  fix(offres): correction filtre statut
  chore: mise à jour .gitignore
```

Le hook `commit-msg` rejette les messages trop vagues (ex. seulement "update").

## Script push manuel « sauvegarde »

Quand vous voulez sauvegarder sur GitHub après un lot de travail :

```powershell
.\scripts\save-and-push.ps1
```

Ou classique :

```powershell
git add .
git status
git commit -m "feat(frontend): description claire"
git push origin main
```

## Si des secrets ont été commités par erreur

1. **Révoquer** les clés sur Supabase / RapidAPI (nouvelles clés).
2. Retirer le fichier de l’historique : `git filter-repo` ou support GitHub « Remove secret ».
3. Ne pas se contenter de `git rm` : l’historique garde les anciennes versions.
