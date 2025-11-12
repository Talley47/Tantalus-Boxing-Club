# 🚨 Remove Exposed Secret from Git History
# Run this AFTER you've rotated the Supabase key

Write-Host "🚨 SECURITY: Removing exposed secret from Git history..." -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  WARNING: This will rewrite Git history!" -ForegroundColor Yellow
Write-Host "⚠️  Make sure you've rotated the Supabase key first!" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Have you rotated the Supabase Service Role Key? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "❌ Please rotate the key first, then run this script again." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔍 Removing secret from Git history..." -ForegroundColor Cyan

# Set environment variable to suppress warning
$env:FILTER_BRANCH_SQUELCH_WARNING = "1"

# Remove the secret from all commits
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch test-registration-flow.js test-real-registration.js test-admin-login.js check-users.js create-admin-proper.js ENV_TEMPLATE.txt SKIP_TO_NEXTJS.md CURRENT_STATUS.md" --prune-empty --tag-name-filter cat -- --all

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Secret removed from Git history!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📤 Pushing cleaned history to GitHub..." -ForegroundColor Cyan
    Write-Host "⚠️  This will force push and rewrite history on GitHub" -ForegroundColor Yellow
    
    $pushConfirm = Read-Host "Continue with force push? (yes/no)"
    if ($pushConfirm -eq "yes") {
        git push origin main --force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "🎉 SUCCESS! Secret removed from GitHub history!" -ForegroundColor Green
            Write-Host ""
            Write-Host "✅ Next steps:" -ForegroundColor Yellow
            Write-Host "1. Verify on GitHub: https://github.com/Talley47/Tantalus-Boxing-Club" -ForegroundColor White
            Write-Host "2. Search for the old key - it should NOT be found" -ForegroundColor White
            Write-Host "3. Set environment variables in Vercel" -ForegroundColor White
        } else {
            Write-Host ""
            Write-Host "❌ Push failed. Check your Git credentials." -ForegroundColor Red
        }
    } else {
        Write-Host ""
        Write-Host "⚠️  Push cancelled. Run 'git push origin main --force' manually when ready." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "❌ Failed to remove secret from history." -ForegroundColor Red
    Write-Host "Check the error message above." -ForegroundColor Yellow
}

