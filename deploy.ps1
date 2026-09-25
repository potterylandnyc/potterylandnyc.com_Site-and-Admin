Write-Host "Syncing shared styles.css into both sites..." -ForegroundColor Cyan
Copy-Item -Path "styles.css" -Destination "potterylandnyc.com\Public\styles.css" -Force
Copy-Item -Path "styles.css" -Destination "admin.potterylandnyc.com\Public\styles.css" -Force

Write-Host "Deploying main site..." -ForegroundColor Cyan
Set-Location "potterylandnyc.com"
wrangler deploy
Set-Location ..

Write-Host "Deploying admin site..." -ForegroundColor Cyan
Set-Location "admin.potterylandnyc.com"
wrangler deploy
Set-Location ..

Write-Host "Done. Both sites deployed." -ForegroundColor Green
