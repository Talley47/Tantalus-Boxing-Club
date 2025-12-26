# 🚨 FIX THE "NO FIGHTERS" ERROR - 3 STEPS

## The Problem
Your app shows "NO FIGHTERS RETURNED FROM QUERY" because RLS is blocking access.

## The Solution (30 seconds)

### Step 1: Open Supabase SQL Editor
1. Go to: **https://supabase.com/dashboard**
2. Click your project
3. Click **"SQL Editor"** in the left sidebar

### Step 2: Copy & Run SQL
1. Open file: **`database/🚨-RUN-THIS-NOW.sql`**
2. **Select ALL** (Ctrl+A)
3. **Copy** (Ctrl+C)
4. **Paste** in Supabase SQL Editor (Ctrl+V)
5. Click **"Run"** button (or press F5)

### Step 3: Verify Success
You should see:
- ✅ `status: "✅ SUCCESS - RLS FIXED!"`
- ✅ `total_fighters: [your number]`

### Step 4: Refresh Your App
- **Windows/Linux:** Press **Ctrl+Shift+R**
- **Mac:** Press **Cmd+Shift+R**

**Fighters should now appear!** 🎉

---

## ❓ Still Not Working?

Run this diagnostic:
1. Open: **`database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql`**
2. Copy ALL content
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Check the output - it will tell you exactly what's wrong

---

## 🔒 What This Does

✅ Grants SELECT permissions to `anon` and `authenticated` roles  
✅ Keeps RLS enabled (security stays on)  
✅ Removes all existing restrictive policies  
✅ Creates permissive policies allowing public read access  

**This is safe** - it only allows reading fighter profiles, not modifying them.

