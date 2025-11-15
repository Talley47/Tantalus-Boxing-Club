# Comprehensive diagnostic and fix script
# Run this from the tantalus-boxing-club directory

Write-Host "🔍 Tantalus Boxing Club - Environment Diagnostic" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if .env.local exists
Write-Host "Step 1: Checking .env.local file..." -ForegroundColor Yellow
$envFile = ".env.local"

if (-not (Test-Path $envFile)) {
    Write-Host "❌ .env.local file NOT FOUND!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Creating .env.local file now..." -ForegroundColor Yellow
    
    $envContent = @"
REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
"@
    
    try {
        $envContent | Out-File -FilePath $envFile -Encoding utf8 -NoNewline
        Write-Host "✅ Created .env.local file!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create .env.local: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ .env.local file exists" -ForegroundColor Green
    
    # Verify content
    $content = Get-Content $envFile -Raw
    if ($content -match "REACT_APP_SUPABASE_URL" -and $content -match "REACT_APP_SUPABASE_ANON_KEY") {
        Write-Host "✅ File contains required variables" -ForegroundColor Green
    } else {
        Write-Host "⚠️  File exists but may be missing variables" -ForegroundColor Yellow
    }
}

Write-Host ""

# Step 2: Check for running Node processes
Write-Host "Step 2: Checking for running Node processes..." -ForegroundColor Yellow
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -notlike "*Adobe*" -and $_.Path -notlike "*Creative Cloud*"
}

if ($nodeProcesses) {
    Write-Host "⚠️  Found $($nodeProcesses.Count) Node.js process(es) running" -ForegroundColor Yellow
    Write-Host "   These might be your dev server. You should stop them before restarting." -ForegroundColor Yellow
    Write-Host ""
    $stop = Read-Host "Do you want to stop all Node.js processes? (y/n)"
    if ($stop -eq "y" -or $stop -eq "Y") {
        $nodeProcesses | Stop-Process -Force
        Write-Host "✅ Stopped all Node.js processes" -ForegroundColor Green
    }
} else {
    Write-Host "✅ No Node.js processes running" -ForegroundColor Green
}

Write-Host ""

# Step 3: Verify environment file
Write-Host "Step 3: Verifying environment variables..." -ForegroundColor Yellow
node verify-env-setup.js

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Environment variables are not configured correctly!" -ForegroundColor Red
    Write-Host "Please check the .env.local file and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 4: Instructions
Write-Host "Step 4: Next Steps" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 IMPORTANT: Follow these steps EXACTLY:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. CLEAR BROWSER CACHE:" -ForegroundColor White
Write-Host "   - Press Ctrl+Shift+Delete" -ForegroundColor Gray
Write-Host "   - Select 'All time'" -ForegroundColor Gray
Write-Host "   - Check 'Cached images and files'" -ForegroundColor Gray
Write-Host "   - Click 'Clear data'" -ForegroundColor Gray
Write-Host "   - Close ALL browser windows" -ForegroundColor Gray
Write-Host ""
Write-Host "2. START DEV SERVER:" -ForegroundColor White
Write-Host "   - Open a NEW terminal/PowerShell window" -ForegroundColor Gray
Write-Host "   - Run: cd $PWD" -ForegroundColor Gray
Write-Host "   - Run: npm start" -ForegroundColor Gray
Write-Host "   - Wait for 'Compiled successfully!' message" -ForegroundColor Gray
Write-Host ""
Write-Host "3. VERIFY:" -ForegroundColor White
Write-Host "   - Browser should open to http://localhost:3000" -ForegroundColor Gray
Write-Host "   - Open console (F12)" -ForegroundColor Gray
Write-Host "   - Look for: '🔍 Supabase Configuration Check: ✅ Set'" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  CRITICAL: Make sure you're accessing http://localhost:3000" -ForegroundColor Yellow
Write-Host "   NOT file:// or a build folder!" -ForegroundColor Yellow
Write-Host ""

$startNow = Read-Host "Do you want to start the dev server now? (y/n)"
if ($startNow -eq "y" -or $startNow -eq "Y") {
    Write-Host ""
    Write-Host "🚀 Starting dev server..." -ForegroundColor Green
    Write-Host "⚠️  Remember to clear browser cache after it starts!" -ForegroundColor Yellow
    Write-Host ""
    npm start
} else {
    Write-Host ""
    Write-Host "📝 To start manually, run: npm start" -ForegroundColor Cyan
    Write-Host "   Make sure to clear browser cache first!" -ForegroundColor Yellow
}

