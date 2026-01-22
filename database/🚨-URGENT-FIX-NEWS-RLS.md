# 🚨 URGENT: Fix News & Announcements Not Showing

## ⚠️ IMPORTANT: This is NOT a code issue - it's a database security policy

The app code is working correctly. The database is blocking authenticated users from reading news because **RLS (Row Level Security) policy is missing**.

---

## ✅ SOLUTION: Create RLS Policy (Takes 2 Minutes)

### Method 1: Supabase Dashboard UI (RECOMMENDED - No SQL needed!)

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project

2. **Navigate to RLS Policies**
   - Click **"Table Editor"** in left sidebar
   - Click on **`news_announcements`** table
   - Click **"RLS"** tab at the top

3. **Create New Policy**
   - Click **"New Policy"** button
   - Choose **"Create a policy from scratch"**
   - Fill in:
     - **Policy name**: `Authenticated read published news`
     - **Allowed operation**: Select **`SELECT`** (read only)
     - **Target roles**: Select **`authenticated`**
     - **USING expression**: Copy and paste this EXACTLY:
       ```sql
       is_published IS NOT NULL AND is_published = TRUE
       ```
   - Click **"Review"** then **"Save policy"**

4. **Verify**
   - You should see the policy in the list
   - It should say: `SELECT` for `authenticated` role

5. **Test**
   - Refresh your app (Ctrl+Shift+R)
   - News should now appear!

---

### Method 2: Check if News Items Are Published

If the RLS policy already exists, check if news items are published:

1. **Supabase Dashboard** → **"Table Editor"** → **`news_announcements`**
2. Look at each row's **`is_published`** column
3. If it's `false` or `null`, change it to `true`
4. Click **"Save"**

---

## 🔍 Diagnostic: Check What's Wrong

Run this script to check the issue:

```bash
cd tantalus-boxing-club
node scripts/check-news-rls.js
```

This will tell you:
- ✅ If RLS policy exists
- ✅ If news items are published
- ✅ What the exact error is

---

## 📋 What to Check in Browser Console (F12)

Open browser console and look for:

**If RLS is blocking:**
```
🚫 RLS POLICY ISSUE: No news items returned for authenticated user.
```

**If items are unpublished:**
```
📰 News query result: { publishedCount: 0, unpublishedCount: 5 }
```

---

## ❓ Why Is This Happening?

Supabase uses **Row Level Security (RLS)** to control who can read/write data. By default, tables are locked down. You need to create policies that say "authenticated users can read published news."

This is a **security feature**, not a bug. The app code is correct - the database just needs permission configured.

---

## 🆘 Still Not Working?

1. **Check browser console** (F12) for exact error
2. **Verify you're logged in** (RLS only applies to authenticated users)
3. **Check Supabase Dashboard** → **"Table Editor"** → **`news_announcements`** → **"RLS"** tab
4. **Make sure policy exists** and allows `SELECT` for `authenticated` role
