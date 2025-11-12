# 🚀 Connect Local Repository to GitHub
# Run this script AFTER creating the repository on GitHub

# IMPORTANT: Replace YOUR_USERNAME with your actual GitHub username
$GITHUB_USERNAME = "YOUR_USERNAME"
$REPO_NAME = "tantalus-boxing-club"

Write-Host "🚀 Connecting to GitHub..." -ForegroundColor Cyan
Write-Host ""

# Check if remote already exists
$remoteExists = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  Remote 'origin' already exists!" -ForegroundColor Yellow
    Write-Host "Current remote URL: $remoteExists" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to update it? (y/n)"
    if ($overwrite -eq "y" -or $overwrite -eq "Y") {
        git remote remove origin
        Write-Host "✅ Removed existing remote" -ForegroundColor Green
    } else {
        Write-Host "❌ Cancelled. Please remove the remote manually or use a different name." -ForegroundColor Red
        exit 1
    }
}

# Add remote
Write-Host "📡 Adding GitHub remote..." -ForegroundColor Cyan
$remoteUrl = "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
git remote add origin $remoteUrl

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Remote added successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to add remote" -ForegroundColor Red
    exit 1
}

# Rename branch to main (if needed)
Write-Host ""
Write-Host "🌿 Checking branch name..." -ForegroundColor Cyan
$currentBranch = git branch --show-current
if ($currentBranch -ne "main") {
    Write-Host "Renaming branch from '$currentBranch' to 'main'..." -ForegroundColor Yellow
    git branch -M main
    Write-Host "✅ Branch renamed to 'main'" -ForegroundColor Green
} else {
    Write-Host "✅ Already on 'main' branch" -ForegroundColor Green
}

# Push to GitHub
Write-Host ""
Write-Host "📤 Pushing to GitHub..." -ForegroundColor Cyan
Write-Host "You'll be prompted for GitHub credentials:" -ForegroundColor Yellow
Write-Host "  - Username: Your GitHub username" -ForegroundColor Yellow
Write-Host "  - Password: Use a Personal Access Token (NOT your password)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Get token from: https://github.com/settings/tokens" -ForegroundColor Cyan
Write-Host ""

git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "🎉 SUCCESS! Your code is now on GitHub!" -ForegroundColor Green
    Write-Host "Visit: https://github.com/$GITHUB_USERNAME/$REPO_NAME" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Verify your files are on GitHub" -ForegroundColor White
    Write-Host "2. Deploy to Vercel (see VERCEL_DEPLOYMENT.md)" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Push failed. Common issues:" -ForegroundColor Red
    Write-Host "1. Repository doesn't exist on GitHub - create it first!" -ForegroundColor Yellow
    Write-Host "2. Wrong username - check the script and update GITHUB_USERNAME" -ForegroundColor Yellow
    Write-Host "3. Authentication failed - use Personal Access Token, not password" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Get help: https://docs.github.com/en/get-started/getting-started-with-git" -ForegroundColor Cyan
}

