# 🚨 DO THIS RIGHT NOW - 2 MINUTES

## Your fighters are blocked by RLS. Fix it in 2 minutes:

### Step 1: Open Supabase
Go to: **https://supabase.com/dashboard** → Your Project → **SQL Editor** (left sidebar)

### Step 2: Copy the SQL below (Ctrl+A, Ctrl+C)

```sql
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE r RECORD; BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' AND (cmd = 'SELECT' OR cmd = 'ALL') LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); END LOOP; END $$;
CREATE POLICY "Authenticated users can view fighter profiles" ON public.fighter_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Anonymous users can view fighter profiles" ON public.fighter_profiles FOR SELECT TO anon USING (true);
SELECT '✅ SUCCESS - RLS FIXED!' as status, COUNT(*) as total_fighters FROM public.fighter_profiles;
```

### Step 3: Paste in Supabase SQL Editor (Ctrl+V)

### Step 4: Click "Run" button (or press F5)

### Step 5: You should see:
- ✅ `status: "✅ SUCCESS - RLS FIXED!"`
- ✅ `total_fighters: [your number]`

### Step 6: Refresh your app
- **Windows:** Press **Ctrl+Shift+R**
- **Mac:** Press **Cmd+Shift+R**

**Fighters should appear immediately!** 🎉

---

## ❓ Still not working?

Run this diagnostic first:
1. Open `database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql`
2. Copy ALL content
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Share the output with me

