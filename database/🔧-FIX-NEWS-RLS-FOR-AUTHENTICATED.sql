-- ============================================================================
-- FIX: News & Announcements RLS Policies for Authenticated Users
-- ============================================================================
-- Issue: Authenticated users cannot see news items because RLS policies
--        may only allow 'anon' role to read published news.
-- Solution: Add/update policies to allow authenticated users to read published news
-- ============================================================================

-- Step 1: Check current policies
SELECT 
  'Current Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
ORDER BY policyname;

-- Step 2: Drop ALL existing SELECT policies (we'll recreate them cleanly)
-- Use DO block to handle any errors gracefully
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
  END LOOP;
END $$;

-- Step 3: Create policy for anon role (public/unauthenticated users)
-- They can only see published news
CREATE POLICY "Public read published news" 
ON public.news_announcements 
FOR SELECT 
TO anon 
USING (is_published = TRUE);

-- Step 4: Create policy for authenticated role
-- Authenticated users can see published news
-- IMPORTANT: This policy MUST exist for logged-in users to see news
CREATE POLICY "Authenticated read published news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (
  is_published IS NOT NULL 
  AND is_published = TRUE
);

-- Step 4b: Also create a policy for service_role (if needed for admin operations)
-- This allows admins to see all news (including unpublished) via admin panel
-- Note: Admin panel should use service_role key, not anon key
-- But we'll also add a policy that checks admin role if is_admin_user function exists
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'is_admin_user'
  ) THEN
    -- Create policy that allows admins to read all news
    EXECUTE 'CREATE POLICY "Admin read all news" 
      ON public.news_announcements 
      FOR SELECT 
      TO authenticated 
      USING (is_admin_user(auth.uid()) = true)';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- If function doesn't exist or policy creation fails, continue
    RAISE NOTICE 'Could not create admin policy (this is OK if is_admin_user function does not exist)';
END $$;

-- Step 5: Verify the fix
SELECT 
  'After Fix - Policy Verification' as status,
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
  COUNT(*) FILTER (WHERE is_published = FALSE) as unpublished_count
FROM public.news_announcements;

