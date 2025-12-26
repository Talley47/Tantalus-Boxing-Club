# 🚨 URGENT: Fix Fighters Not Appearing

## The Problem
Your app shows "NO FIGHTERS RETURNED FROM QUERY" because Row Level Security (RLS) is blocking access to the `fighter_profiles` table.

## The Solution (2 Minutes)

### Step 1: Open Supabase Dashboard
1. Go to: **https://supabase.com/dashboard**
2. Click on **your project**
3. Click **SQL Editor** in the left sidebar

### Step 2: Copy the SQL
1. Open file: `database/COPY-THIS-AND-RUN.sql`
2. **Select ALL** (Ctrl+A or Cmd+A)
3. **Copy** (Ctrl+C or Cmd+C)

### Step 3: Paste and Run
1. In Supabase SQL Editor, click **"New Query"**
2. **Paste** the SQL (Ctrl+V or Cmd+V)
3. Click the **"Run"** button (or press Ctrl+Enter)

### Step 4: Verify Success
You should see:
- ✅ A row with `status: "✅ SUCCESS - RLS FIXED!"`
- ✅ A number in `total_fighters` column (your fighter count)
- ✅ Two policies listed: "Authenticated users..." and "Anonymous users..."

### Step 5: Refresh Your App
- **Windows/Linux:** Press **Ctrl+Shift+R**
- **Mac:** Press **Cmd+Shift+R**

**Fighters should now appear on your homepage!** 🎉

---

## 🔍 If Still Not Working

Run the diagnostic script:
1. Open: `database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql`
2. Copy ALL content
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Check the output - it will tell you exactly what's wrong

---

## ❓ What This Does

✅ Grants SELECT permissions to `anon` and `authenticated` roles  
✅ Keeps RLS enabled (security stays on)  
✅ Removes all existing restrictive policies  
✅ Creates permissive policies allowing public read access  

**This is safe** - it only allows reading fighter profiles, not modifying them.

