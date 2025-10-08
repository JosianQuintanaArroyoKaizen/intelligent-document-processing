# deploy.ps1 - Deploy UI changes to production
# Run this from the repo root directory

Write-Host "`n=== Starting UI Deployment ===" -ForegroundColor Cyan

# Configuration
$WEBUI_BUCKET = "idp-bedrock-webuibucket-ddd1a2zt4iti"
$DISTRIBUTION_ID = "E3B41LHG0OOI4W"
$UI_PATH = ".\src\ui"

# Check if we're in the right directory
if (-not (Test-Path $UI_PATH)) {
    Write-Host "ERROR: Cannot find src/ui directory. Please run this from the repo root." -ForegroundColor Red
    exit 1
}

# Step 1: Build
Write-Host "`n[1/3] Building React app..." -ForegroundColor Green
Push-Location $UI_PATH
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Step 2: Upload to S3
Write-Host "`n[2/3] Uploading to S3..." -ForegroundColor Green
aws s3 sync "$UI_PATH\build" "s3://$WEBUI_BUCKET" --delete
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: S3 upload failed!" -ForegroundColor Red
    exit 1
}

# Step 3: Invalidate CloudFront cache
Write-Host "`n[3/3] Invalidating CloudFront cache..." -ForegroundColor Green
$invalidation = aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*" | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CloudFront invalidation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Cyan
Write-Host "Invalidation ID: $($invalidation.Invalidation.Id)" -ForegroundColor Yellow
Write-Host "Status: $($invalidation.Invalidation.Status)" -ForegroundColor Yellow
Write-Host "`nYour changes will be live in 1-2 minutes at:" -ForegroundColor Green
Write-Host "https://d1vly2ykm54is7.cloudfront.net/`n" -ForegroundColor Cyan