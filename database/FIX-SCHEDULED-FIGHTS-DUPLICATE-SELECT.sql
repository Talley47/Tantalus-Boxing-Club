-- ============================================================================
-- FIX: scheduled_fights Duplicate SELECT Policies
-- ============================================================================
-- Consolidates duplicate SELECT policies:
-- - "Authenticated can view scheduled fights"
-- - "Authenticated users can view scheduled fights"
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
  AND tablename = 'scheduled_fights'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 2: Drop duplicate SELECT policies
DROP POLICY IF EXISTS "Authenticated can view scheduled fights" ON public.scheduled_fights;
DROP POLICY IF EXISTS "Authenticated users can view scheduled fights" ON public.scheduled_fights;
DROP POLICY IF EXISTS "Users can view scheduled fights" ON public.scheduled_fights;
DROP POLICY IF EXISTS "Public can view scheduled fights" ON public.scheduled_fights;

-- Step 3: Create a single consolidated SELECT policy for authenticated role
-- Scheduled fights are typically public data, so authenticated users can view all
DO $$
BEGIN
  CREATE POLICY "Authenticated users can view scheduled fights" 
  ON public.scheduled_fights 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Created consolidated SELECT policy for authenticated role';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error creating policy: %', SQLERRM;
END $$;

-- Step 4: Ensure anon role has its own separate policy (if needed)
-- This is separate from authenticated policies, so no duplicate issue
DO $$
BEGIN
  -- Check if anon policy exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'scheduled_fights'
      AND cmd = 'SELECT'
      AND ('anon' = ANY(roles) OR roles IS NULL)
  ) THEN
    CREATE POLICY "Public can view scheduled fights" 
    ON public.scheduled_fights 
    FOR SELECT 
    TO anon 
    USING (true);
    
    RAISE NOTICE '✅ Created anon policy for scheduled fights';
  ELSE
    RAISE NOTICE '✅ Anon policy already exists';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️ Could not create anon policy: %', SQLERRM;
END $$;

-- Step 5: Verify the fix
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
  AND tablename = 'scheduled_fights'
  AND cmd = 'SELECT'
ORDER BY roles, policyname;

-- Step 6: Check for other duplicate policies
SELECT 
  'Other Duplicates Check' as status,
  cmd as command,
  roles,
  COUNT(*) as policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'scheduled_fights'
GROUP BY cmd, roles
HAVING COUNT(*) > 1
ORDER BY cmd, roles;

-- Step 7: Summary
SELECT 
  'Summary' as status,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as authenticated_select_count,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('anon' = ANY(roles) OR roles IS NULL)) as anon_select_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES FOR AUTHENTICATED - Fix successful'
    ELSE '❌ Still has duplicates for authenticated - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'scheduled_fights';

