# v26.10.26-01
# Save (and deploy) in one go. Stops at the first error.
#   .\save.ps1 "what I changed"            -> save to GitHub, then deploy
#   .\save.ps1 "what I changed" -NoDeploy  -> save to GitHub only
param(
  [Parameter(Mandatory=$true)][string]$Message,
  [switch]$NoDeploy
)
Set-Location $PSScriptRoot
Write-Host "Computer: $env:COMPUTERNAME   Folder: $PSScriptRoot" -ForegroundColor Magenta

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
  # Nothing to save usually means an edit never reached this PC (e.g. Claude's write was overwritten).
  Fail "Nothing changed - the files may not have been saved to this PC. Ask Claude to check. (To deploy without new changes, use .\deploy.ps1)"
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
