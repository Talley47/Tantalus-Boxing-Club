# Fix Callout Requests RLS Policy Error

## Problem
When trying to create a callout request, you're getting:
```
Error: new row violates row-level security policy for table "callout_requests"
```

## Solution

### Step 1: Run the RLS Fix SQL

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Click on **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy and paste the contents of `database/fix-callout-requests-rls-comprehensive.sql`
6. Click **Run** (or press Ctrl+Enter)

This will:
- Drop and recreate all RLS policies for `callout_requests`
- Ensure fighters can create callouts where they are the caller
- Ensure fighters can view callouts where they are caller or target
- Ensure targets can update (accept/decline) callouts
- Grant proper permissions

### Step 2: Verify It Works

After running the SQL:
1. Try creating a rematch request again
2. The error should be gone!

## What Changed

The RLS policy now properly checks that:
- `caller_id` matches a fighter profile owned by `auth.uid()` (the logged-in user)
- This ensures users can only create callouts for themselves

## Optional: Add Notification Sound File

The notification bell is looking for a sound file. To add it:

1. Place `boxing-bell-signals-6115 (1).mp3` in the `public` folder
2. Or rename your sound file to match one of these paths:
   - `/boxing-bell-signals-6115 (1).mp3`
   - `/boxing-bell-signals-6115.mp3`
   - `/assets/boxing-bell-signals-6115 (1).mp3`

This is optional - notifications will still work without the sound file.

