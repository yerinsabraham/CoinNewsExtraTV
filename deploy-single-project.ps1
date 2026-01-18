# Single Project Firebase Deployment Script
# Usage: .\deploy-single-project.ps1 -ProjectNumber 1

param(
    [Parameter(Mandatory=$true)]
    [ValidateRange(1,5)]
    [int]$ProjectNumber
)

$projectId = "coinnewsextratv-batch-0$ProjectNumber"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying to: $projectId" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Confirm
$confirm = Read-Host "Deploy to $projectId? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Deployment cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Deploying..." -ForegroundColor Yellow

# Deploy
firebase deploy --project $projectId --only functions,hosting,firestore

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access bulk creator at:" -ForegroundColor Yellow
    Write-Host "https://$projectId.web.app/bulk-creator.html" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
}
