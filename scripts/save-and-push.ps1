# Sauvegarde manuelle sur GitHub (à lancer quand une fonctionnalité est prête)
# Usage : .\scripts\save-and-push.ps1 -Message "feat(offres): liste paginee"
param(
  [Parameter(Mandatory = $true)]
  [string] $Message
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

git add -A
git status
$confirm = Read-Host "Valider ce commit et pousser vers origin ? (o/N)"
if ($confirm -ne "o" -and $confirm -ne "O") {
  Write-Host "Annulé." -ForegroundColor Yellow
  exit 0
}

git commit -m $Message
if ($LASTEXITCODE -ne 0) {
  Write-Host "Commit annulé ou échoué (rien à committer ?)." -ForegroundColor Red
  exit $LASTEXITCODE
}

$branch = git rev-parse --abbrev-ref HEAD
git push origin $branch
Write-Host "Push terminé vers origin/$branch" -ForegroundColor Green
