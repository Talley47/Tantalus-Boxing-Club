-- ============================================================================
-- FIX: news_announcements RLS Performance - Simple Version
-- ============================================================================
-- Fixes the "Authenticated read all news" policy that re-evaluates auth.uid()
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current "Authenticated read all news" policy
SELECT 
  'Current Policy' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  CASE 
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN '❌ Needs optimization'
    ELSE '✅ Already optimized'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND (
    policyname LIKE '%Authenticated%read%all%news%'
    OR policyname LIKE '%Authenticated read all news%'
    OR policyname LIKE '%authenticated read all news%'
  );

-- Step 2: Drop and recreate policies with optimized auth.uid() calls
DO $$
BEGIN
  -- Drop policies that might use auth.uid() directly
  DROP POLICY IF EXISTS "Authenticated read all news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Authenticated users can view news announcements" ON public.news_announcements;
  DROP POLICY IF EXISTS "Authenticated and admins can read news" ON public.news_announcements;
  
  -- Recreate "Authenticated read all news" with optimized (select auth.uid())
  -- This evaluates once per query instead of once per row
  CREATE POLICY "Authenticated read all news" 
  ON public.news_announcements 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Created optimized "Authenticated read all news" policy';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error creating policy: %', SQLERRM;
END $$;

-- Step 3: Also optimize other policies that might use auth.uid()
DO $$
BEGIN
  -- Admin policies that check auth.uid() for admin role
  DROP POLICY IF EXISTS "Admin update news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Admin delete news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Admin read all news" ON public.news_announcements;
  
  -- Recreate admin policies with optimized auth.uid() calls
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (which should already be optimized)
    CREATE POLICY "Admin update news" 
    ON public.news_announcements 
    FOR UPDATE 
    TO authenticated 
    USING (is_admin_user());
    
    CREATE POLICY "Admin delete news" 
    ON public.news_announcements 
    FOR DELETE 
    TO authenticated 
    USING (is_admin_user());
    
    CREATE POLICY "Admin read all news" 
    ON public.news_announcements 
    FOR SELECT 
    TO authenticated 
    USING (is_admin_user());
  ELSE
    -- Fallback: check profiles table with optimized auth.uid()
    CREATE POLICY "Admin update news" 
    ON public.news_announcements 
    FOR UPDATE 
    TO authenticated 
    USING (
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
    
    CREATE POLICY "Admin delete news" 
    ON public.news_announcements 
    FOR DELETE 
    TO authenticated 
    USING (
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
    
    CREATE POLICY "Admin read all news" 
    ON public.news_announcements 
    FOR SELECT 
    TO authenticated 
    USING (
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
  END IF;
  
  RAISE NOTICE '✅ Created optimized admin policies';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️ Admin policies not created (may not exist): %', SQLERRM;
END $$;

-- Step 4: Optimize INSERT policy if it exists
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated and admins can insert news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Fighters insert fight results" ON public.news_announcements;
  
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Authenticated and admins can insert news" 
    ON public.news_announcements 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      is_admin_user() 
      OR type = 'fight_result'
    );
  ELSE
    CREATE POLICY "Authenticated and admins can insert news" 
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
  END IF;
  
  RAISE NOTICE '✅ Created optimized INSERT policy';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️ INSERT policy not created (may not exist): %', SQLERRM;
END $$;

-- Step 5: Verify all policies are optimized
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
ORDER BY policyname;

-- Step 6: Final summary
SELECT 
  'Performance Fix Complete' as status,
  COUNT(*) FILTER (WHERE qual LIKE '%(select auth.uid())%' OR qual IS NULL OR qual LIKE '%true%') as optimized_count,
  COUNT(*) FILTER (WHERE qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%') as unoptimized_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%') = 0 
    THEN '✅ ALL POLICIES OPTIMIZED - Performance warning should be resolved'
    ELSE '⚠️ Some policies may still need manual optimization'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements';

