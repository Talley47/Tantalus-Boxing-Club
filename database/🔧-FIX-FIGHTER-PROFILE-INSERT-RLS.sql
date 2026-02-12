-- ============================================================================
-- 🔧 FIX: Fighter Profile INSERT RLS Policy
-- ============================================================================
-- This ensures authenticated users can INSERT their own fighter profiles
-- ============================================================================

-- Step 1: Check current INSERT policies
SELECT 
  'Current INSERT Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'INSERT'
ORDER BY policyname;

-- Step 2: Drop existing INSERT policies (we'll recreate them cleanly)
DROP POLICY IF EXISTS "Users insert own profile" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Users can insert own fighter profile" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Users and admins can insert fighter profiles" ON public.fighter_profiles;

-- Step 3: Create INSERT policy for authenticated users
-- This allows users to insert their own fighter profile (user_id must match auth.uid())
CREATE POLICY "Users can insert own fighter profile" 
ON public.fighter_profiles 
FOR INSERT 
TO authenticated
WITH CHECK (
  (select auth.uid()) = user_id
);

-- Step 4: Verify the policy was created
SELECT 
  '✅ INSERT Policy Created' as status,
  policyname,
  cmd as command,
  roles,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'INSERT';

-- ============================================================================
-- ✅ DONE: Users can now insert their own fighter profiles
-- ============================================================================
