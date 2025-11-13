# Remove Exposed Supabase Service Role Key from Git History
# Run this AFTER rotating the key in Supabase

Write-Host "🚨 SECURITY: Removing exposed service role key from Git history..." -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  IMPORTANT: Have you rotated the key in Supabase? (yes/no)" -ForegroundColor Yellow
$confirm = Read-Host

if ($confirm -ne "yes") {
    Write-Host "❌ Please rotate the key in Supabase first!" -ForegroundColor Red
    Write-Host "   Go to: https://supabase.com/dashboard → Settings → API → Reset service role key" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Removing UPDATE_ENV_LOCAL.md from Git history..." -ForegroundColor Yellow

# Set environment variable to suppress warnings
$env:FILTER_BRANCH_SQUELCH_WARNING = "1"

# Remove the file from all Git history
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch UPDATE_ENV_LOCAL.md" --prune-empty --tag-name-filter cat -- --all

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ File removed from Git history!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  Now force pushing to GitHub (this rewrites history)..." -ForegroundColor Yellow
    Write-Host "   This will update the remote repository." -ForegroundColor Yellow
    Write-Host ""
    
    $pushConfirm = Read-Host "Continue with force push? (yes/no)"
    if ($pushConfirm -eq "yes") {
        git push origin main --force
        Write-Host ""
        Write-Host "✅ Done! The exposed key has been removed from Git history." -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Next steps:" -ForegroundColor Cyan
        Write-Host "   1. Verify the key is rotated in Supabase" -ForegroundColor White
        Write-Host "   2. Update your .env.local file with the new key" -ForegroundColor White
        Write-Host "   3. Update Vercel environment variables" -ForegroundColor White
        Write-Host "   4. Test your application" -ForegroundColor White
    } else {
        Write-Host "⚠️  Force push cancelled. Run 'git push origin main --force' manually when ready." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Error removing file from Git history" -ForegroundColor Red
    exit 1
}

