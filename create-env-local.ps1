# PowerShell script to create .env.local file
# Run this from the tantalus-boxing-club directory

$envContent = @"
# Supabase Configuration
# These values are required for the app to connect to Supabase

REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
"@

$envFile = ".env.local"

if (Test-Path $envFile) {
    Write-Host "⚠️  .env.local already exists!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "❌ Cancelled. File not modified." -ForegroundColor Red
        exit
    }
}

try {
    $envContent | Out-File -FilePath $envFile -Encoding utf8 -NoNewline
    Write-Host "✅ Created .env.local successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Restart your development server (Ctrl+C then npm start)" -ForegroundColor White
    Write-Host "   2. Refresh your browser" -ForegroundColor White
    Write-Host "   3. The error should be gone!" -ForegroundColor White
} catch {
    Write-Host "❌ Error creating .env.local: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Manual creation:" -ForegroundColor Yellow
    Write-Host "   Create a file named '.env.local' in this directory with:" -ForegroundColor White
    Write-Host "   REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co" -ForegroundColor Gray
    Write-Host "   REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." -ForegroundColor Gray
}

