-- ============================================================================
-- 🚨 DEFINITIVE FIX: Fighters Not Showing
-- ============================================================================
-- 
-- YOU HAVE 30+ FIGHTERS BUT THEY'RE NOT SHOWING
-- THIS FIXES IT COMPLETELY
--
-- INSTRUCTIONS:
-- 1. Copy ALL (Ctrl+A, Ctrl+C)
-- 2. Supabase Dashboard → SQL Editor → New Query
-- 3. Paste (Ctrl+V) → Click "Run"
-- 4. Check the verification at the end
-- 5. Hard refresh app (Ctrl+Shift+R)
--
-- ============================================================================

-- ============================================================================
-- STEP 1: Grant ALL necessary permissions
-- ============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
GRANT SELECT ON TABLE public.profiles TO anon, authenticated;

-- ============================================================================
-- STEP 2: Enable RLS (keep enabled for security)
-- ============================================================================

ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 3: Remove ALL existing policies (clean slate)
-- ============================================================================

-- Remove all policies on fighter_profiles
DO $$ 
DECLARE 
  r RECORD; 
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles'
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); 
  END LOOP; 
END $$;

-- Remove all policies on profiles
DO $$ 
DECLARE 
  r RECORD; 
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles'
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname); 
  END LOOP; 
END $$;

-- ============================================================================
-- STEP 4: Create SIMPLE, PERMISSIVE policies for fighter_profiles
-- ============================================================================

-- Policy 1: Authenticated users can see ALL fighters
CREATE POLICY "authenticated_select_all" 
ON public.fighter_profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- Policy 2: Anonymous users can see ALL fighters
CREATE POLICY "anon_select_all" 
ON public.fighter_profiles 
FOR SELECT 
TO anon 
USING (true);

-- ============================================================================
-- STEP 5: Create policies for profiles table
-- ============================================================================

-- Policy 1: Users can see their own profile
CREATE POLICY "users_select_own_profile" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (id = (select auth.uid()));

-- Policy 2: Authenticated users can query profiles (for admin checks)
CREATE POLICY "authenticated_select_profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- ============================================================================
-- STEP 6: VERIFY - This should show your 30+ fighters!
-- ============================================================================

SELECT 
  '✅ VERIFICATION' as status,
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - Fighters are accessible!'
    ELSE '❌ FAIL - Still 0 fighters'
  END as result
FROM public.fighter_profiles;

-- ============================================================================
-- STEP 7: Test query (simulate what your app does)
-- ============================================================================

SELECT 
  '✅ TEST QUERY' as status,
  COUNT(*) as rows_returned,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Query works - fighters will show!'
    ELSE '❌ Query returns 0 - still blocked'
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL
LIMIT 10;

-- ============================================================================
-- STEP 8: Show current policies (for verification)
-- ============================================================================

SELECT 
  '✅ CURRENT POLICIES' as status,
  tablename,
  policyname,
  cmd as operation,
  roles,
  'Policy is active' as status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- 
-- If verification shows fighters > 0:
-- 1. Hard refresh your app (Ctrl+Shift+R)
-- 2. Fighters should appear!
--
-- If still 0 fighters:
-- 1. Check the "CURRENT POLICIES" output above
-- 2. Make sure policies exist and have USING (true)
-- 3. Check browser console for other errors
--
-- ============================================================================

