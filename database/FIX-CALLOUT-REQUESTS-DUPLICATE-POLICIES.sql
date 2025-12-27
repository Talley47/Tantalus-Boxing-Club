-- ============================================================================
-- FIX: callout_requests Multiple Permissive Policies
-- ============================================================================
-- Consolidates duplicate DELETE policies for authenticated role
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current DELETE policies on callout_requests
SELECT 
  'Current DELETE Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'DELETE'
ORDER BY policyname;

-- Step 2: Check for duplicate policies (same role and action)
SELECT 
  'Duplicate Policies Detected' as status,
  cmd as command,
  roles,
  COUNT(*) as policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'DELETE'
GROUP BY cmd, roles
HAVING COUNT(*) > 1;

-- Step 3: Drop duplicate DELETE policies and create a single consolidated one
DO $$
DECLARE
  policy_name TEXT;
  policy_qual TEXT;
  policy_with_check TEXT;
  policy_roles TEXT;
  consolidated_qual TEXT := 'false'; -- Start with false, will build OR conditions
BEGIN
  -- Find all DELETE policies for authenticated role
  FOR policy_name, policy_qual, policy_with_check, policy_roles IN
    SELECT 
      policyname,
      qual,
      with_check,
      roles::text
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND cmd = 'DELETE'
      AND ('authenticated' = ANY(roles) OR roles IS NULL)
    ORDER BY policyname
  LOOP
    -- Drop the duplicate policy
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.callout_requests', policy_name);
    RAISE NOTICE '✅ Dropped duplicate policy: %', policy_name;
    
    -- Build consolidated USING clause
    -- Combine all the conditions with OR
    IF policy_qual IS NOT NULL AND policy_qual != '' THEN
      IF consolidated_qual = 'false' THEN
        consolidated_qual := policy_qual;
      ELSE
        consolidated_qual := consolidated_qual || ' OR (' || policy_qual || ')';
      END IF;
    END IF;
  END LOOP;
  
  -- If we found policies, create a single consolidated one
  IF consolidated_qual != 'false' THEN
    -- Check if is_admin_user function exists
    IF EXISTS (
      SELECT 1 FROM pg_proc 
      WHERE proname = 'is_admin_user' 
      AND pronamespace = 'public'::regnamespace
    ) THEN
      -- Use function (simpler and optimized)
      CREATE POLICY "Admins can delete callouts" 
      ON public.callout_requests 
      FOR DELETE 
      TO authenticated 
      USING (is_admin_user());
      
      RAISE NOTICE '✅ Created consolidated DELETE policy using is_admin_user()';
    ELSE
      -- Fallback: use the consolidated qual or check profiles table
      IF consolidated_qual LIKE '%admin%' OR consolidated_qual LIKE '%role%' THEN
        -- Use optimized (select auth.uid()) for admin check
        CREATE POLICY "Admins can delete callouts" 
        ON public.callout_requests 
        FOR DELETE 
        TO authenticated 
        USING (
          EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = (select auth.uid()) 
            AND role = 'admin'
          )
        );
        
        RAISE NOTICE '✅ Created consolidated DELETE policy using (select auth.uid())';
      ELSE
        -- Use the consolidated qual as-is
        CREATE POLICY "Admins can delete callouts" 
        ON public.callout_requests 
        FOR DELETE 
        TO authenticated 
        USING (consolidated_qual);
        
        RAISE NOTICE '✅ Created consolidated DELETE policy with combined conditions';
      END IF;
    END IF;
  ELSE
    RAISE NOTICE '⚠️ No DELETE policies found to consolidate';
  END IF;
END $$;

-- Step 4: Check for other duplicate policies (INSERT, UPDATE, SELECT)
SELECT 
  'Other Potential Duplicates' as status,
  cmd as command,
  roles,
  COUNT(*) as policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
GROUP BY cmd, roles
HAVING COUNT(*) > 1
ORDER BY cmd, roles;

-- Step 5: Verify the fix
SELECT 
  'After Fix' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'DELETE'
ORDER BY policyname;

-- Step 6: Summary
SELECT 
  'Summary' as status,
  COUNT(*) FILTER (WHERE cmd = 'DELETE' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as delete_policy_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'DELETE' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES - Fix successful'
    ELSE '❌ Still has duplicates'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests';

