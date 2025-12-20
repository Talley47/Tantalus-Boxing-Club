# RLS Fix for fighter_profiles Table

## Problem
Your app is returning 0 rows from `fighter_profiles` queries even though:
- The HTTP request succeeds (200 status)
- Data exists in the database
- The query syntax is correct

**Root Cause**: Row Level Security (RLS) policies are blocking access, AND/OR missing GRANT permissions.

## Solution

### Quick Fix (Recommended)
1. Open `database/COPY-PASTE-THIS-NOW.sql`
2. Copy ALL lines
3. Go to Supabase Dashboard → SQL Editor
4. Paste and click "Run"
5. Hard refresh your app (Ctrl+Shift+R)

### If That Doesn't Work
1. Run `database/DIAGNOSE-EXACT-ISSUE.sql` first
2. Share the results to identify the exact problem
3. Then run the fix script

## What This Fixes
This fix applies to **ALL** queries to `fighter_profiles` across your entire app:
- Homepage fighter list
- My Profile page
- Rankings
- Matchmaking
- Training camps
- Callouts
- Notifications
- And 100+ other places

Once the database permissions are fixed, everything will work.

## Files Available
- `COPY-PASTE-THIS-NOW.sql` - Minimal fix (easiest to use)
- `FIX-RLS-WITH-GRANTS.sql` - Complete fix with verification
- `DIAGNOSE-EXACT-ISSUE.sql` - Diagnostic tool to find problems

## After Running the Fix
1. Check Supabase SQL Editor results - should see 2 policies listed
2. Hard refresh your app (Ctrl+Shift+R)
3. Check browser console - should see fighters loading
4. If still broken, run the diagnostic script and share results

