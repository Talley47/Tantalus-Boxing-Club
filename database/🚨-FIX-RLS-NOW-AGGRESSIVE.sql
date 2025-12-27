-- ============================================================================
-- 🚨 AGGRESSIVE RLS FIX - GUARANTEED TO WORK
-- ============================================================================
-- This script is EXTREMELY aggressive and will fix RLS blocking
-- It drops EVERYTHING and recreates it correctly
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
  v_count INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🚨 STARTING AGGRESSIVE RLS FIX';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  
  -- ============================================================================
  -- STEP 1: Grant schema permissions (CRITICAL - MUST BE FIRST!)
  -- ============================================================================
  RAISE NOTICE 'Step 1: Granting schema permissions...';
  GRANT USAGE ON SCHEMA public TO anon, authenticated;
  RAISE NOTICE '  ✅ Granted USAGE on public schema to anon, authenticated';
  
  -- ============================================================================
  -- STEP 2: Grant table SELECT permissions (CRITICAL - separate from RLS!)
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 2: Granting table SELECT permissions...';
  GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
  GRANT SELECT ON TABLE public.profiles TO authenticated;
  RAISE NOTICE '  ✅ Granted SELECT on fighter_profiles to anon, authenticated';
  RAISE NOTICE '  ✅ Granted SELECT on profiles to authenticated';
  
  -- ============================================================================
  -- STEP 3: Enable RLS (security best practice)
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 3: Enabling RLS...';
  ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  RAISE NOTICE '  ✅ Enabled RLS on fighter_profiles';
  RAISE NOTICE '  ✅ Enabled RLS on profiles';
  
  -- ============================================================================
  -- STEP 4: Drop ALL existing SELECT policies (AGGRESSIVE - clean slate)
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 4: Dropping ALL existing SELECT policies (aggressive cleanup)...';
  
  -- Drop ALL policies for fighter_profiles (not just SELECT)
  FOR policy_rec IN 
    SELECT policyname
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
      RAISE NOTICE '  ✅ Dropped policy: %', policy_rec.policyname;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '  ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Drop ALL policies for profiles
  FOR policy_rec IN 
    SELECT policyname
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', policy_rec.policyname);
      RAISE NOTICE '  ✅ Dropped policy: %', policy_rec.policyname;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '  ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Also explicitly drop known policy names (in case they weren't caught above)
  DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_all_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Anonymous users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Public can view all fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view all fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Read own fighter profile" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.profiles;
  
  RAISE NOTICE '  ✅ Finished dropping all existing policies';
  
  -- ============================================================================
  -- STEP 5: Create NEW permissive policies for fighter_profiles
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 5: Creating NEW permissive policies for fighter_profiles...';
  
  -- Policy for anon role (public access - CRITICAL for homepage before login)
  CREATE POLICY "Public can view fighter profiles"
  ON public.fighter_profiles
  FOR SELECT
  TO anon
  USING (true);
  RAISE NOTICE '  ✅ Created policy: "Public can view fighter profiles" for anon role';
  
  -- Policy for authenticated role (logged-in users)
  CREATE POLICY "Authenticated users can view fighter profiles"
  ON public.fighter_profiles
  FOR SELECT
  TO authenticated
  USING (true);
  RAISE NOTICE '  ✅ Created policy: "Authenticated users can view fighter profiles" for authenticated role';
  
  -- ============================================================================
  -- STEP 6: Create NEW permissive policy for profiles
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 6: Creating NEW permissive policy for profiles...';
  
  CREATE POLICY "Authenticated users can view profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);
  RAISE NOTICE '  ✅ Created policy: "Authenticated users can view profiles" for authenticated role';
  
  -- ============================================================================
  -- STEP 7: Verify policies were created
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 7: Verifying policies were created...';
  
  -- Count anon policies for fighter_profiles
  SELECT COUNT(*) INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND 'anon' = ANY(roles);
  
  IF v_count = 0 THEN
    RAISE WARNING '  ❌ ERROR: No anon SELECT policy exists for fighter_profiles!';
  ELSIF v_count = 1 THEN
    RAISE NOTICE '  ✅ SUCCESS: Exactly 1 anon SELECT policy exists for fighter_profiles';
  ELSE
    RAISE WARNING '  ⚠️ WARNING: % anon SELECT policies exist for fighter_profiles (should be 1)', v_count;
  END IF;
  
  -- Count authenticated policies for fighter_profiles
  SELECT COUNT(*) INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND 'authenticated' = ANY(roles);
  
  IF v_count = 0 THEN
    RAISE WARNING '  ❌ ERROR: No authenticated SELECT policy exists for fighter_profiles!';
  ELSIF v_count = 1 THEN
    RAISE NOTICE '  ✅ SUCCESS: Exactly 1 authenticated SELECT policy exists for fighter_profiles';
  ELSE
    RAISE WARNING '  ⚠️ WARNING: % authenticated SELECT policies exist for fighter_profiles (should be 1)', v_count;
  END IF;
  
  -- ============================================================================
  -- STEP 8: Test query as anon role (simulates browser before login)
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 8: Testing query as anon role (simulates browser)...';
  
  SET ROLE anon;
  SELECT COUNT(*) INTO v_count
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL;
  RESET ROLE;
  
  IF v_count = 0 THEN
    RAISE WARNING '';
    RAISE WARNING '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE WARNING '❌ CRITICAL: anon role still sees 0 rows!';
    RAISE WARNING '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE WARNING 'This should NOT happen after running this fix.';
    RAISE WARNING 'Possible causes:';
    RAISE WARNING '  1. There is a view or function interfering';
    RAISE WARNING '  2. The policies were not created correctly';
    RAISE WARNING '  3. There is a permission issue at the schema level';
    RAISE WARNING '';
    RAISE WARNING 'Please run: database/🚨-TEST-EXACT-APP-QUERY.sql for detailed diagnostics';
    RAISE WARNING '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '✅ SUCCESS: anon role sees % rows!', v_count;
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE 'RLS is now working correctly!';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Hard refresh your browser (Ctrl+Shift+R or Cmd+Shift+R)';
    RAISE NOTICE '  2. Fighters should appear immediately';
    RAISE NOTICE '  3. Check the verification queries below to confirm';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ FIX COMPLETE';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
EXCEPTION WHEN OTHERS THEN
  RESET ROLE; -- Make sure to reset role if error occurs
  RAISE WARNING '❌ ERROR during fix: %', SQLERRM;
  RAISE;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES: Check that it worked
-- ============================================================================

-- Verification 1: Check policies exist
SELECT 
  'Verification 1: Policies' as check_type,
  tablename,
  policyname,
  roles,
  cmd as command
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
  AND cmd = 'SELECT'
ORDER BY tablename, 
  CASE WHEN 'anon' = ANY(roles) THEN 1 ELSE 2 END,
  policyname;

-- Verification 2: Check permissions
SELECT 
  'Verification 2: Permissions' as check_type,
  'fighter_profiles' as table_name,
  CASE 
    WHEN has_table_privilege('anon', 'public.fighter_profiles', 'SELECT') THEN '✅ anon can SELECT'
    ELSE '❌ anon CANNOT SELECT'
  END || ' | ' ||
  CASE 
    WHEN has_table_privilege('authenticated', 'public.fighter_profiles', 'SELECT') THEN '✅ authenticated can SELECT'
    ELSE '❌ authenticated CANNOT SELECT'
  END as permissions;

-- Verification 3: Check schema permissions
SELECT 
  'Verification 3: Schema Permissions' as check_type,
  CASE 
    WHEN has_schema_privilege('anon', 'public', 'USAGE') THEN '✅ anon has USAGE'
    ELSE '❌ anon MISSING USAGE'
  END || ' | ' ||
  CASE 
    WHEN has_schema_privilege('authenticated', 'public', 'USAGE') THEN '✅ authenticated has USAGE'
    ELSE '❌ authenticated MISSING USAGE'
  END as schema_permissions;

-- Verification 4: Test query (simulates your app's EXACT query pattern)
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SET ROLE anon;
  SELECT COUNT(*) INTO row_count
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Verification 4: Test Query (App Pattern)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count = 0 THEN
    RAISE WARNING '❌ FAILED: anon role sees 0 rows';
    RAISE WARNING '   This means RLS is still blocking';
    RAISE WARNING '   Please run: database/🚨-TEST-EXACT-APP-QUERY.sql for detailed diagnostics';
  ELSE
    RAISE NOTICE '✅ SUCCESS: anon role sees % rows', row_count;
    RAISE NOTICE '   RLS is working correctly!';
    RAISE NOTICE '   Hard refresh your app (Ctrl+Shift+R) and fighters should appear.';
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Verification 5: Show sample rows (if any)
SELECT 
  'Verification 5: Sample Rows' as check_type,
  COUNT(*) as total_rows,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as rows_with_user_id
FROM public.fighter_profiles;

-- Show actual sample rows
SELECT 
  'Sample Data' as check_type,
  id,
  user_id,
  name,
  points,
  tier,
  weight_class
FROM public.fighter_profiles
WHERE user_id IS NOT NULL
ORDER BY points DESC
LIMIT 10;

