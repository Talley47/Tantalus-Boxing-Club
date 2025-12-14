-- Optimize News Announcements RLS Policy
-- The current RLS policy might be causing performance issues
-- This script creates a simpler, faster policy

-- Drop existing policy
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create optimized RLS policy
-- Simple check: is_published = TRUE (no complex joins or subqueries)
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT TO anon
    USING (is_published = TRUE);

-- Ensure the index exists to support this policy
CREATE INDEX IF NOT EXISTS idx_news_announcements_is_published 
ON news_announcements(is_published)
WHERE is_published = TRUE;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ News announcements RLS policy optimized!';
    RAISE NOTICE '   - Simplified policy for better performance';
    RAISE NOTICE '   - Index created to support the policy';
END $$;

