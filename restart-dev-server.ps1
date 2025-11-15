# PowerShell script to restart dev server with proper setup
# Run this from the tantalus-boxing-club directory

Write-Host "🔄 Restarting Development Server..." -ForegroundColor Cyan
Write-Host ""

# Check if .env.local exists
$envFile = ".env.local"
if (-not (Test-Path $envFile)) {
    Write-Host "❌ ERROR: .env.local file not found!" -ForegroundColor Red
    Write-Host "Please create .env.local first using create-env-local.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ .env.local file found" -ForegroundColor Green

# Verify environment variables
Write-Host "🔍 Verifying environment variables..." -ForegroundColor Cyan
node verify-env-setup.js

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Environment variables are not configured correctly!" -ForegroundColor Red
    Write-Host "Please fix .env.local and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Make sure NO other 'npm start' processes are running" -ForegroundColor White
Write-Host "   2. Press Ctrl+C if you see a server running" -ForegroundColor White
Write-Host "   3. Clear your browser cache (Ctrl+Shift+Delete)" -ForegroundColor White
Write-Host "   4. Then run: npm start" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tip: Open a NEW terminal window and run 'npm start' there" -ForegroundColor Yellow
Write-Host ""

$start = Read-Host "Do you want to start the dev server now? (y/n)"
if ($start -eq "y" -or $start -eq "Y") {
    Write-Host ""
    Write-Host "🚀 Starting dev server..." -ForegroundColor Green
    Write-Host "⚠️  Make sure to clear browser cache after server starts!" -ForegroundColor Yellow
    Write-Host ""
    npm start
} else {
    Write-Host ""
    Write-Host "📝 To start manually, run: npm start" -ForegroundColor Cyan
}

