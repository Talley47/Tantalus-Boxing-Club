# ✅ Step-by-Step Checklist: Fix RLS Issue

Follow these steps **exactly** in order. Check off each step as you complete it.

---

## 📋 Pre-Flight Check

- [ ] I have access to my Supabase dashboard (https://supabase.com/dashboard)
- [ ] I know which Supabase project to use
- [ ] My app is running (localhost:3000 or similar)
- [ ] I can see the browser console (F12 → Console tab)

---

## 🚀 Step 1: Open the SQL Fix File

- [ ] Navigate to: `tantalus-boxing-club/database/COPY-PASTE-THIS-NOW.sql`
- [ ] Open the file in a text editor (Notepad, VS Code, etc.)
- [ ] **DO NOT** edit the file - just open it

**Alternative (Windows):** Double-click `database/OPEN-FIX-FILE.bat` - it will open the file for you!

---

## 📋 Step 2: Copy the SQL

- [ ] Press `Ctrl+A` (select all text in the SQL file)
- [ ] Press `Ctrl+C` (copy to clipboard)
- [ ] Verify: You should have copied about 27 lines of SQL code

---

## 🌐 Step 3: Open Supabase SQL Editor

- [ ] Go to: https://supabase.com/dashboard
- [ ] Click on your project (select the correct one if you have multiple)
- [ ] In the left sidebar, click **"SQL Editor"**
- [ ] Click the **"New Query"** button (top right)

**Alternative:** If you used `OPEN-FIX-FILE.bat`, the dashboard should already be open!

---

## 📝 Step 4: Paste and Run the SQL

- [ ] Click in the SQL Editor text area
- [ ] Press `Ctrl+V` (paste the SQL you copied)
- [ ] Verify: You should see SQL starting with `-- MINIMAL FIX:` and ending with a `SELECT` statement
- [ ] Click the **"Run"** button (or press `Ctrl+Enter`)
- [ ] **WAIT** for the query to finish (usually 1-2 seconds)

---

## ✅ Step 5: Verify Success

After clicking "Run", check the results panel below the editor:

- [ ] You see a **"Success"** message (green checkmark)
- [ ] You see a **table with 2 rows** showing policies:
  - Row 1: `"Authenticated users can view fighter profiles"` with roles `{authenticated}`
  - Row 2: `"Anonymous users can view fighter profiles"` with roles `{anon}`

**If you DON'T see 2 policies:**
- [ ] Check for error messages in red
- [ ] Copy the error message
- [ ] Run `database/CHECK-IF-FIX-APPLIED.sql` to see what's configured
- [ ] Share the error message or results with the assistant

---

## 🔄 Step 6: Refresh Your App

- [ ] Go back to your running app in the browser
- [ ] Press `Ctrl+Shift+R` (hard refresh - clears cache)
- [ ] **OR** Press `F5` (regular refresh)
- [ ] Wait for the page to reload

---

## 🧪 Step 7: Test the Fix

### Option A: Check Browser Console

- [ ] Open browser console (F12 → Console tab)
- [ ] Look for the message: `✅ Fetched X fighter profiles from database`
- [ ] If you see this, **SUCCESS!** Fighters should now be visible

### Option B: Run Verification Script

- [ ] Open browser console (F12 → Console tab)
- [ ] Open file: `database/VERIFY-IN-BROWSER.js`
- [ ] Copy ALL the code from that file
- [ ] Paste it into the browser console
- [ ] Press Enter
- [ ] Check the output - it will tell you if the fix worked

---

## ❌ If Fighters Still Don't Appear

If after Step 7, fighters still don't show:

### Diagnostic Step 1: Check What's Configured

- [ ] Open: `database/CHECK-IF-FIX-APPLIED.sql`
- [ ] Copy ALL lines
- [ ] Paste into Supabase SQL Editor → Run
- [ ] Check results - should show 2 policies
- [ ] If fewer than 2, the fix didn't apply correctly

### Diagnostic Step 2: Comprehensive Check

- [ ] Open: `database/FIND-THE-PROBLEM.sql`
- [ ] Copy ALL lines
- [ ] Paste into Supabase SQL Editor → Run
- [ ] **Copy the ENTIRE output** (all results)
- [ ] Share the output with the assistant

### Diagnostic Step 3: Browser Console Test

- [ ] Run the verification script from Step 7 (Option B)
- [ ] Copy the entire console output
- [ ] Share it with the assistant

---

## 🎯 Success Criteria

You'll know the fix worked when:

1. ✅ Supabase SQL Editor shows "Success" + 2 policies
2. ✅ Browser console shows: `✅ Fetched X fighter profiles`
3. ✅ Fighters appear on the homepage
4. ✅ Fighters appear on "My Profile" page

---

## ⚠️ Common Mistakes

- ❌ **Didn't copy ALL lines** - Make sure you copied from `-- MINIMAL FIX:` to the final `SELECT` statement
- ❌ **Didn't click "Run"** - Just pasting isn't enough, you must click "Run"
- ❌ **Didn't hard refresh** - Regular refresh might use cached data
- ❌ **Wrong Supabase project** - Make sure you're in the correct project
- ❌ **SQL Editor error** - If you see an error, copy it and share it

---

## 📞 Need Help?

If you've completed all steps and it's still not working:

1. Run `database/FIND-THE-PROBLEM.sql` in Supabase SQL Editor
2. Copy the **entire output**
3. Run `database/VERIFY-IN-BROWSER.js` in your browser console
4. Copy the **entire console output**
5. Share both outputs with the assistant

---

**Remember:** This is a database security setting. The code cannot fix it automatically. You MUST run the SQL in Supabase Dashboard yourself.

