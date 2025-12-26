# 🚨 URGENT: Fix RLS Blocking Fighters

## ⚡ FASTEST FIX (Copy-Paste - 30 seconds)

### Step 1: Open Supabase SQL Editor
Go to: **https://supabase.com/dashboard** → Your Project → **SQL Editor**

### Step 2: Copy & Paste
1. Open file: `database/COPY-THIS-AND-RUN.sql`
2. **Select ALL** (Ctrl+A)
3. **Copy** (Ctrl+C)
4. **Paste** in Supabase SQL Editor (Ctrl+V)
5. Click **"Run"** button

### Step 3: Verify Success
You should see:
- ✅ `status: "✅ SUCCESS - RLS FIXED!"`
- ✅ `total_fighters: [number]` (your fighter count)
- ✅ Two policies listed: "Authenticated users..." and "Anonymous users..."

### Step 4: Refresh Your App
- **Windows/Linux:** Press **Ctrl+Shift+R**
- **Mac:** Press **Cmd+Shift+R**

**Fighters should now appear!** 🎉

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

