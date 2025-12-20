# ⚡ QUICK ACTION PLAN - Fix Fighters Not Displaying

## 🎯 **THE PROBLEM**
RLS (Row Level Security) is blocking all reads on `fighter_profiles` table.  
**Result:** Homepage and My Profile show no fighters.

---

## ✅ **THE FIX (30 Seconds)**

### **Step 1: Copy SQL**
Open `database/FIX-RLS-NOW.html` → Click "Copy SQL" button  
**OR**  
Open `database/SINGLE-LINE-DISABLE-RLS.sql` → Copy entire line (Ctrl+A, Ctrl+C)

### **Step 2: Run in Supabase**
1. Go to: https://supabase.com/dashboard/project/andmtvsqqomgwphotdwf/sql
2. Click "New Query"
3. Paste SQL (Ctrl+V)
4. Click "Run"

### **Step 3: Verify**
- Should see: `SUCCESS - RLS DISABLED` with row count > 0
- Hard refresh app: `Ctrl+Shift+R`
- **Fighters should appear immediately!**

---

## 📋 **SQL TO COPY**

```sql
DO $$ DECLARE r RECORD; BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); END LOOP; END $$; ALTER TABLE public.fighter_profiles DISABLE ROW LEVEL SECURITY; GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated; SELECT 'SUCCESS - RLS DISABLED' as status, COUNT(*) as visible_rows FROM public.fighter_profiles;
```

---

## 🔍 **IF STILL BROKEN**

1. Run: `database/CHECK-IF-FIX-APPLIED.sql` in Supabase
2. Run: `database/VERIFY-IN-BROWSER.js` in browser console
3. Share results

---

**Full details:** See `COMPREHENSIVE-SCAN-AND-RESOLUTION-PLAN.md`

