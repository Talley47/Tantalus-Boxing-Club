@echo off

REM This script helps you DISABLE RLS completely to remove all blocking.
REM It will open the SQL fix file and your Supabase dashboard automatically.

echo.
echo ==================================================================
echo ⚡ DISABLE RLS COMPLETELY - Fastest Fix
echo ==================================================================
echo.
echo This script will open two things for you:
echo 1. The SQL file: database\SINGLE-LINE-DISABLE-RLS.sql (ONE LINE - easiest to copy!)
echo 2. Your Supabase Project's SQL Editor in your web browser
echo.
echo ⚠️  IMPORTANT: This will COMPLETELY DISABLE RLS (removes all security).
echo    This is the FASTEST way to fix the blocking issue.
echo    You can re-enable RLS later using database\RE-ENABLE-RLS-PROPERLY.sql
echo.
echo Please follow these steps carefully:
echo.
echo STEP 1: When the SQL file opens, copy the ENTIRE line (it's all one line - Ctrl+A, Ctrl+C).
echo STEP 2: Go to the Supabase SQL Editor (which will open automatically).
echo         Click "New Query", paste the SQL (Ctrl+V), and click "Run".
echo STEP 3: After running the SQL, hard refresh your application (Ctrl+Shift+R).
echo.
echo Press any key to continue and open the files...
pause >nul

REM Define the path to the HTML helper page (EASIEST OPTION - has copy button!)
set "HTML_FILE=.\database\FIX-RLS-NOW.html"

REM Define the path to the SQL file (backup option)
set "SQL_FILE=.\database\SINGLE-LINE-DISABLE-RLS.sql"

REM Define the Supabase SQL Editor URL
REM IMPORTANT: Replace 'YOUR_PROJECT_REF' with your actual Supabase project reference.
REM You can find this in your Supabase dashboard URL:
REM https://supabase.com/dashboard/project/YOUR_PROJECT_REF/sql
set "SUPABASE_SQL_EDITOR_URL=https://supabase.com/dashboard/project/andmtvsqqomgwphotdwf/sql"

echo.
echo Opening HTML helper page (EASIEST - has copy button!): %HTML_FILE%
start "" "%HTML_FILE%"

echo Opening Supabase SQL Editor: %SUPABASE_SQL_EDITOR_URL%
start "" "%SUPABASE_SQL_EDITOR_URL%"

echo.
echo ==================================================================
echo ✅ Files opened! Now, follow the instructions in this window:
echo.
echo    1. Copy ALL content from the SQL file (Ctrl+A, Ctrl+C).
echo    2. In Supabase SQL Editor, click "New Query", paste (Ctrl+V), and "Run".
echo    3. Verify you see "Success" and "rls_enabled = false" in the results.
echo    4. Hard refresh your application (Ctrl+Shift+R).
echo.
echo ⚡ This COMPLETELY DISABLES RLS - fighters should appear immediately!
echo.
echo 💡 To re-enable RLS later (with proper policies), use:
echo    database\RE-ENABLE-RLS-PROPERLY.sql
echo.
echo This window will close automatically in 60 seconds.
timeout /t 60 /nobreak >nul
exit

