@echo off
REM Batch script to create .env.local file
REM Run this from the tantalus-boxing-club directory

echo Creating .env.local file...

(
echo # Supabase Configuration
echo # These values are required for the app to connect to Supabase
echo.
echo REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
echo REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
) > .env.local

if exist .env.local (
    echo.
    echo ✅ Created .env.local successfully!
    echo.
    echo 📋 Next steps:
    echo    1. Restart your development server (Ctrl+C then npm start)
    echo    2. Refresh your browser
    echo    3. The error should be gone!
) else (
    echo.
    echo ❌ Error creating .env.local
    echo.
    echo 💡 Manual creation:
    echo    Create a file named '.env.local' in this directory with:
    echo    REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
    echo    REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
)

pause

