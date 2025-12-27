-- ============================================================================
-- 🚨 DEFINITIVE RLS FIX - FINAL VERSION
-- ============================================================================
-- This script FIXES EVERYTHING that could cause RLS blocking
-- It's aggressive and comprehensive - fixes permissions, policies, and checks for interference
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
  view_rec RECORD;
  func_rec RECORD;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🚨 STARTING DEFINITIVE RLS FIX';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  
  -- ============================================================================
  -- STEP 1: Grant schema permissions (CRITICAL - must be first!)
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
  -- STEP 4: Drop ALL existing SELECT policies (clean slate)
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 4: Dropping ALL existing SELECT policies...';
  
  -- Drop policies for fighter_profiles
  FOR policy_rec IN 
    SELECT policyname
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
      RAISE NOTICE '  ✅ Dropped policy: %', policy_rec.policyname;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '  ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Drop policies for profiles
  FOR policy_rec IN 
    SELECT policyname
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', policy_rec.policyname);
      RAISE NOTICE '  ✅ Dropped policy: %', policy_rec.policyname;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '  ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- ============================================================================
  -- STEP 5: Create NEW permissive policies for fighter_profiles
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 5: Creating NEW permissive policies for fighter_profiles...';
  
  -- Policy for anon role (public access - CRITICAL for homepage)
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
  -- STEP 7: Check for and handle interfering views
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE 'Step 7: Checking for interfering views...';
  
  FOR view_rec IN
    SELECT viewname, viewowner
    FROM pg_views
    WHERE schemaname = 'public'
      AND (definition ILIKE '%fighter_profiles%' OR viewname ILIKE '%fighter%')
  LOOP
    IF view_rec.viewowner = 'postgres' THEN
      RAISE NOTICE '  ⚠️ Found view: % (owned by postgres - might bypass RLS)', view_rec.viewname;
      RAISE NOTICE '     If app uses this view, it might bypass RLS. Check app code.';
    ELSE
      RAISE NOTICE '  ✅ Found view: % (owned by %)', view_rec.viewname, view_rec.viewowner;
    END IF;
  END LOOP;
  
  -- ============================================================================
  -- STEP 8: Verify the fix worked
  -- ============================================================================
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Step 8: Verifying fix...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Check anon policies
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT' 
      AND 'anon' = ANY(roles)
  ) THEN
    RAISE NOTICE '  ✅ anon SELECT policy exists for fighter_profiles';
  ELSE
    RAISE WARNING '  ❌ anon SELECT policy MISSING for fighter_profiles';
  END IF;
  
  -- Check authenticated policies
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT' 
      AND 'authenticated' = ANY(roles)
  ) THEN
    RAISE NOTICE '  ✅ authenticated SELECT policy exists for fighter_profiles';
  ELSE
    RAISE WARNING '  ❌ authenticated SELECT policy MISSING for fighter_profiles';
  END IF;
  
  -- Check permissions
  IF has_table_privilege('anon', 'public.fighter_profiles', 'SELECT') THEN
    RAISE NOTICE '  ✅ anon has SELECT permission on fighter_profiles';
  ELSE
    RAISE WARNING '  ❌ anon MISSING SELECT permission on fighter_profiles';
  END IF;
  
  IF has_table_privilege('authenticated', 'public.fighter_profiles', 'SELECT') THEN
    RAISE NOTICE '  ✅ authenticated has SELECT permission on fighter_profiles';
  ELSE
    RAISE WARNING '  ❌ authenticated MISSING SELECT permission on fighter_profiles';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ FIX COMPLETE';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Check the verification queries below';
  RAISE NOTICE '  2. If Check 4 shows row_count > 0, RLS is fixed!';
  RAISE NOTICE '  3. Hard refresh your app (Ctrl+Shift+R or Cmd+Shift+R)';
  RAISE NOTICE '  4. Fighters should appear immediately';
  RAISE NOTICE '';
  
EXCEPTION WHEN OTHERS THEN
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

-- Verification 3: Test query as anon (simulates browser)
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
  RAISE NOTICE 'Verification 3: Test Query as anon Role';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count = 0 THEN
    RAISE WARNING '❌ RLS STILL BLOCKING: anon role sees 0 rows';
    RAISE WARNING '   This should NOT happen after running this fix.';
    RAISE WARNING '   Please check:';
    RAISE WARNING '   1. Did the script run without errors?';
    RAISE WARNING '   2. Are there any views/functions interfering?';
    RAISE WARNING '   3. Run DIAGNOSE-EXACT-PROBLEM.sql for more details';
  ELSE
    RAISE NOTICE '✅ SUCCESS: anon role sees % rows', row_count;
    RAISE NOTICE '   RLS is working correctly!';
    RAISE NOTICE '   Hard refresh your app (Ctrl+Shift+R) and fighters should appear.';
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Verification 4: Show sample rows (if any)
SELECT 
  'Verification 4: Sample Rows' as check_type,
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

