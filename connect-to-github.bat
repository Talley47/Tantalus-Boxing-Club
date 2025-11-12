@echo off
REM 🚀 Connect Local Repository to GitHub
REM Run this script AFTER creating the repository on GitHub

echo.
echo 🚀 Connecting to GitHub...
echo.

REM IMPORTANT: Replace YOUR_USERNAME with your actual GitHub username
set GITHUB_USERNAME=Talley47
set REPO_NAME=tantalus-boxing-club

REM Check if remote already exists
git remote get-url origin >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  Remote 'origin' already exists!
    git remote get-url origin
    set /p overwrite="Do you want to update it? (y/n): "
    if /i "%overwrite%"=="y" (
        git remote remove origin
        echo ✅ Removed existing remote
    ) else (
        echo ❌ Cancelled. Please remove the remote manually.
        exit /b 1
    )
)

REM Add remote
echo.
echo 📡 Adding GitHub remote...
set remoteUrl=https://github.com/Talley47/%REPO_NAME%.git
git remote add origin %remoteUrl%

if %errorlevel% neq 0 (
    echo ❌ Failed to add remote
    exit /b 1
)
echo ✅ Remote added successfully!

REM Rename branch to main (if needed)
echo.
echo 🌿 Checking branch name...
git branch --show-current > temp_branch.txt
set /p currentBranch=<temp_branch.txt
del temp_branch.txt

if not "%currentBranch%"=="main" (
    echo Renaming branch from '%currentBranch%' to 'main'...
    git branch -M main
    echo ✅ Branch renamed to 'main'
) else (
    echo ✅ Already on 'main' branch
)

REM Push to GitHub
echo.
echo 📤 Pushing to GitHub...
echo You'll be prompted for GitHub credentials:
echo   - Username: Your GitHub username
echo   - Password: Use a Personal Access Token (NOT your password)
echo.
echo Get token from: https://github.com/settings/tokens
echo.

git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo 🎉 SUCCESS! Your code is now on GitHub!
    echo Visit: https://github.com/%GITHUB_USERNAME%/%REPO_NAME%
    echo.
    echo Next steps:
    echo 1. Verify your files are on GitHub
    echo 2. Deploy to Vercel (see VERCEL_DEPLOYMENT.md)
) else (
    echo.
    echo ❌ Push failed. Common issues:
    echo 1. Repository doesn't exist on GitHub - create it first!
    echo 2. Wrong username - check the script and update GITHUB_USERNAME
    echo 3. Authentication failed - use Personal Access Token, not password
    echo.
    echo Get help: https://docs.github.com/en/get-started/getting-started-with-git
)

pause

