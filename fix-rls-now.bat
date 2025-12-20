@echo off
REM RLS Fix Helper Script for Windows
REM This script opens the SQL file and provides instructions

echo.
echo ================================================================================
echo   RLS FIX HELPER - Follow These Simple Steps
echo ================================================================================
echo.
echo This will open the SQL file you need to copy.
echo.
pause

REM Open the SQL file in default text editor
start "" "database\COPY-PASTE-THIS-NOW.sql"

echo.
echo ================================================================================
echo   STEP-BY-STEP INSTRUCTIONS
echo ================================================================================
echo.
echo The SQL file should now be open in your text editor.
echo.
echo STEP 1: Select ALL text in the file (Ctrl+A)
echo STEP 2: Copy it (Ctrl+C)
echo.
echo STEP 3: Go to Supabase Dashboard:
echo         https://supabase.com/dashboard
echo.
echo STEP 4: In Supabase Dashboard:
echo         - Select your project
echo         - Click "SQL Editor" (left sidebar)
echo         - Click "New Query"
echo         - Paste the SQL (Ctrl+V)
echo         - Click "Run" button (or press Ctrl+Enter)
echo.
echo STEP 5: Verify success:
echo         - Should see "Success" message
echo         - Results should show 2 policies listed
echo.
echo STEP 6: Refresh your app:
echo         - Hard refresh: Ctrl+Shift+R
echo.
echo ================================================================================
echo.
pause

