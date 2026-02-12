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

-- ✅ Policy created! Logged-in users can now see published news.

