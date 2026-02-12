-- ============================================================================
-- 🔧 FIX: Allow Authenticated Users to Read ALL News Items
-- ============================================================================
-- PROBLEM: Authenticated users cannot see news because RLS policies are blocking
--          access. We need to allow authenticated users to read all rows, then
--          filter client-side for published items.
-- ============================================================================
-- SOLUTION: Create a policy that allows authenticated users to read all news
--           items. Client-side code will filter for is_published = true.
-- ============================================================================

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Authenticated read published news" ON public.news_announcements;
DROP POLICY IF EXISTS "Authenticated read all news" ON public.news_announcements;

-- Create policy for authenticated users to read ALL news items
-- Client-side code will filter for is_published = true
CREATE POLICY "Authenticated read all news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (true);

-- ✅ Policy created! Authenticated users can now read all news items.
--    Client-side code filters for is_published = true before displaying.
