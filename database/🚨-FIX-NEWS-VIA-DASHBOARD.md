# 🚨 FIX NEWS & ANNOUNCEMENTS VIA SUPABASE DASHBOARD

## Problem
News & Announcements shows "No news or announcements at the moment" even though admin posts exist.

## Root Cause
**RLS (Row Level Security) policy is missing** for authenticated users. Logged-in users can't read the `news_announcements` table.

---

## ✅ SOLUTION: Create RLS Policy via Dashboard UI

### Step 1: Open Supabase Dashboard
1. Go to: https://supabase.com/dashboard
2. Select your project
3. Click **"Authentication"** → **"Policies"** in the left sidebar
   - OR go to **"Table Editor"** → Click `news_announcements` table → Click **"RLS"** tab

### Step 2: Create Policy for Authenticated Users
1. In the **"RLS"** section for `news_announcements` table:
2. Click **"New Policy"** or **"Create Policy"**
3. Fill in:
   - **Policy Name**: `Authenticated read published news`
   - **Allowed Operation**: `SELECT` (read only)
   - **Target Roles**: `authenticated`
   - **USING Expression**: Paste this:
     ```sql
     is_published IS NOT NULL AND is_published = TRUE
     ```
4. Click **"Save"** or **"Create"**

### Step 3: Verify Policy Exists
- You should see a policy named `Authenticated read published news` in the list
- It should allow `SELECT` for `authenticated` role

### Step 4: Test
1. Refresh your app (hard refresh: Ctrl+Shift+R)
2. Go to Home Page → News & Announcements tab
3. News should now appear!

---

## 🔍 ALTERNATIVE: Check if News Items Are Published

If the RLS policy already exists, the issue might be that news items aren't published:

### Step 1: Check News Items
1. Supabase Dashboard → **"Table Editor"** → `news_announcements`
2. Look at the `is_published` column
3. If it's `false` or `null`, that's why they're not showing

### Step 2: Publish News Items
1. Click on a news item row
2. Change `is_published` from `false` to `true`
3. Click **"Save"**
4. Repeat for all news items you want to show

---

## 🐛 Still Not Working?

### Check Browser Console (F12)
Look for errors like:
- `RLS POLICY ISSUE: No news items returned for authenticated user`
- `permission denied`
- `policy`

### Verify You're Logged In
- The RLS policy only applies to **authenticated** (logged-in) users
- If you're not logged in, you need a different policy for `anon` role

---

## 📝 Quick SQL (If Dashboard UI Doesn't Work)

If you can access SQL Editor (even if it's blocked for other queries), try this minimal script:

```sql
CREATE POLICY "Authenticated read published news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (is_published IS NOT NULL AND is_published = TRUE);
```

**Note**: If you get `permission denied for schema pg_catalog`, use the Dashboard UI method above instead.
