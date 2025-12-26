# 🚨 DO THIS NOW - Fix Fighters Not Appearing

## The Problem
Your app shows "NO FIGHTERS RETURNED FROM QUERY" because database security (RLS) is blocking access.

## The Fix (2 minutes)

### Step 1: Open Supabase Dashboard
1. Go to: **https://supabase.com/dashboard**
2. Click on **your project**
3. Click **SQL Editor** in the left sidebar

### Step 2: Copy the Fix Script
1. Open file: **`database/COPY-THIS-AND-RUN.sql`**
2. Press **Ctrl+A** (select all)
3. Press **Ctrl+C** (copy)

### Step 3: Run the Script
1. In Supabase SQL Editor, click **"New Query"**
2. Press **Ctrl+V** (paste)
3. Click **"Run"** button (or press Ctrl+Enter)

### Step 4: Check Results
You should see:
- ✅ A row with `status: "✅ SUCCESS - RLS FIXED!"`
- ✅ A number showing `total_fighters: [your count]`
- ✅ Two policies listed: "Authenticated users..." and "Anonymous users..."

### Step 5: Refresh Your App
- **Windows/Linux:** Press **Ctrl+Shift+R**
- **Mac:** Press **Cmd+Shift+R**

**Fighters should now appear!** 🎉

---

## 🔍 Verify It Worked

After refreshing, check your browser console. You should see:
- ✅ No more "NO FIGHTERS RETURNED FROM QUERY" errors
- ✅ Fighters loading on the homepage

---

## ❓ Still Not Working?

Run this diagnostic script:
1. Open: **`database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql`**
2. Copy ALL content (Ctrl+A, Ctrl+C)
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Share the output - it will show exactly what's wrong

---

## 📋 What the Fix Does

✅ Grants SELECT permissions to `anon` and `authenticated` roles  
✅ Keeps RLS enabled (security stays on)  
✅ Removes all existing restrictive policies  
✅ Creates permissive policies allowing public read access  

**This is safe** - it only allows reading fighter profiles, not modifying them.

