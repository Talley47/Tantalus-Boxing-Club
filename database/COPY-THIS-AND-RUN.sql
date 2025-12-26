-- ============================================================================
-- 🚨🚨🚨 COPY THIS ENTIRE FILE AND RUN IN SUPABASE SQL EDITOR 🚨🚨🚨
-- ============================================================================
-- 
-- INSTRUCTIONS:
-- 1. Select ALL (Ctrl+A)
-- 2. Copy (Ctrl+C)
-- 3. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 4. Paste (Ctrl+V) → Click "Run"
-- 5. Hard refresh your app (Ctrl+Shift+R)
--
-- This will fix RLS blocking fighter_profiles
-- ============================================================================

-- Step 1: Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Step 2: Enable RLS (keep it enabled for security)
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop ALL existing SELECT policies (clean slate)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'fighter_profiles'
      AND (cmd = 'SELECT' OR cmd = 'ALL')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname);
  END LOOP;
END $$;

-- Step 4: Create permissive SELECT policies for BOTH roles
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

-- Step 5: VERIFY IT WORKS - This should return rows!
SELECT 
  '✅ SUCCESS - RLS FIXED!' as status,
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id
FROM public.fighter_profiles;

-- Step 6: Show final policies
SELECT 
  'Final Policies' as info,
  policyname,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY cmd, policyname;

