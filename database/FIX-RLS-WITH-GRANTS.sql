-- =====================================================
-- COMPLETE FIX: Grants + RLS Policies for fighter_profiles
-- Run this ENTIRE script in Supabase SQL Editor
-- =====================================================

-- 0) Make sure the table exists where you think it does
-- (optional) select * from public.fighter_profiles limit 1;

-- 1) Ensure roles can even SELECT the table (privileges are separate from RLS)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- 2) Enable RLS (recommended to keep it enabled)
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- 3) Drop old SELECT policies on this table (avoid conflicts)
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'fighter_profiles'
      AND (cmd = 'SELECT' OR cmd = 'ALL')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname);
    RAISE NOTICE '✅ Dropped policy: %', r.policyname;
  END LOOP;
END $$;

-- 4) ✅ Create policies for BOTH roles (homepage loads before login)
-- Since the homepage displays fighters without requiring authentication,
-- we need both policies enabled:

-- Policy for authenticated users (logged in)
CREATE POLICY "Authenticated users can view fighter profiles"
ON public.fighter_profiles
FOR SELECT
TO authenticated
USING (true);

-- Policy for anonymous users (not logged in)
-- REQUIRED because homepage loads before login
CREATE POLICY "Anonymous users can view fighter profiles"
ON public.fighter_profiles
FOR SELECT
TO anon
USING (true);

-- 5) Verify the fix worked
SELECT 
    '✅ VERIFICATION' as status,
    policyname,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- 6) Test query as authenticated user
SET ROLE authenticated;
SELECT COUNT(*) as visible_rows_as_authenticated FROM public.fighter_profiles;
SELECT user_id, name, handle FROM public.fighter_profiles LIMIT 3;
RESET ROLE;

-- Done! Refresh your app and fighters should appear.

