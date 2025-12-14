-- QUICK FIX for News Announcements Timeout Error
-- Run this FIRST in Supabase SQL Editor to fix the 500 error

-- Step 1: Drop old indexes that don't match the query pattern
DROP INDEX IF EXISTS idx_news_announcements_published;
DROP INDEX IF EXISTS idx_news_announcements_created;

-- Step 2: Create optimized composite index for the exact query
-- Query pattern: WHERE is_published = TRUE ORDER BY created_at DESC LIMIT 20
-- Drop duplicate index if it exists
DROP INDEX IF EXISTS idx_news_published_created;

-- Create index with consistent naming (idx_news_announcements_published_created)
CREATE INDEX IF NOT EXISTS idx_news_announcements_published_created 
ON news_announcements(is_published, created_at DESC)
WHERE is_published = TRUE;

-- Step 3: Create general index on created_at for other queries
CREATE INDEX IF NOT EXISTS idx_news_announcements_created_at 
ON news_announcements(created_at DESC);

-- Step 4: Create partial index on is_published for filtering
-- Drop duplicate indexes if they exist
DROP INDEX IF EXISTS idx_news_published;
DROP INDEX IF EXISTS idx_news_published_simple;
DROP INDEX IF EXISTS idx_news_is_published;

-- Create index with consistent naming (idx_news_announcements_is_published)
CREATE INDEX IF NOT EXISTS idx_news_announcements_is_published 
ON news_announcements(is_published)
WHERE is_published = TRUE;

-- Step 5: Update table statistics for query planner
ANALYZE news_announcements;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ News announcements indexes created!';
    RAISE NOTICE '   The timeout error should now be fixed.';
    RAISE NOTICE '   Refresh your app and the news should load quickly.';
END $$;

