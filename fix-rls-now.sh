#!/bin/bash
# RLS Fix Helper Script for Mac/Linux
# This script opens the SQL file and provides instructions

echo ""
echo "================================================================================"
echo "  RLS FIX HELPER - Follow These Simple Steps"
echo "================================================================================"
echo ""
echo "This will open the SQL file you need to copy."
echo ""
read -p "Press Enter to continue..."

# Open the SQL file in default text editor
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "database/COPY-PASTE-THIS-NOW.sql"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open "database/COPY-PASTE-THIS-NOW.sql" 2>/dev/null || \
    gedit "database/COPY-PASTE-THIS-NOW.sql" 2>/dev/null || \
    nano "database/COPY-PASTE-THIS-NOW.sql"
else
    echo "Please manually open: database/COPY-PASTE-THIS-NOW.sql"
fi

echo ""
echo "================================================================================"
echo "  STEP-BY-STEP INSTRUCTIONS"
echo "================================================================================"
echo ""
echo "The SQL file should now be open in your text editor."
echo ""
echo "STEP 1: Select ALL text in the file (Ctrl+A or Cmd+A)"
echo "STEP 2: Copy it (Ctrl+C or Cmd+C)"
echo ""
echo "STEP 3: Go to Supabase Dashboard:"
echo "        https://supabase.com/dashboard"
echo ""
echo "STEP 4: In Supabase Dashboard:"
echo "        - Select your project"
echo "        - Click 'SQL Editor' (left sidebar)"
echo "        - Click 'New Query'"
echo "        - Paste the SQL (Ctrl+V or Cmd+V)"
echo "        - Click 'Run' button (or press Ctrl+Enter)"
echo ""
echo "STEP 5: Verify success:"
echo "        - Should see 'Success' message"
echo "        - Results should show 2 policies listed"
echo ""
echo "STEP 6: Refresh your app:"
echo "        - Hard refresh: Ctrl+Shift+R (Linux) or Cmd+Shift+R (Mac)"
echo ""
echo "================================================================================"
echo ""
read -p "Press Enter to exit..."

