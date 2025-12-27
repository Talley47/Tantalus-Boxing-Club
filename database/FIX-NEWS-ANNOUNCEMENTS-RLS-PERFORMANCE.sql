-- ============================================================================
-- FIX: news_announcements RLS Performance Issue
-- ============================================================================
-- This fixes the performance warning about auth.uid() being re-evaluated
-- for each row. Wraps auth.uid() calls in (select auth.uid()) for optimization.
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current policies on news_announcements
SELECT 
  'Current Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause,
  CASE 
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN '❌ Needs optimization'
    WHEN with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%' THEN '❌ Needs optimization'
    WHEN qual LIKE '%(select auth.uid())%' OR qual IS NULL OR qual LIKE '%true%' THEN '✅ Optimized'
    ELSE '✅ OK'
  END as performance_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
ORDER BY policyname, cmd;

-- Step 2: Find policies that need optimization
SELECT 
  'Policies Needing Fix' as status,
  policyname,
  cmd as command,
  CASE 
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN 'USING clause'
    WHEN with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%' THEN 'WITH CHECK clause'
    ELSE 'N/A'
  END as issue_location
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND (
    (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
    OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
  );

-- Step 3: Fix policies by dropping and recreating with optimized auth.uid() calls
DO $$
DECLARE
  policy_rec RECORD;
  new_qual TEXT;
  new_with_check TEXT;
  role_list TEXT;
BEGIN
  -- Loop through all policies on news_announcements that need optimization
  FOR policy_rec IN
    SELECT 
      policyname,
      cmd,
      qual,
      with_check,
      roles
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'news_announcements'
      AND (
        (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
        OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
      )
  LOOP
    -- Drop the existing policy
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.news_announcements', policy_rec.policyname);
    
    -- Convert roles from array format {authenticated} to comma-separated authenticated
    role_list := trim(both '{}' from policy_rec.roles::text);
    
    -- Optimize the USING clause
    new_qual := policy_rec.qual;
    IF new_qual IS NOT NULL THEN
      -- Replace auth.uid() with (select auth.uid())
      new_qual := regexp_replace(new_qual, '\bauth\.uid\(\)', '(select auth.uid())', 'g');
    END IF;
    
    -- Optimize the WITH CHECK clause
    new_with_check := policy_rec.with_check;
    IF new_with_check IS NOT NULL THEN
      -- Replace auth.uid() with (select auth.uid())
      new_with_check := regexp_replace(new_with_check, '\bauth\.uid\(\)', '(select auth.uid())', 'g');
    END IF;
    
    -- Recreate the policy with optimized clauses
    IF policy_rec.cmd = 'SELECT' THEN
      EXECUTE format(
        'CREATE POLICY %I ON public.news_announcements FOR SELECT TO %s USING (%s)',
        policy_rec.policyname,
        role_list,
        COALESCE(new_qual, 'true')
      );
    ELSIF policy_rec.cmd = 'INSERT' THEN
      EXECUTE format(
        'CREATE POLICY %I ON public.news_announcements FOR INSERT TO %s WITH CHECK (%s)',
        policy_rec.policyname,
        role_list,
        COALESCE(new_with_check, 'true')
      );
    ELSIF policy_rec.cmd = 'UPDATE' THEN
      EXECUTE format(
        'CREATE POLICY %I ON public.news_announcements FOR UPDATE TO %s USING (%s) WITH CHECK (%s)',
        policy_rec.policyname,
        role_list,
        COALESCE(new_qual, 'true'),
        COALESCE(new_with_check, new_qual, 'true')
      );
    ELSIF policy_rec.cmd = 'DELETE' THEN
      EXECUTE format(
        'CREATE POLICY %I ON public.news_announcements FOR DELETE TO %s USING (%s)',
        policy_rec.policyname,
        role_list,
        COALESCE(new_qual, 'true')
      );
    ELSIF policy_rec.cmd = 'ALL' THEN
      -- Handle ALL command (SELECT, INSERT, UPDATE, DELETE)
      EXECUTE format(
        'CREATE POLICY %I ON public.news_announcements FOR ALL TO %s USING (%s) WITH CHECK (%s)',
        policy_rec.policyname,
        role_list,
        COALESCE(new_qual, 'true'),
        COALESCE(new_with_check, new_qual, 'true')
      );
    END IF;
    
    RAISE NOTICE '✅ Optimized policy: %', policy_rec.policyname;
  END LOOP;
  
  IF NOT FOUND THEN
    RAISE NOTICE '✅ No policies found that need optimization';
  END IF;
END $$;

-- Step 4: Verify the fix
SELECT 
  'After Fix' as status,
  policyname,
  cmd as command,
  roles,
  CASE 
    WHEN qual LIKE '%(select auth.uid())%' OR qual IS NULL OR qual LIKE '%true%' THEN '✅ Optimized'
    WHEN qual LIKE '%auth.uid()%' THEN '❌ Still needs optimization'
    ELSE '✅ OK'
  END as using_status,
  CASE 
    WHEN with_check LIKE '%(select auth.uid())%' OR with_check IS NULL THEN '✅ Optimized'
    WHEN with_check LIKE '%auth.uid()%' THEN '❌ Still needs optimization'
    ELSE '✅ OK'
  END as with_check_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
ORDER BY policyname, cmd;

-- Step 5: Summary
SELECT 
  'Summary' as status,
  COUNT(*) FILTER (WHERE qual LIKE '%(select auth.uid())%' OR qual IS NULL OR qual LIKE '%true%') as optimized_policies,
  COUNT(*) FILTER (WHERE qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%') as unoptimized_policies,
  COUNT(*) as total_policies,
  CASE 
    WHEN COUNT(*) FILTER (WHERE qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%') = 0 
    THEN '✅ ALL POLICIES OPTIMIZED'
    ELSE '❌ Some policies still need optimization'
  END as overall_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements';

