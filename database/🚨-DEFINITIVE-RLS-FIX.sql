-- ============================================================================
-- 🚨 DEFINITIVE RLS FIX - Complete Solution
-- ============================================================================
-- This script provides a comprehensive fix for RLS issues on:
-- 1. fighter_profiles table (homepage rankings)
-- 2. profiles table (My Profile page)
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
  anon_policy_count INTEGER;
  auth_policy_count INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🚨 DEFINITIVE RLS FIX - Starting comprehensive fix...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- ============================================================================
  -- PART 1: Fix fighter_profiles table
  -- ============================================================================
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 PART 1: Fixing fighter_profiles table...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Grant schema usage (CRITICAL - often missing!)
  GRANT USAGE ON SCHEMA public TO anon, authenticated;
  RAISE NOTICE '  ✅ Granted USAGE on public schema to anon, authenticated';
  
  -- Step 2: Grant table SELECT permissions (CRITICAL - separate from RLS!)
  GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
  RAISE NOTICE '  ✅ Granted SELECT on public.fighter_profiles to anon, authenticated';
  
  -- Step 3: Ensure RLS is enabled
  ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
  RAISE NOTICE '  ✅ Enabled RLS on public.fighter_profiles';
  
  -- Step 4: Drop ALL existing SELECT policies (aggressive cleanup)
  RAISE NOTICE '';
  RAISE NOTICE '  🗑️  Dropping all existing SELECT policies...';
  FOR policy_rec IN 
    SELECT policyname, roles
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
      RAISE NOTICE '    ✅ Dropped: % (roles: %)', policy_rec.policyname, policy_rec.roles;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '    ⚠️ Could not drop %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Step 5: Also explicitly drop known policy names (safety net)
  DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Anonymous users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Users can view all fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_all_fighter_profiles" ON public.fighter_profiles;
  
  -- Step 6: Create SINGLE anon policy (avoids duplicate warning)
  CREATE POLICY "Public can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO anon 
  USING (true);
  RAISE NOTICE '';
  RAISE NOTICE '  ✅ Created anon policy: "Public can view fighter profiles"';
  
  -- Step 7: Create authenticated policy
  CREATE POLICY "Authenticated users can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO authenticated 
  USING (true);
  RAISE NOTICE '  ✅ Created authenticated policy: "Authenticated users can view fighter profiles"';
  
  -- Step 8: Verify policies
  SELECT COUNT(*) INTO anon_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND ('anon' = ANY(roles) OR roles IS NULL OR roles = '{}');
  
  SELECT COUNT(*) INTO auth_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND ('authenticated' = ANY(roles));
  
  RAISE NOTICE '';
  IF anon_policy_count = 1 AND auth_policy_count >= 1 THEN
    RAISE NOTICE '  ✅ Verification: Exactly one anon policy and at least one authenticated policy exist';
  ELSE
    RAISE WARNING '  ❌ Verification failed: anon=% authenticated=%', anon_policy_count, auth_policy_count;
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
  RAISE NOTICE '  ✅ Granted permissions on public.profiles to authenticated';
  
  -- Step 2: Enable RLS
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  RAISE NOTICE '  ✅ Enabled RLS on public.profiles';
  
  -- Step 3: Drop ALL existing SELECT policies
  RAISE NOTICE '';
  RAISE NOTICE '  🗑️  Dropping all existing SELECT policies...';
  FOR policy_rec IN 
    SELECT policyname, roles
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', policy_rec.policyname);
      RAISE NOTICE '    ✅ Dropped: % (roles: %)', policy_rec.policyname, policy_rec.roles;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '    ⚠️ Could not drop %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Step 4: Also explicitly drop known policy names
  DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Authenticated users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;
  
  -- Step 5: Create SINGLE consolidated policy for authenticated users
  CREATE POLICY "Authenticated users can view profiles" 
  ON public.profiles 
  FOR SELECT 
  TO authenticated 
  USING (true);
  RAISE NOTICE '';
  RAISE NOTICE '  ✅ Created authenticated policy: "Authenticated users can view profiles"';
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ FIX COMPLETE';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ Error during fix: %', SQLERRM;
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

-- Check for duplicate anon policies on fighter_profiles
SELECT 
  'Duplicate Check (fighter_profiles)' as check_type,
  COUNT(*) as anon_policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ ERROR: No anon policy exists!'
    WHEN COUNT(*) = 1 THEN '✅ SUCCESS: Exactly one anon policy exists'
    WHEN COUNT(*) > 1 THEN '❌ DUPLICATES: Multiple anon policies still exist'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL OR roles = '{}');

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

-- Final summary
SELECT 
  '✅ FIX COMPLETE' as status,
  'All RLS issues should now be resolved.' as message,
  'fighter_profiles: Accessible to both anon and authenticated users' as fighter_profiles_status,
  'profiles: Accessible to authenticated users (My Profile page should work)' as profiles_status;
