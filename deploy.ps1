# Firebase Deployment Script
Write-Host "Starting Firebase Deployment..." -ForegroundColor Green

# Set Firebase project
Write-Host "Setting Firebase project..." -ForegroundColor Yellow
firebase use coinnewsextratv-9c75a

# Install functions dependencies
Write-Host "Installing Functions dependencies..." -ForegroundColor Yellow
Set-Location functions
npm install
Set-Location ..

# Deploy Firestore rules
Write-Host "Deploying Firestore rules..." -ForegroundColor Yellow
firebase deploy --only firestore:rules

# Deploy Functions
Write-Host "Deploying Firebase Functions..." -ForegroundColor Yellow
firebase deploy --only functions

Write-Host "Deployment completed!" -ForegroundColor Green
