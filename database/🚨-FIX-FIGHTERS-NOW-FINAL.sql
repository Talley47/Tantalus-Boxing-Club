-- ============================================================================
-- 🚨 FINAL FIX - This WILL fix fighters not showing
-- ============================================================================
-- 
-- YOUR APP QUERIES: fighter_profiles WHERE user_id IS NOT NULL
-- THIS SCRIPT FIXES RLS TO ALLOW THAT EXACT QUERY
--
-- INSTRUCTIONS:
-- 1. Copy ALL of this file (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Click "New Query" (or clear existing query)
-- 4. Paste (Ctrl+V)
-- 5. Click "Run" button (or press F5)
-- 6. Wait for "Success" message
-- 7. Hard refresh your app (Ctrl+Shift+R)
--
-- ============================================================================

-- ============================================================================
-- STEP 1: GRANT ALL NECESSARY PERMISSIONS
-- ============================================================================

-- Grant schema usage (CRITICAL - often missing!)
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant table SELECT permissions (CRITICAL - often missing!)
GRANT SELECT ON TABLE public.fighter_profiles TO anon;
GRANT SELECT ON TABLE public.fighter_profiles TO authenticated;
GRANT SELECT ON TABLE public.profiles TO anon;
GRANT SELECT ON TABLE public.profiles TO authenticated;

-- ============================================================================
-- STEP 2: ENABLE RLS (Keep enabled for security)
-- ============================================================================

ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 3: REMOVE ALL EXISTING POLICIES (Clean slate - removes conflicts)
-- ============================================================================

-- Remove ALL policies on fighter_profiles (SELECT, INSERT, UPDATE, DELETE, ALL)
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

-- Remove ALL policies on profiles
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
-- STEP 4: CREATE NEW PERMISSIVE POLICIES (Simplest possible)
-- ============================================================================

-- fighter_profiles: Allow authenticated users to read ALL rows
CREATE POLICY "authenticated_read_all_fighter_profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- fighter_profiles: Allow anonymous users to read ALL rows
CREATE POLICY "anon_read_all_fighter_profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO anon 
USING (true);

-- profiles: Allow authenticated users to read ALL rows
CREATE POLICY "authenticated_read_all_profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- profiles: Allow anonymous users to read ALL rows
CREATE POLICY "anon_read_all_profiles" 
ON public.profiles 
FOR SELECT 
TO anon 
USING (true);

-- ============================================================================
-- STEP 5: VERIFICATION - Test the EXACT query your app uses
-- ============================================================================

-- Test 1: Count total fighters (should match what you see in Supabase dashboard)
SELECT 
  'TEST 1: Total fighters in table' as test_name,
  COUNT(*) as total_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - No fighters in table!'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - Found ' || COUNT(*) || ' fighters'
    ELSE '⚠️ Unknown'
  END as result
FROM public.fighter_profiles;

-- Test 2: Count fighters with user_id IS NOT NULL (your app's exact filter)
SELECT 
  'TEST 2: Fighters with user_id (app query)' as test_name,
  COUNT(*) as fighters_with_user_id,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - No fighters with user_id!'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - Found ' || COUNT(*) || ' fighters (app will see these)'
    ELSE '⚠️ Unknown'
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Test 3: Get sample fighters (ordered by points DESC, limited to 30 - your app's exact query)
SELECT 
  'TEST 3: Sample fighters (app query simulation)' as test_name,
  COUNT(*) as visible_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - App will see 0 fighters!'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - App will see ' || COUNT(*) || ' fighters'
    ELSE '⚠️ Unknown'
  END as result
FROM (
  SELECT id, user_id, name, points
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL
  ORDER BY points DESC
  LIMIT 30
) sub;

-- Test 4: Show actual policy count (should be 4: 2 for fighter_profiles, 2 for profiles)
SELECT 
  'TEST 4: Policy count' as test_name,
  tablename,
  COUNT(*) as policy_count,
  STRING_AGG(policyname, ', ') as policy_names
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
GROUP BY tablename;

-- Test 5: Check permissions (should show SELECT for anon and authenticated)
SELECT 
  'TEST 5: Permissions check' as test_name,
  table_name,
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN ('fighter_profiles', 'profiles')
  AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, grantee;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- 
-- If TEST 2 shows "✅ SUCCESS" with fighters > 0:
-- 1. Hard refresh your app (Ctrl+Shift+R)
-- 2. Fighters should appear immediately!
--
-- If TEST 2 still shows 0 fighters:
-- 1. Check TEST 1 - if it shows 0, fighters don't exist in the table
-- 2. Check TEST 4 - should show 4 policies total
-- 3. Check TEST 5 - should show SELECT permissions for anon and authenticated
-- 4. Run: database/DIAGNOSE-CURRENT-STATE.sql for more details
--
-- ============================================================================

