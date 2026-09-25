# v26.09.25-02
# Safety check: only deploy if this PC matches GitHub exactly.
Set-Location $PSScriptRoot

function Stop-Deploy($msg) {
  Write-Host ""
  Write-Host "DEPLOY STOPPED: $msg" -ForegroundColor Red
  Write-Host "Nothing was deployed." -ForegroundColor Red
  exit 1
}

Write-Host "Checking git..." -ForegroundColor Cyan
$changes = git status --porcelain
if ($LASTEXITCODE -ne 0) { Stop-Deploy "git status failed." }
if ($changes) {
  Write-Host "Uncommitted changes:" -ForegroundColor Yellow
  $changes | ForEach-Object { Write-Host "  $_" }
  Stop-Deploy "commit and push these first."
}

git fetch --quiet origin
if ($LASTEXITCODE -ne 0) { Stop-Deploy "could not reach GitHub (git fetch failed)." }
$behind = [int](git rev-list --count HEAD..origin/main)
$ahead  = [int](git rev-list --count origin/main..HEAD)
if ($behind -gt 0) { Stop-Deploy "GitHub has $behind newer commit(s) (probably from the other PC). Run: git pull" }
if ($ahead -gt 0)  { Stop-Deploy "$ahead commit(s) not pushed yet. Run: git push" }
Write-Host "Git OK - this PC matches GitHub." -ForegroundColor Green

Write-Host "Deploying main site..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\potterylandnyc.com"
wrangler deploy
if ($LASTEXITCODE -ne 0) { Set-Location $PSScriptRoot; Write-Host "MAIN SITE DEPLOY FAILED. Admin site was not deployed." -ForegroundColor Red; exit 1 }

Write-Host "Deploying admin site..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\admin.potterylandnyc.com"
wrangler deploy
if ($LASTEXITCODE -ne 0) { Set-Location $PSScriptRoot; Write-Host "ADMIN SITE DEPLOY FAILED. Main site WAS deployed." -ForegroundColor Red; exit 1 }

Set-Location $PSScriptRoot
Write-Host "Done. Both sites deployed." -ForegroundColor Green
