# 🚨 DO THIS RIGHT NOW 🚨

## Your fighters aren't showing because database security is blocking them.

## ✅ THE FIX (3 Steps, 30 seconds)

### Step 1: Copy the SQL
1. Open file: **`database/🚨-RUN-THIS-NOW.sql`**
2. Press **Ctrl+A** (select all)
3. Press **Ctrl+C** (copy)

### Step 2: Run in Supabase
1. Go to: **https://supabase.com/dashboard**
2. Click your project
3. Click **"SQL Editor"** in the left sidebar
4. Click **"New Query"** (or use existing editor)
5. Press **Ctrl+V** (paste the SQL)
6. Click **"Run"** button (or press Ctrl+Enter)

### Step 3: Verify & Refresh
1. You should see: `✅ SUCCESS - RLS FIXED!` and a number showing fighter count
2. Go back to your app
3. Press **Ctrl+Shift+R** (hard refresh)

**Fighters should now appear!** 🎉

---

## ❓ What if it doesn't work?

If you still see "NO FIGHTERS RETURNED FROM QUERY":

1. **Check the Supabase output** - Did you see `✅ SUCCESS`?
2. **Run this diagnostic**: Copy `database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql` and run it in Supabase
3. **Share the output** - It will tell us exactly what's wrong

---

## 🔍 Why This Happens

Your database has Row Level Security (RLS) enabled, which is good for security. But the policies were too restrictive - they blocked everyone from reading fighter profiles, even though the homepage needs to show them.

This fix:
- ✅ Keeps RLS enabled (security stays on)
- ✅ Adds read permissions for anonymous and logged-in users
- ✅ Allows fighters to appear on homepage

**This is safe** - it only allows reading, not modifying fighter data.

