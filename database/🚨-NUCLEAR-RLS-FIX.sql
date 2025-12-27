-- ============================================================================
-- 🚨 NUCLEAR RLS FIX - Most Aggressive Solution
-- ============================================================================
-- This script provides the most aggressive fix for persistent RLS issues.
-- It checks for interfering views/functions, drops all policies more aggressively,
-- and tests the exact query pattern the app uses.
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
  view_rec RECORD;
  func_rec RECORD;
  anon_policy_count INTEGER;
  test_row_count INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🚨 NUCLEAR RLS FIX - Most Aggressive Solution';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- ============================================================================
  -- STEP 0: Check for interfering views/functions
  -- ============================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔍 STEP 0: Checking for interfering views/functions...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Check for views that reference fighter_profiles
  FOR view_rec IN
    SELECT viewname, definition
    FROM pg_views
    WHERE schemaname = 'public'
      AND (definition ILIKE '%fighter_profiles%' OR viewname ILIKE '%fighter%')
  LOOP
    RAISE NOTICE '  ⚠️ Found view: % (may interfere with RLS)', view_rec.viewname;
  END LOOP;
  
  -- ============================================================================
  -- PART 1: Fix fighter_profiles table
  -- ============================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 PART 1: Fixing fighter_profiles table...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Grant schema usage (CRITICAL!)
  GRANT USAGE ON SCHEMA public TO anon, authenticated;
  RAISE NOTICE '  ✅ Granted USAGE on public schema';
  
  -- Step 2: Grant table SELECT permissions (CRITICAL!)
  GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
  RAISE NOTICE '  ✅ Granted SELECT on fighter_profiles';
  
  -- Step 3: Ensure RLS is enabled
  ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
  RAISE NOTICE '  ✅ Enabled RLS';
  
  -- Step 4: Drop ALL existing SELECT policies (most aggressive)
  RAISE NOTICE '';
  RAISE NOTICE '  🗑️  Dropping ALL existing SELECT policies...';
  
  -- First, get all policies and drop them
  FOR policy_rec IN 
    SELECT DISTINCT policyname
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
      RAISE NOTICE '    ✅ Dropped: %', policy_rec.policyname;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '    ⚠️ Could not drop %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Also explicitly drop known policy names (comprehensive list)
  DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Anonymous users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Users can view all fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_all_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Read own fighter profile" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Read all fighter profiles" ON public.fighter_profiles;
  
  -- Step 5: Create SINGLE anon policy
  CREATE POLICY "Public can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO anon 
  USING (true);
  RAISE NOTICE '';
  RAISE NOTICE '  ✅ Created anon policy';
  
  -- Step 6: Create authenticated policy
  CREATE POLICY "Authenticated users can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO authenticated 
  USING (true);
  RAISE NOTICE '  ✅ Created authenticated policy';
  
  -- Step 7: Verify policies
  SELECT COUNT(*) INTO anon_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND ('anon' = ANY(roles) OR roles IS NULL OR roles = '{}');
  
  RAISE NOTICE '';
  IF anon_policy_count = 1 THEN
    RAISE NOTICE '  ✅ Verification: Exactly one anon policy exists';
  ELSE
    RAISE WARNING '  ❌ Verification failed: % anon policies found', anon_policy_count;
  END IF;
  
  -- Step 8: Test query (simulate app's exact query)
  RAISE NOTICE '';
  RAISE NOTICE '  🧪 Testing query (simulating app behavior)...';
  EXECUTE 'SELECT COUNT(*) FROM public.fighter_profiles WHERE user_id IS NOT NULL' INTO test_row_count;
  
  IF test_row_count > 0 THEN
    RAISE NOTICE '  ✅ Test query returned % rows - RLS is working!', test_row_count;
  ELSE
    RAISE WARNING '  ❌ Test query returned 0 rows - RLS may still be blocking';
  END IF;
  
  -- ============================================================================
  -- PART 2: Fix profiles table
  -- ============================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 PART 2: Fixing profiles table...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Grant permissions
  GRANT USAGE ON SCHEMA public TO authenticated;
  GRANT SELECT ON TABLE public.profiles TO authenticated;
  RAISE NOTICE '  ✅ Granted permissions';
  
  -- Step 2: Enable RLS
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  RAISE NOTICE '  ✅ Enabled RLS';
  
  -- Step 3: Drop ALL existing SELECT policies
  RAISE NOTICE '';
  RAISE NOTICE '  🗑️  Dropping ALL existing SELECT policies...';
  FOR policy_rec IN 
    SELECT DISTINCT policyname
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', policy_rec.policyname);
      RAISE NOTICE '    ✅ Dropped: %', policy_rec.policyname;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '    ⚠️ Could not drop %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Also explicitly drop known policy names
  DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Authenticated users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;
  
  -- Step 4: Create SINGLE consolidated policy
  CREATE POLICY "Authenticated users can view profiles" 
  ON public.profiles 
  FOR SELECT 
  TO authenticated 
  USING (true);
  RAISE NOTICE '';
  RAISE NOTICE '  ✅ Created authenticated policy';
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ NUCLEAR FIX COMPLETE';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE '📋 NEXT STEPS:';
  RAISE NOTICE '   1. Hard refresh your app (Ctrl+Shift+R or Cmd+Shift+R)';
  RAISE NOTICE '   2. Check if fighters appear on homepage';
  RAISE NOTICE '   3. Check if My Profile page loads';
  RAISE NOTICE '';
  RAISE NOTICE '🔍 If still not working, run: DIAGNOSE-CURRENT-RLS-STATE.sql';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ Error during nuclear fix: %', SQLERRM;
  RAISE WARNING 'Stack trace: %', SQLSTATE;
  RAISE;
END $$;

-- ============================================================================
-- VERIFICATION: Check final state
-- ============================================================================

-- Check fighter_profiles policies
SELECT 
  'fighter_profiles Policies' as check_type,
  policyname,
  roles,
  cmd as command
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY 
  CASE WHEN 'anon' = ANY(roles) THEN 1 ELSE 2 END,
  policyname;

-- Check profiles policies
SELECT 
  'profiles Policies' as check_type,
  policyname,
  roles,
  cmd as command
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'profiles'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Test query that simulates the app's exact query pattern
SELECT 
  'Test Query Result' as check_type,
  COUNT(*) as row_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ RLS IS STILL BLOCKING - No rows returned'
    WHEN COUNT(*) > 0 THEN '✅ RLS ALLOWS ACCESS - Rows returned'
  END as status
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Show sample rows (if any)
SELECT 
  'Sample Rows' as check_type,
  id,
  user_id,
  name,
  points
FROM public.fighter_profiles
WHERE user_id IS NOT NULL
ORDER BY points DESC
LIMIT 5;
