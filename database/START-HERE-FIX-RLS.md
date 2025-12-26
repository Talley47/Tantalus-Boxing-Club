# 🚨 START HERE: Fix RLS Blocking Fighters

## ⚡ FASTEST METHOD (30 seconds)

### Step 1: Open the HTML Page
**Double-click this file:** `database/FIX-RLS-NOW.html`

### Step 2: Click "Copy SQL" Button
The button is in the top-right corner of the SQL box.

### Step 3: Go to Supabase Dashboard
1. Open: https://supabase.com/dashboard
2. Click your project
3. Click **"SQL Editor"** in the left sidebar

### Step 4: Paste & Run
1. Click **"New Query"** button
2. Press **Ctrl+V** (or Cmd+V on Mac) to paste
3. Click **"Run"** button (or press Ctrl+Enter)

### Step 5: Verify Success
You should see:
- ✅ `status: "SUCCESS - RLS FIXED"`
- ✅ `visible_rows: [number]` (your fighter count)

### Step 6: Refresh Your App
- **Windows/Linux:** Press **Ctrl+Shift+R**
- **Mac:** Press **Cmd+Shift+R**

**Fighters should now appear on your homepage!** 🎉

---

## 📋 Alternative: Copy-Paste Method

If the HTML page doesn't work:

1. Open: `database/ONE-LINE-FIX-RLS.sql`
2. Select ALL text (Ctrl+A)
3. Copy (Ctrl+C)
4. Go to Supabase SQL Editor
5. Paste (Ctrl+V)
6. Click "Run"
7. Refresh your app (Ctrl+Shift+R)

---

## ❓ Still Not Working?

Run the diagnostic script:
1. Open: `database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql`
2. Copy ALL content
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Check the output for warnings

---

## 🔍 What This Fix Does

✅ Grants SELECT permissions to `anon` and `authenticated` roles  
✅ Keeps RLS enabled (security stays on)  
✅ Removes restrictive policies  
✅ Creates permissive policies allowing public read access  

**This is safe** - it only allows reading fighter profiles, not modifying them.

