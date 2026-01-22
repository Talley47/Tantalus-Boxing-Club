# 🚨 FIX NEWS & ANNOUNCEMENTS - DASHBOARD UI ONLY (NO SQL)

## Problem
News & Announcements shows "Unable to load news items" even though admin posts exist.

## Root Cause
**RLS (Row Level Security) policy is missing** for authenticated (logged-in) users. The database is blocking access to the `news_announcements` table.

---

## ✅ SOLUTION: Create RLS Policy via Dashboard UI

### Step 1: Open Supabase Dashboard
1. Go to: https://supabase.com/dashboard
2. Select your project: **andmtvsqqomgwphotdwf**
3. Click **"Table Editor"** in the left sidebar

### Step 2: Open News Announcements Table
1. In the table list, find and click **`news_announcements`**
2. You should see the table data

### Step 3: Open RLS Policies
1. At the top of the table view, click the **"RLS"** tab (next to "Data", "Columns", etc.)
2. You'll see a list of existing policies (if any)

### Step 4: Create New Policy
1. Click the **"New Policy"** button (or **"Create Policy"**)
2. A dialog/form will appear

### Step 5: Fill in Policy Details
Fill in the form with these exact values:

- **Policy Name**: `Authenticated read published news`
- **Allowed Operation**: Select **`SELECT`** (read only)
- **Target Roles**: Select **`authenticated`** (this is for logged-in users)
- **USING Expression**: Paste this SQL condition:
  ```sql
  is_published IS NOT NULL AND is_published = TRUE
  ```

### Step 6: Save Policy
1. Click **"Save"** or **"Create"**
2. You should see the new policy appear in the list

### Step 7: Verify Policy Exists
- You should see a policy named `Authenticated read published news`
- It should allow `SELECT` for `authenticated` role
- The USING expression should match what you entered

### Step 8: Test
1. **Hard refresh** your app: Press `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
2. Go to **Home Page** → **News & Announcements** tab
3. News should now appear! ✅

---

## 🔍 ALTERNATIVE: Check if News Items Are Published

If the RLS policy already exists but news still doesn't show:

### Step 1: Check News Items
1. Supabase Dashboard → **"Table Editor"** → `news_announcements`
2. Look at the `is_published` column for each row
3. If it's `false` or `null`, that's why they're not showing

### Step 2: Publish News Items
1. Click on a news item row to edit it
2. Find the `is_published` column
3. Change it from `false` to `true` (or check the checkbox if it's a boolean)
4. Click **"Save"** (or press Enter)
5. Repeat for all news items you want to show

---

## 🐛 Still Not Working?

### Check Browser Console (F12)
1. Open Developer Tools: Press `F12`
2. Go to **Console** tab
3. Look for errors like:
   - `🚫 RLS POLICY ISSUE: No news items returned for authenticated user`
   - `permission denied`
   - `policy`

### Verify You're Logged In
- The RLS policy only applies to **authenticated** (logged-in) users
- Make sure you're logged into the app
- If you're not logged in, you need a different policy for `anon` role

### Check if Policy Was Created Correctly
1. Go back to Dashboard → Table Editor → `news_announcements` → RLS tab
2. Verify the policy exists and has:
   - Name: `Authenticated read published news`
   - Operation: `SELECT`
   - Role: `authenticated`
   - USING: `is_published IS NOT NULL AND is_published = TRUE`

---

## 📝 What This Fix Does

This RLS policy allows **logged-in users** to read (SELECT) rows from `news_announcements` table **only if**:
- `is_published` is not NULL
- `is_published` is TRUE

This means:
- ✅ Published news items are visible to logged-in users
- ❌ Unpublished news items are hidden from logged-in users
- ❌ News items with NULL `is_published` are hidden

---

## ✅ Success Indicators

After creating the policy, you should see:
1. ✅ Policy appears in RLS policies list
2. ✅ Browser console shows: `📰 News query result: { totalFetched: X, ... }`
3. ✅ News items appear on Home Page
4. ✅ No more "Unable to load news items" error

---

## 🆘 Need Help?

If you're still stuck:
1. Check browser console (F12) for specific error messages
2. Verify you're logged into the app
3. Verify news items exist and are published (`is_published = true`)
4. Verify the RLS policy was created correctly
