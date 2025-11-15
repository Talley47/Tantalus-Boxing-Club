@echo off
echo ========================================
echo   FIX ERRORS - SIMPLE VERSION
echo ========================================
echo.

echo Step 1: Stopping all Node.js processes...
taskkill /F /IM node.exe /FI "IMAGEPATH ne *Adobe*" 2>nul
timeout /t 2 /nobreak >nul
echo Done.
echo.

echo Step 2: Verifying .env.local file...
if exist .env.local (
    echo .env.local file exists
) else (
    echo Creating .env.local file...
    (
        echo REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
        echo REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
    ) > .env.local
    echo Created.
)
echo.

echo ========================================
echo   IMPORTANT: Clear Browser Cache NOW
echo ========================================
echo.
echo 1. Press Ctrl+Shift+Delete
echo 2. Select "All time"
echo 3. Check ALL boxes
echo 4. Click "Clear data"
echo 5. Close browser completely
echo.
pause

echo.
echo Step 3: Starting dev server...
echo.
echo After server starts:
echo - Wait for "Compiled successfully!"
echo - Open NEW browser window
echo - Go to http://localhost:3000
echo - Check console (F12) for Supabase check
echo.
npm start

