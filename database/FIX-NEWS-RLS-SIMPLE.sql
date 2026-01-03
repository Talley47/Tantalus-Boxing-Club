-- ============================================================================
-- SIMPLE FIX: News & Announcements RLS for Authenticated Users
-- ============================================================================
-- Copy ALL of this code into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Drop all existing SELECT policies
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

-- Step 2: Create policy for anonymous users (unauthenticated)
CREATE POLICY "Public read published news" 
ON public.news_announcements 
FOR SELECT 
TO anon 
USING (is_published = TRUE);

-- Step 3: Create policy for authenticated users (logged in)
-- THIS IS THE KEY FIX - without this, logged-in users can't see news
CREATE POLICY "Authenticated read published news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (
  is_published IS NOT NULL 
  AND is_published = TRUE
);

-- Step 4: Verify it worked
SELECT 
  '✅ Policies Created' as status,
  policyname,
  cmd as command,
  roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
ORDER BY policyname;

