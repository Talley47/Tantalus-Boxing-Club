# 🚨 QUICK FIX: Enable Fighter Profiles Access

## Problem
RLS policies are blocking access to `fighter_profiles` table. Queries return HTTP 200 but 0 rows.

## Solution (Choose ONE method)

### ⚡ Method 1: One-Line Fix (FASTEST)
1. Open `database/ONE-LINE-FIX-RLS.sql`
2. Copy the ENTIRE line (Ctrl+A, Ctrl+C)
3. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
4. Paste (Ctrl+V) → Click "Run"
5. Hard refresh your app (Ctrl+Shift+R)

### 📋 Method 2: Full Script (MORE DETAILED OUTPUT)
1. Open `database/FIX-FIGHTER-PROFILES-RLS-IMMEDIATE.sql`
2. Copy ALL content (Ctrl+A, Ctrl+C)
3. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
4. Paste (Ctrl+V) → Click "Run"
5. Check the output for verification messages
6. Hard refresh your app (Ctrl+Shift+R)

### 🔍 Method 3: Check First, Then Fix
1. Run `database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql` to see current state
2. Then run `database/FIX-FIGHTER-PROFILES-RLS-IMMEDIATE.sql` to fix

## What the Fix Does
- ✅ Grants SELECT permissions to `anon` and `authenticated` roles
- ✅ Enables Row Level Security (kept enabled for security)
- ✅ Drops all existing SELECT policies
- ✅ Creates permissive SELECT policies for both roles (`USING (true)`)

## Expected Result
After running the fix:
- ✅ Fighters appear on homepage immediately
- ✅ No more "NO FIGHTERS RETURNED FROM QUERY" errors
- ✅ Both logged-in and logged-out users can see fighters

## If Still Not Working
1. Check browser console for errors
2. Verify you ran the SQL script successfully
3. Check Supabase logs for query errors
4. Run `database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql` to verify the fix was applied

