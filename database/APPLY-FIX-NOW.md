# 🚨 URGENT: Fix RLS Blocking Fighter Profiles

## The Problem
Your app shows "NO FIGHTERS RETURNED FROM QUERY" because RLS policies are blocking access to the `fighter_profiles` table.

## The Solution (3 Steps - Takes 30 Seconds)

### Option 1: Use the HTML Page (EASIEST)
1. **Open:** `database/FIX-RLS-NOW.html` in your browser (double-click it)
2. **Click:** The "Copy SQL" button
3. **Go to:** https://supabase.com/dashboard → Your Project → SQL Editor
4. **Paste:** Press Ctrl+V
5. **Run:** Click "Run" button
6. **Refresh:** Your app (Ctrl+Shift+R)

### Option 2: Copy-Paste SQL Directly
1. **Open:** `database/ONE-LINE-FIX-RLS.sql`
2. **Copy:** The entire line (Ctrl+A, Ctrl+C)
3. **Go to:** https://supabase.com/dashboard → Your Project → SQL Editor
4. **Paste:** Press Ctrl+V
5. **Run:** Click "Run" button
6. **Refresh:** Your app (Ctrl+Shift+R)

### Option 3: Use the Full Script (MOST DETAILED)
1. **Open:** `database/FIX-FIGHTER-PROFILES-RLS-IMMEDIATE.sql`
2. **Copy:** All content (Ctrl+A, Ctrl+C)
3. **Go to:** https://supabase.com/dashboard → Your Project → SQL Editor
4. **Paste:** Press Ctrl+V
5. **Run:** Click "Run" button
6. **Refresh:** Your app (Ctrl+Shift+R)

## What This Does
- ✅ Grants SELECT permissions to `anon` and `authenticated` roles
- ✅ Enables RLS (keeps security enabled)
- ✅ Drops existing restrictive policies
- ✅ Creates permissive policies allowing everyone to read fighter profiles

## Expected Result
After running the SQL, you should see:
- Status: `SUCCESS - RLS FIXED`
- Row count: Number of fighter profiles in your database

Then fighters will appear on your homepage! 🎉

## Still Not Working?
Run the diagnostic script:
1. **Open:** `database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql`
2. **Copy & Run** in Supabase SQL Editor
3. **Check** the output for any warnings

