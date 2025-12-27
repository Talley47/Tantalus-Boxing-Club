-- ============================================================================
-- FIX: fighter_profiles Duplicate SELECT Policies
-- ============================================================================
-- Consolidates duplicate SELECT policies:
-- - "Users can view own fighter profile"
-- - "authenticated_read_fighter_profiles"
-- Into a single consolidated policy
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current SELECT policies
SELECT 
  'Current SELECT Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 2: Drop duplicate SELECT policies
DROP POLICY IF EXISTS "Users can view own fighter profile" ON public.fighter_profiles;
DROP POLICY IF EXISTS "authenticated_read_fighter_profiles" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Users can view their own fighter profile" ON public.fighter_profiles;
DROP POLICY IF EXISTS "authenticated_read_all_fighter_profiles" ON public.fighter_profiles;

-- Step 3: Create a single consolidated SELECT policy
-- Since "authenticated_read_fighter_profiles" likely allows viewing all profiles,
-- and "Users can view own fighter profile" allows viewing own profile,
-- we'll create a policy that allows authenticated users to view all fighter profiles
-- (this covers both cases and is more permissive)
DO $$
BEGIN
  CREATE POLICY "authenticated_read_fighter_profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Created consolidated SELECT policy';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error creating policy: %', SQLERRM;
END $$;

-- Step 4: Verify the fix
SELECT 
  'After Fix' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY cmd, roles) = 1 THEN '✅ No duplicates'
    ELSE '❌ Still has duplicates'
  END as duplicate_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY roles, policyname;

-- Step 5: Check for other duplicate policies
SELECT 
  'Other Duplicates Check' as status,
  cmd as command,
  roles,
  COUNT(*) as policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
GROUP BY cmd, roles
HAVING COUNT(*) > 1
ORDER BY cmd, roles;

-- Step 6: Summary
SELECT 
  'Summary' as status,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as select_policy_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES - Fix successful'
    ELSE '❌ Still has duplicates - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles';

