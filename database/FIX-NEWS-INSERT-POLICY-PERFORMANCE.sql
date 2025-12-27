-- ============================================================================
-- FIX: news_announcements INSERT Policy Performance
-- ============================================================================
-- Fixes the "Authenticated insert news" policy that re-evaluates auth.uid()
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current INSERT policies
SELECT 
  'Current INSERT Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause,
  CASE 
    WHEN with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%' THEN '❌ Needs optimization'
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN '❌ Needs optimization'
    WHEN with_check LIKE '%(select auth.uid())%' OR qual LIKE '%(select auth.uid())%' THEN '✅ Optimized'
    ELSE '✅ OK'
  END as performance_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'INSERT'
ORDER BY policyname;

-- Step 2: Fix INSERT policies
DO $$
BEGIN
  -- Drop existing INSERT policies that might use auth.uid() directly
  DROP POLICY IF EXISTS "Authenticated insert news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Authenticated and admins can insert news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Fighters insert fight results" ON public.news_announcements;
  DROP POLICY IF EXISTS "Fighters can insert fight results" ON public.news_announcements;
  
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (which should already be optimized)
    CREATE POLICY "Authenticated insert news" 
    ON public.news_announcements 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      is_admin_user() 
      OR type = 'fight_result'
    );
    
    RAISE NOTICE '✅ Created optimized INSERT policy using is_admin_user()';
  ELSE
    -- Fallback: check profiles table with optimized (select auth.uid())
    CREATE POLICY "Authenticated insert news" 
    ON public.news_announcements 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
      OR type = 'fight_result'
    );
    
    RAISE NOTICE '✅ Created optimized INSERT policy using (select auth.uid())';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error creating INSERT policy: %', SQLERRM;
END $$;

-- Step 3: Verify the fix
SELECT 
  'Verification' as status,
  policyname,
  cmd as command,
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
  AND cmd = 'INSERT'
ORDER BY policyname;

-- Step 4: Summary
SELECT 
  'INSERT Policy Fix Complete' as status,
  COUNT(*) FILTER (WHERE with_check LIKE '%(select auth.uid())%' OR with_check IS NULL) as optimized_count,
  COUNT(*) FILTER (WHERE with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%') as unoptimized_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%') = 0 
    THEN '✅ ALL INSERT POLICIES OPTIMIZED - Performance warning should be resolved'
    ELSE '⚠️ Some INSERT policies may still need manual optimization'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'INSERT';

