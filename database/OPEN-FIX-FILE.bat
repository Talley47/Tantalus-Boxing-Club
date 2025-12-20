@echo off
REM =====================================================
REM QUICK FIX HELPER: Opens the SQL fix file
REM =====================================================

echo.
echo =====================================================
echo OPENING SQL FIX FILE
echo =====================================================
echo.
echo This will open: database\COPY-PASTE-THIS-NOW.sql
echo.
echo INSTRUCTIONS:
echo   1. Select ALL text in the file (Ctrl+A)
echo   2. Copy it (Ctrl+C)
echo   3. Go to: https://supabase.com/dashboard
echo   4. Select your project
echo   5. Click "SQL Editor" in left sidebar
echo   6. Click "New Query"
echo   7. Paste the SQL (Ctrl+V)
echo   8. Click "Run" (or press Ctrl+Enter)
echo   9. Verify: Should see "Success" and 2 policies listed
echo  10. Hard refresh your app (Ctrl+Shift+R)
echo.
echo =====================================================
echo.

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

REM Open the SQL file
start notepad "%SCRIPT_DIR%COPY-PASTE-THIS-NOW.sql"

REM Also open Supabase dashboard in browser
start https://supabase.com/dashboard

echo.
echo Files opened! Follow the instructions above.
echo.
pause

