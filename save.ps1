# v26.09.25-01
# Save (and deploy) in one go. Stops at the first error.
#   .\save.ps1 "what I changed"            -> save to GitHub, then deploy
#   .\save.ps1 "what I changed" -NoDeploy  -> save to GitHub only
param(
  [Parameter(Mandatory=$true)][string]$Message,
  [switch]$NoDeploy
)
Set-Location $PSScriptRoot

function Fail($msg) {
  Write-Host ""
  Write-Host "STOPPED: $msg" -ForegroundColor Red
  Write-Host "Nothing was deployed." -ForegroundColor Red
  exit 1
}

Write-Host "Saving changes..." -ForegroundColor Cyan
git add -A
if ($LASTEXITCODE -ne 0) { Fail "git add failed." }
$staged = git diff --cached --name-only
if ($staged) {
  git commit -m $Message
  if ($LASTEXITCODE -ne 0) { Fail "git commit failed." }
} else {
  Write-Host "No new changes to commit." -ForegroundColor Yellow
}

Write-Host "Getting latest from GitHub..." -ForegroundColor Cyan
git pull --no-edit
if ($LASTEXITCODE -ne 0) { Fail "git pull failed (probably a conflict between the two PCs). Ask Claude for help before doing anything else." }

Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
git push
if ($LASTEXITCODE -ne 0) { Fail "git push failed." }
Write-Host "Saved to GitHub." -ForegroundColor Green

if ($NoDeploy) {
  Write-Host "Not deploying (-NoDeploy was used)." -ForegroundColor Yellow
  exit 0
}

Write-Host ""
& "$PSScriptRoot\deploy.ps1"
exit $LASTEXITCODE
