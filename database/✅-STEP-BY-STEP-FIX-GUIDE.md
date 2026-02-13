# ✅ Step-by-Step Fix Guide: Fighter Profiles RLS

## 🎯 Goal
Fix the RLS blocking issue so fighters appear on homepage and rankings page.

---

## 📋 Step-by-Step Instructions

### **Step 1: Open Supabase Dashboard**
1. Go to: https://supabase.com/dashboard
2. Select your project
3. Click **"SQL Editor"** in the left sidebar
4. Click **"New Query"**

---

### **Step 2: Run Command 1 - Grant Permissions**

Copy and paste this command:
```sql
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
```

**Click "Run"** (or press Ctrl+Enter)

**Expected Result:** Should see "Success" message

**Wait for:** Command to complete before proceeding

---

### **Step 3: Run Command 2 - Create Policy for Anonymous Users**

Copy and paste this command:
```sql
CREATE POLICY IF NOT EXISTS "anon_view_fighters" 
ON public.fighter_profiles FOR SELECT TO anon USING (true);
```

**Click "Run"**

**Expected Result:** Should see "Success" message

**Wait for:** Command to complete

---

### **Step 4: Run Command 3 - Create Policy for Authenticated Users**

Copy and paste this command:
```sql
CREATE POLICY IF NOT EXISTS "auth_view_fighters" 
ON public.fighter_profiles FOR SELECT TO authenticated USING (true);
```

**Click "Run"**

**Expected Result:** Should see "Success" message

**Wait for:** Command to complete

---

### **Step 5: Verify Fix Worked**

Copy and paste this command:
```sql
SELECT COUNT(*) as fighters FROM public.fighter_profiles;
```

**Click "Run"**

**Expected Result:** Should return a number > 0 (e.g., `fighters: 5`)

**If you see a number > 0:** ✅ **FIX WORKED!**

**If you see 0:** The database might be empty, or there's still an RLS issue.

---

## ✅ After Fix Applied

1. **Hard refresh your browser:**
   - Windows/Linux: `Ctrl + Shift + R`
   - Mac: `Cmd + Shift + R`

2. **Check homepage:**
   - Should see fighters in "Top Fighters" section
   - Should NOT see "No fighters found"

3. **Check rankings page:**
   - Should show all fighters
   - Should NOT be empty

4. **Check browser console:**
   - Open Developer Tools (F12)
   - Go to Console tab
   - Should NOT see RLS errors
   - Should NOT see "NO FIGHTERS RETURNED FROM QUERY"

---

## 🐛 Troubleshooting

### Problem: "Policy already exists"
**Solution:** This is OK! The `IF NOT EXISTS` clause prevents errors. The policy is already there, which is good.

### Problem: "Permission denied"
**Solution:** Make sure you're logged into Supabase Dashboard with admin access.

### Problem: "Table does not exist"
**Solution:** Check table name - it should be `fighter_profiles` (with underscore, not hyphen).

### Problem: Still seeing "No fighters found"
**Solution:**
1. Clear browser cache completely
2. Wait 30 seconds
3. Hard refresh again (Ctrl+Shift+R)
4. Check browser console for errors
5. Run verification query again: `SELECT COUNT(*) FROM fighter_profiles;`

### Problem: SQL Editor times out
**Solution:**
1. Run commands one at a time (don't run all at once)
2. Wait for each to complete before next
3. If still timing out, use Dashboard UI method (see below)

---

## 🔄 Alternative: Use Dashboard UI (If SQL Times Out)

If SQL Editor continues to timeout, use the UI:

1. **Go to:** Database → Policies
2. **Select Table:** `fighter_profiles`
3. **Create Policy 1:**
   - Click "New Policy"
   - Name: `anon_view_fighters`
   - Operation: `SELECT`
   - Roles: `anon`
   - USING: `true`
   - Click "Save"
4. **Create Policy 2:**
   - Click "New Policy"
   - Name: `auth_view_fighters`
   - Operation: `SELECT`
   - Roles: `authenticated`
   - USING: `true`
   - Click "Save"
5. **Grant Permissions:**
   - Go to: Database → Tables → `fighter_profiles`
   - Click "..." menu → "Edit Table"
   - Look for "Permissions" section
   - Ensure `anon` and `authenticated` have SELECT permission

---

## ✅ Success Indicators

After applying the fix, you should see:

✅ Verification query returns fighters count > 0  
✅ Homepage displays fighters  
✅ Rankings page shows fighters  
✅ No "No fighters found" messages  
✅ No RLS errors in browser console  
✅ Browser console shows fighters loading successfully  

---

## 📞 Need Help?

If you encounter any issues:
1. Share the exact error message
2. Share the result from verification query (Step 5)
3. Share any browser console errors

The fix is simple - it's just granting permissions and creating policies. If commands timeout, run them one at a time and wait for each to complete.
