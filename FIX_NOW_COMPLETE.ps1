# Complete Fix Script - Run this to fix all errors
# Run from: C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club

Write-Host ""
Write-Host "🔧 TANTALUS BOXING CLUB - COMPLETE FIX" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify we're in the right directory
$expectedDir = "tantalus-boxing-club"
if (-not (Test-Path "package.json")) {
    Write-Host "❌ ERROR: package.json not found!" -ForegroundColor Red
    Write-Host "   Make sure you're in the tantalus-boxing-club directory" -ForegroundColor Yellow
    Write-Host "   Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ In correct directory: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Step 2: Verify .env.local exists and is correct
Write-Host "Step 1: Verifying .env.local file..." -ForegroundColor Yellow
if (-not (Test-Path ".env.local")) {
    Write-Host "❌ .env.local not found! Creating it now..." -ForegroundColor Red
    
    $envContent = "REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co`r`nREACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo"
    
    try {
        [System.IO.File]::WriteAllText("$PWD\.env.local", $envContent, [System.Text.Encoding]::UTF8)
        Write-Host "✅ Created .env.local file" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create .env.local: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ .env.local file exists" -ForegroundColor Green
    
    # Verify content
    $content = Get-Content .env.local -Raw
    if ($content -match "REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf" -and 
        $content -match "REACT_APP_SUPABASE_ANON_KEY=eyJ") {
        Write-Host "✅ File content is correct" -ForegroundColor Green
    } else {
        Write-Host "⚠️  File exists but content may be incorrect" -ForegroundColor Yellow
        Write-Host "   Recreating file..." -ForegroundColor Yellow
        
        $envContent = "REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co`r`nREACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo"
        [System.IO.File]::WriteAllText("$PWD\.env.local", $envContent, [System.Text.Encoding]::UTF8)
        Write-Host "✅ Recreated .env.local file" -ForegroundColor Green
    }
}

Write-Host ""

# Step 3: Stop all Node.js processes (except Adobe)
Write-Host "Step 2: Stopping all Node.js processes..." -ForegroundColor Yellow
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -notlike "*Adobe*" -and $_.Path -notlike "*Creative Cloud*"
}

if ($nodeProcesses) {
    Write-Host "   Found $($nodeProcesses.Count) Node.js process(es)" -ForegroundColor Yellow
    $nodeProcesses | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Write-Host "   ✅ Stopped process $($_.Id)" -ForegroundColor Green
        } catch {
            Write-Host "   ⚠️  Could not stop process $($_.Id)" -ForegroundColor Yellow
        }
    }
    Start-Sleep -Seconds 2
} else {
    Write-Host "✅ No Node.js processes running" -ForegroundColor Green
}

Write-Host ""

# Step 4: Clear instructions
Write-Host "Step 3: IMPORTANT - Follow these steps:" -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""
Write-Host "1. CLEAR BROWSER CACHE (CRITICAL):" -ForegroundColor White
Write-Host "   - Press Ctrl+Shift+Delete" -ForegroundColor Gray
Write-Host "   - Time range: 'All time'" -ForegroundColor Gray
Write-Host "   - Check: 'Cached images and files'" -ForegroundColor Gray
Write-Host "   - Check: 'Cookies and other site data'" -ForegroundColor Gray
Write-Host "   - Click 'Clear data'" -ForegroundColor Gray
Write-Host "   - CLOSE ALL browser windows" -ForegroundColor Gray
Write-Host ""
Write-Host "2. START DEV SERVER:" -ForegroundColor White
Write-Host "   Run this command in a NEW terminal:" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. WAIT FOR:" -ForegroundColor White
Write-Host "   - 'Compiled successfully!' message" -ForegroundColor Gray
Write-Host "   - Browser to open to http://localhost:3000" -ForegroundColor Gray
Write-Host ""
Write-Host "4. VERIFY:" -ForegroundColor White
Write-Host "   - Open browser console (F12)" -ForegroundColor Gray
Write-Host "   - Look for: '🔍 Supabase Configuration Check: ✅ Set'" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  CRITICAL: Access http://localhost:3000 (NOT file:// or build/)" -ForegroundColor Yellow
Write-Host ""

# Step 5: Ask if they want to start now
$start = Read-Host "Do you want to start the dev server now? (y/n)"
if ($start -eq "y" -or $start -eq "Y") {
    Write-Host ""
    Write-Host "🚀 Starting dev server..." -ForegroundColor Green
    Write-Host "⚠️  REMEMBER: Clear browser cache after it starts!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The server will open automatically. When it does:" -ForegroundColor Cyan
    Write-Host "1. Clear browser cache (Ctrl+Shift+Delete)" -ForegroundColor White
    Write-Host "2. Refresh the page (Ctrl+Shift+R)" -ForegroundColor White
    Write-Host ""
    
    npm start
} else {
    Write-Host ""
    Write-Host "📝 To start manually, run: npm start" -ForegroundColor Cyan
    Write-Host "   Make sure to clear browser cache first!" -ForegroundColor Yellow
    Write-Host ""
}

