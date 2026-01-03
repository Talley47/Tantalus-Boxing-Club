-- ============================================================================
-- 🚨 URGENT FIX: News & Announcements Blank for Logged-In Users
-- ============================================================================
-- PROBLEM: Logged-in users cannot see news because RLS policies only allow
--          'anon' role to read published news. Authenticated users need their
--          own policy.
-- ============================================================================
-- SOLUTION: Run this ENTIRE script in Supabase SQL Editor
-- ============================================================================

-- Step 1: Check current policies (diagnostic)
SELECT 
  'Current Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 2: Drop all existing SELECT policies (we'll recreate them cleanly)
DO $$ 
DECLARE 
  r RECORD;
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'news_announcements'
      AND cmd = 'SELECT'
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.news_announcements', r.policyname);
    RAISE NOTICE 'Dropped policy: %', r.policyname;
  END LOOP;
END $$;

-- Step 3: Create policy for anonymous users (unauthenticated/public)
CREATE POLICY "Public read published news" 
ON public.news_announcements 
FOR SELECT 
TO anon 
USING (is_published = TRUE);

-- Step 4: Create policy for authenticated users (logged in)
-- ⚠️ THIS IS THE CRITICAL FIX - without this, logged-in users can't see news
CREATE POLICY "Authenticated read published news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (
  is_published IS NOT NULL 
  AND is_published = TRUE
);

-- Step 5: Verify the fix worked
SELECT 
  '✅ Policies Created' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 6: Test query (should return published news count)
SELECT 
  'Published News Count' as test,
  COUNT(*) as published_count,
  COUNT(*) FILTER (WHERE is_published = FALSE) as unpublished_count,
  COUNT(*) FILTER (WHERE is_published IS NULL) as null_published_count
FROM public.news_announcements;

