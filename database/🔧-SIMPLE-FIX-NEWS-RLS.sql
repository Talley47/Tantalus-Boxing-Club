-- ============================================================================
-- 🔧 SIMPLE FIX: News & Announcements Blank for Logged-In Users
-- ============================================================================
-- PROBLEM: Logged-in users cannot see news because RLS policies only allow
--          'anon' role to read published news. Authenticated users need their
--          own policy.
-- ============================================================================
-- SOLUTION: Run this ENTIRE script in Supabase SQL Editor
-- ============================================================================

-- Drop the policy if it exists (to avoid conflicts)
DROP POLICY IF EXISTS "Authenticated read published news" ON public.news_announcements;

-- Create policy for authenticated users (logged in)
-- ⚠️ THIS IS THE CRITICAL FIX - without this, logged-in users can't see news
CREATE POLICY "Authenticated read published news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (
  is_published IS NOT NULL 
  AND is_published = TRUE
);

-- Verify the policy was created
SELECT 
  '✅ Policy Created' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
  AND 'authenticated' = ANY(roles::text[])
ORDER BY policyname;

