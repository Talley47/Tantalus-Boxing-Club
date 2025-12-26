# ⚠️ URGENT: Fix "NO FIGHTERS RETURNED" Error

## The Problem
Your app can't see fighter profiles because Row Level Security (RLS) is blocking access. The query succeeds (HTTP 200) but returns 0 rows.

## The Solution (2 Minutes)

### Step 1: Open Supabase SQL Editor
1. Go to: **https://supabase.com/dashboard**
2. Select your project
3. Click **"SQL Editor"** in the left sidebar

### Step 2: Copy & Run This SQL
1. Open file: **`database/🚨-RUN-THIS-NOW.sql`**
2. **Select ALL** (Ctrl+A)
3. **Copy** (Ctrl+C)
4. **Paste** into Supabase SQL Editor (Ctrl+V)
5. Click **"Run"** button

### Step 3: Verify Success
You should see:
- ✅ `status: "✅ SUCCESS - RLS FIXED!"`
- ✅ `total_fighters: [a number]` (your fighter count)

### Step 4: Refresh Your App
- **Windows/Linux:** Press **Ctrl+Shift+R**
- **Mac:** Press **Cmd+Shift+R**

**Fighters should now appear on your homepage!** 🎉

---

## What This Does
- ✅ Grants SELECT permissions to `anon` and `authenticated` roles
- ✅ Keeps RLS enabled (security stays on)
- ✅ Removes restrictive policies
- ✅ Creates permissive policies allowing public read access

**This is safe** - it only allows reading fighter profiles, not modifying them.

---

## If Still Not Working
Run the diagnostic script:
1. Open: **`database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql`**
2. Copy ALL content
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Share the output with me

