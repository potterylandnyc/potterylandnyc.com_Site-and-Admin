Write-Host "Deploying main site..." -ForegroundColor Cyan
Set-Location "potterylandnyc.com"
wrangler deploy
Set-Location ..

Write-Host "Deploying admin site..." -ForegroundColor Cyan
Set-Location "admin.potterylandnyc.com"
wrangler deploy
Set-Location ..

Write-Host "Done. Both sites deployed." -ForegroundColor Green
