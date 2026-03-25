# Active les hooks Git du dépôt (à exécuter une fois par clone)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

git config core.hooksPath .githooks
Write-Host "OK : core.hooksPath = .githooks" -ForegroundColor Green
Write-Host "Test : git commit (les hooks pre-commit / commit-msg seront actifs)." -ForegroundColor Cyan
