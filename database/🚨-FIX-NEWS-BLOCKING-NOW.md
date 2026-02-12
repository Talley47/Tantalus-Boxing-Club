# 🚨 URGENT: Fix News & Announcements Blocking

## Problem
News and Announcements are blank for authenticated (logged-in) users because RLS policies are blocking access.

## Solution (2 minutes)

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project
3. Click **SQL Editor** in the left sidebar

### Step 2: Run the Fix SQL
1. Open the file: `database/FIX-NEWS-RLS-AUTHENTICATED-READ-ALL.sql`
2. Copy **ALL** the SQL (Ctrl+A, Ctrl+C)
3. Paste into Supabase SQL Editor (Ctrl+V)
4. Click **Run** button

### Step 3: Verify
1. Hard refresh your app (Ctrl+Shift+R)
2. News & Announcements should now appear!

## What This Does
- Allows authenticated users to read ALL news items from the database
- Client-side code filters for `is_published = true` before displaying
- This prevents RLS from blocking access while still only showing published news

## If Still Not Working
Check the browser console (F12) for error messages. Look for:
- `🚫 RLS POLICY ISSUE` - means RLS is still blocking
- `📰 News query result` - shows how many items were fetched
- `✅ After filtering` - shows how many published items remain
