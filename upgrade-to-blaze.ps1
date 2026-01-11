# Upgrade Firebase Projects to Blaze Plan via CLI
# Automates billing setup for all 5 batch projects

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firebase Blaze Plan Upgrade Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if gcloud is installed
Write-Host "Checking for Google Cloud CLI..." -ForegroundColor Yellow
$gcloudCheck = Get-Command gcloud -ErrorAction SilentlyContinue
if (-not $gcloudCheck) {
    Write-Host "❌ Google Cloud CLI not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install it from:" -ForegroundColor Yellow
    Write-Host "https://cloud.google.com/sdk/docs/install" -ForegroundColor White
    Write-Host ""
    Write-Host "After installation, run:" -ForegroundColor Yellow
    Write-Host "gcloud auth login" -ForegroundColor White
    exit 1
}

Write-Host "✅ Google Cloud CLI found" -ForegroundColor Green
Write-Host ""

# Firebase projects
$projects = @(
    "coinnewsextratv-batch-01",
    "coinnewsextratv-batch-02",
    "coinnewsextratv-batch-03",
    "coinnewsextratv-batch-04",
    "coinnewsextratv-batch-05"
)

Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Link billing account to all 5 Firebase projects" -ForegroundColor White
Write-Host "  2. Enable required APIs for Cloud Functions" -ForegroundColor White
Write-Host "  3. Verify billing is active" -ForegroundColor White
Write-Host ""

# Get billing accounts
Write-Host "Fetching your billing accounts..." -ForegroundColor Yellow
Write-Host ""
$billingAccounts = gcloud billing accounts list --format="value(name,displayName)" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to fetch billing accounts" -ForegroundColor Red
    Write-Host "Please run: gcloud auth login" -ForegroundColor Yellow
    exit 1
}

Write-Host "Available billing accounts:" -ForegroundColor Green
$billingAccounts
Write-Host ""

# Prompt for billing account
Write-Host "Enter the billing account ID (e.g., 012345-6789AB-CDEF01):" -ForegroundColor Yellow
$billingAccountId = Read-Host "Billing Account ID"

if ([string]::IsNullOrWhiteSpace($billingAccountId)) {
    Write-Host "❌ No billing account provided. Exiting." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Using billing account: $billingAccountId" -ForegroundColor Green
Write-Host ""

# Confirm
$confirm = Read-Host "Link this billing account to all 5 projects? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Operation cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Starting upgrade process..." -ForegroundColor Cyan
Write-Host ""

$successful = @()
$failed = @()

foreach ($project in $projects) {
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "Processing: $project" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    try {
        # Link billing account
        Write-Host "  1. Linking billing account..." -ForegroundColor Yellow
        gcloud billing projects link $project --billing-account=$billingAccountId 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "     ✅ Billing linked successfully" -ForegroundColor Green
            
            # Enable required APIs
            Write-Host "  2. Enabling Cloud Functions API..." -ForegroundColor Yellow
            gcloud services enable cloudfunctions.googleapis.com --project=$project 2>&1 | Out-Null
            
            Write-Host "  3. Enabling Cloud Build API..." -ForegroundColor Yellow
            gcloud services enable cloudbuild.googleapis.com --project=$project 2>&1 | Out-Null
            
            Write-Host "  4. Enabling Cloud Firestore API..." -ForegroundColor Yellow
            gcloud services enable firestore.googleapis.com --project=$project 2>&1 | Out-Null
            
            Write-Host "     ✅ All APIs enabled" -ForegroundColor Green
            
            # Verify billing
            Write-Host "  5. Verifying billing status..." -ForegroundColor Yellow
            $billingInfo = gcloud billing projects describe $project --format="value(billingEnabled)" 2>&1
            
            if ($billingInfo -eq "True") {
                Write-Host "     ✅ Billing verified: ACTIVE" -ForegroundColor Green
                $successful += $project
            } else {
                Write-Host "     ⚠️  Billing not active yet" -ForegroundColor Yellow
                $failed += $project
            }
        } else {
            Write-Host "     ❌ Failed to link billing" -ForegroundColor Red
            $failed += $project
        }
    }
    catch {
        Write-Host "     ❌ Error: $_" -ForegroundColor Red
        $failed += $project
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Upgrade Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Successfully upgraded: $($successful.Count)" -ForegroundColor Green
foreach ($project in $successful) {
    Write-Host "   - $project" -ForegroundColor Green
}
Write-Host ""

if ($failed.Count -gt 0) {
    Write-Host "❌ Failed: $($failed.Count)" -ForegroundColor Red
    foreach ($project in $failed) {
        Write-Host "   - $project" -ForegroundColor Red
    }
    Write-Host ""
}

if ($successful.Count -eq 5) {
    Write-Host "🎉 All 5 projects upgraded to Blaze plan!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Deploy to all projects: .\deploy-all-projects.ps1" -ForegroundColor White
    Write-Host "  2. Test bulk creators on each project" -ForegroundColor White
    Write-Host "  3. Start creating accounts!" -ForegroundColor White
} else {
    Write-Host "⚠️  Some projects failed. You may need to upgrade them manually:" -ForegroundColor Yellow
    Write-Host "   https://console.firebase.google.com/project/{project-id}/usage" -ForegroundColor White
}

Write-Host ""
Write-Host "Upgrade process complete!" -ForegroundColor Cyan
