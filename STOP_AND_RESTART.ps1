# Complete Stop and Restart Script
# This will stop everything and guide you through a clean restart

Write-Host ""
Write-Host "🛑 STOPPING ALL PROCESSES AND CLEARING CACHE" -ForegroundColor Red
Write-Host "=" * 70 -ForegroundColor Red
Write-Host ""

# Step 1: Stop all Node.js processes
Write-Host "Step 1: Stopping all Node.js processes..." -ForegroundColor Yellow
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
    Start-Sleep -Seconds 3
    Write-Host "   ✅ All Node.js processes stopped" -ForegroundColor Green
} else {
    Write-Host "   ✅ No Node.js processes running" -ForegroundColor Green
}

Write-Host ""

# Step 2: Verify .env.local
Write-Host "Step 2: Verifying .env.local file..." -ForegroundColor Yellow
if (Test-Path ".env.local") {
    $content = Get-Content .env.local -Raw
    if ($content -match "REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf" -and 
        $content -match "REACT_APP_SUPABASE_ANON_KEY=eyJ") {
        Write-Host "   ✅ .env.local file exists and is correct" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  .env.local exists but content may be incorrect" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ .env.local file NOT FOUND!" -ForegroundColor Red
    Write-Host "   Creating it now..." -ForegroundColor Yellow
    
    $envContent = "REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co`r`nREACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo"
    
    try {
        [System.IO.File]::WriteAllText("$PWD\.env.local", $envContent, [System.Text.Encoding]::UTF8)
        Write-Host "   ✅ Created .env.local file" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Failed to create .env.local: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 3: Instructions
Write-Host "Step 3: CRITICAL - Clear Browser Cache" -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  BEFORE starting the server, you MUST clear browser cache:" -ForegroundColor Red
Write-Host ""
Write-Host "1. Close ALL browser tabs/windows with your app" -ForegroundColor White
Write-Host "2. Press Ctrl+Shift+Delete" -ForegroundColor White
Write-Host "3. Time range: 'All time'" -ForegroundColor White
Write-Host "4. Check ALL boxes:" -ForegroundColor White
Write-Host "   - Browsing history" -ForegroundColor Gray
Write-Host "   - Cookies and other site data" -ForegroundColor Gray
Write-Host "   - Cached images and files" -ForegroundColor Gray
Write-Host "   - Hosted app data" -ForegroundColor Gray
Write-Host "   - Service workers" -ForegroundColor Gray
Write-Host "5. Click 'Clear data'" -ForegroundColor White
Write-Host "6. Close browser completely" -ForegroundColor White
Write-Host ""

# Step 4: Ask to continue
$continue = Read-Host "Have you cleared the browser cache? (y/n)"
if ($continue -ne "y" -and $continue -ne "Y") {
    Write-Host ""
    Write-Host "⚠️  Please clear browser cache first, then run this script again" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Step 4: Starting dev server..." -ForegroundColor Yellow
Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Starting npm start..." -ForegroundColor Green
Write-Host ""
Write-Host "After the server starts:" -ForegroundColor Cyan
Write-Host "1. Wait for 'Compiled successfully!' message" -ForegroundColor White
Write-Host "2. Open a NEW browser window (not the auto-opened one)" -ForegroundColor White
Write-Host "3. Navigate to: http://localhost:3000" -ForegroundColor White
Write-Host "4. Open console (F12) and verify you see:" -ForegroundColor White
Write-Host "   🔍 Supabase Configuration Check: ✅ Set" -ForegroundColor Gray
Write-Host ""

# Start the server
npm start

