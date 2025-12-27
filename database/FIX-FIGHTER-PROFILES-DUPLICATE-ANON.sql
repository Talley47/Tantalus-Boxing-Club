-- ============================================================================
-- TARGETED FIX: Consolidate duplicate anon SELECT policies on fighter_profiles
-- ============================================================================
-- This script specifically fixes the "Multiple Permissive Policies" warning
-- for fighter_profiles table for the anon role
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
  policies_dropped TEXT[] := ARRAY[]::TEXT[];
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 Fixing duplicate anon SELECT policies on fighter_profiles...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Drop ALL existing SELECT policies for anon role
  -- This includes policies that might be assigned to anon explicitly or implicitly
  FOR policy_rec IN 
    SELECT policyname, roles
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT'
      AND (
        'anon' = ANY(roles) 
        OR roles IS NULL 
        OR roles = '{}'
        OR policyname IN ('Public can view fighter profiles', 'anon_read_fighter_profiles')
      )
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
      policies_dropped := array_append(policies_dropped, policy_rec.policyname);
      RAISE NOTICE '  ✅ Dropped policy: % (roles: %)', policy_rec.policyname, policy_rec.roles;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '  ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Step 2: Also explicitly drop known policy names (in case they weren't caught above)
  DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_all_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Anonymous users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Public can view all fighter profiles" ON public.fighter_profiles;
  
  -- Step 3: Create a SINGLE consolidated policy for anon role
  CREATE POLICY "Public can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO anon 
  USING (true);
  
  RAISE NOTICE '';
  RAISE NOTICE '  ✅ Created single anon policy: "Public can view fighter profiles"';
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ Fix complete!';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ Error fixing duplicate policies: %', SQLERRM;
  RAISE;
END $$;

-- Verification: Check that only ONE anon policy exists
SELECT 
  'Verification' as check_type,
  COUNT(*) as anon_policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ ERROR: No anon policy exists!'
    WHEN COUNT(*) = 1 THEN '✅ SUCCESS: Exactly one anon policy exists'
    WHEN COUNT(*) > 1 THEN '❌ STILL HAS DUPLICATES: Multiple anon policies still exist'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL OR roles = '{}');

-- Show final policy state
SELECT 
  'Final Policy State' as check_type,
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

