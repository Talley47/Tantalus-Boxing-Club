-- =====================================================
-- RE-ENABLE RLS WITH PROPER POLICIES (After using DISABLE-RLS-COMPLETELY.sql)
-- Use this if you want to re-enable RLS with permissive policies later
-- Copy ALL lines below and paste into Supabase SQL Editor
-- =====================================================

-- Step 1: Ensure permissions are granted
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Step 2: Drop any existing policies (clean slate)
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname);
  END LOOP;
END $$;

-- Step 3: Re-enable RLS
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Step 4: Create permissive policies (allows everyone to read)
CREATE POLICY "Authenticated users can view fighter profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Anonymous users can view fighter profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO anon 
USING (true);

-- Step 5: Verify (should show 2 policies)
SELECT policyname, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles';

-- ✅ DONE! RLS is now enabled with permissive policies.
-- Refresh your app (Ctrl+Shift+R) and fighters should still appear.

