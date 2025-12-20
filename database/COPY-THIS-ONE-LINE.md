# ⚡ FASTEST FIX - Copy This One Line

## The Problem
RLS (Row Level Security) is blocking access to `fighter_profiles`. The query succeeds but returns 0 rows.

## The Solution
Copy this **ONE LINE** into Supabase SQL Editor and run it:

```
DO $$ DECLARE r RECORD; BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); END LOOP; END $$; ALTER TABLE public.fighter_profiles DISABLE ROW LEVEL SECURITY; GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated; SELECT 'SUCCESS - RLS DISABLED' as status, COUNT(*) as visible_rows FROM public.fighter_profiles;
```

## Steps:
1. **Copy the line above** (it's all one line - select from `DO` to the semicolon at the end)
2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
3. Click **"New Query"**
4. **Paste** the line (Ctrl+V)
5. Click **"Run"** (or press Ctrl+Enter)
6. You should see: `SUCCESS - RLS DISABLED` and a row count
7. **Hard refresh your app** (Ctrl+Shift+R)

## What This Does:
- Drops all RLS policies on `fighter_profiles`
- Disables RLS completely (removes all blocking)
- Grants SELECT permission to `anon` and `authenticated` roles
- Verifies it worked by showing row count

## After Running:
Fighters should appear on your homepage immediately!

## To Re-enable RLS Later:
Use: `database/RE-ENABLE-RLS-PROPERLY.sql`

