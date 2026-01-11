# Multi-Project Firebase Deployment Script
# Deploys to all 5 batch account creation projects
# Usage: .\deploy-all-projects.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Multi-Project Firebase Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Array of Firebase project IDs
$projects = @(
    "coinnewsextratv-batch-01",
    "coinnewsextratv-batch-02",
    "coinnewsextratv-batch-03",
    "coinnewsextratv-batch-04",
    "coinnewsextratv-batch-05"
)

# Deployment options
$deployFunctions = $true
$deployHosting = $true
$deployFirestore = $true

# Color coding
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Yellow"

# Track results
$successful = @()
$failed = @()

Write-Host "Projects to deploy:" -ForegroundColor $infoColor
foreach ($project in $projects) {
    Write-Host "  - $project" -ForegroundColor White
}
Write-Host ""

# Confirm before deploying
$confirm = Read-Host "Deploy to all $($projects.Count) projects? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Deployment cancelled." -ForegroundColor $errorColor
    exit
}

Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Cyan
Write-Host ""

# Deploy to each project
$count = 0
foreach ($project in $projects) {
    $count++
    Write-Host "[$count/$($projects.Count)] Deploying to: $project" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    try {
        # Build deployment command
        $deployCmd = "firebase deploy --project $project"
        
        if ($deployFunctions -and $deployHosting -and $deployFirestore) {
            # Deploy everything
            $deployCmd += " --only functions,hosting,firestore"
        } else {
            $targets = @()
            if ($deployFunctions) { $targets += "functions" }
            if ($deployHosting) { $targets += "hosting" }
            if ($deployFirestore) { $targets += "firestore" }
            if ($targets.Count -gt 0) {
                $deployCmd += " --only " + ($targets -join ",")
            }
        }
        
        Write-Host "Executing: $deployCmd" -ForegroundColor Gray
        
        # Execute deployment
        Invoke-Expression $deployCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully deployed to $project" -ForegroundColor $successColor
            $successful += $project
        } else {
            Write-Host "❌ Failed to deploy to $project" -ForegroundColor $errorColor
            $failed += $project
        }
    }
    catch {
        Write-Host "❌ Error deploying to ${project}: $_" -ForegroundColor $errorColor
        $failed += $project
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Successful: $($successful.Count)" -ForegroundColor $successColor
foreach ($project in $successful) {
    Write-Host "   - $project" -ForegroundColor $successColor
}
Write-Host ""
Write-Host "❌ Failed: $($failed.Count)" -ForegroundColor $errorColor
foreach ($project in $failed) {
    Write-Host "   - $project" -ForegroundColor $errorColor
}
Write-Host ""

if ($failed.Count -eq 0) {
    Write-Host "🎉 All projects deployed successfully!" -ForegroundColor $successColor
    Write-Host ""
    Write-Host "Access your bulk creators at:" -ForegroundColor $infoColor
    foreach ($project in $projects) {
        $url = "https://$project.web.app/bulk-creator.html"
        Write-Host "  - $url" -ForegroundColor White
    }
} else {
    Write-Host "⚠️  Some projects failed to deploy. Check logs above." -ForegroundColor $errorColor
}

Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Cyan
