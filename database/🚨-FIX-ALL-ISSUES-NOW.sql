-- ============================================================================
-- 🚨 COMPREHENSIVE FIX: All RLS Issues
-- ============================================================================
-- This script fixes:
-- 1. "No fighters found" - fighter_profiles table RLS
-- 2. "My Profile page does not load" - profiles table RLS
-- 3. "Please complete your fighter profile" errors - both tables
-- 4. Duplicate anon policies warning
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- ============================================================================
-- PART 1: Fix fighter_profiles table (for rankings, homepage, etc.)
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
  anon_policy_count INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 PART 1: Fixing fighter_profiles table RLS...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Grant permissions (CRITICAL - often missing!)
  GRANT USAGE ON SCHEMA public TO anon, authenticated;
  GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
  
  -- Step 2: Enable RLS
  ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
  
  -- Step 3: Drop ALL existing SELECT policies (clean slate)
  FOR policy_rec IN 
    SELECT policyname, roles
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
      RAISE NOTICE '  ✅ Dropped policy: % (roles: %)', policy_rec.policyname, policy_rec.roles;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '  ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Step 4: Also explicitly drop known policy names (safety net)
  DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Anonymous users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view fighter profiles" ON public.fighter_profiles;
  
  -- Step 5: Create SINGLE anon policy (avoids duplicate warning)
  CREATE POLICY "Public can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO anon 
  USING (true);
  
  RAISE NOTICE '  ✅ Created anon policy: "Public can view fighter profiles"';
  
  -- Step 6: Create authenticated policy
  CREATE POLICY "Authenticated users can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '  ✅ Created authenticated policy: "Authenticated users can view fighter profiles"';
  
  -- Step 7: Verify only ONE anon policy exists
  SELECT COUNT(*) INTO anon_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND ('anon' = ANY(roles) OR roles IS NULL OR roles = '{}');
  
  IF anon_policy_count = 1 THEN
    RAISE NOTICE '  ✅ Verification: Exactly one anon policy exists';
  ELSIF anon_policy_count = 0 THEN
    RAISE WARNING '  ❌ ERROR: No anon policy exists!';
  ELSE
    RAISE WARNING '  ❌ ERROR: % anon policies still exist!', anon_policy_count;
  END IF;
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ Error fixing fighter_profiles: %', SQLERRM;
  RAISE;
END $$;

-- ============================================================================
-- PART 2: Fix profiles table (for My Profile page)
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 PART 2: Fixing profiles table RLS...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Grant permissions
  GRANT USAGE ON SCHEMA public TO authenticated;
  GRANT SELECT ON TABLE public.profiles TO authenticated;
  
  -- Step 2: Enable RLS
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  
  -- Step 3: Drop ALL existing SELECT policies
  FOR policy_rec IN 
    SELECT policyname, roles
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', policy_rec.policyname);
      RAISE NOTICE '  ✅ Dropped policy: % (roles: %)', policy_rec.policyname, policy_rec.roles;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '  ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Step 4: Also explicitly drop known policy names
  DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Authenticated users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;
  
  -- Step 5: Create SINGLE consolidated policy for authenticated users
  -- This allows users to view their own profile AND query profiles for admin checks
  -- Using (true) allows all authenticated users to query profiles (needed for admin checks)
  CREATE POLICY "Authenticated users can view profiles" 
  ON public.profiles 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '  ✅ Created authenticated policy: "Authenticated users can view profiles"';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ Error fixing profiles: %', SQLERRM;
  RAISE;
END $$;

-- ============================================================================
-- PART 3: Verification
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '📊 VERIFICATION: Checking final state...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

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

-- Final summary
SELECT 
  '✅ FIX COMPLETE' as status,
  'All RLS issues should now be resolved.' as message,
  'fighter_profiles: Accessible to both anon and authenticated users' as fighter_profiles_status,
  'profiles: Accessible to authenticated users (My Profile page should work)' as profiles_status;

