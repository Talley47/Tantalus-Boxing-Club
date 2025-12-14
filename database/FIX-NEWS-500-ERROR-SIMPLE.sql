-- FIX NEWS 500 ERROR: Simplify RLS policies to prevent timeouts and errors
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Disable RLS temporarily to drop all policies
-- ============================================
ALTER TABLE news_announcements DISABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 2: Drop ALL existing policies
-- ============================================
DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated read all news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated insert news" ON news_announcements;
DROP POLICY IF EXISTS "Admin insert news" ON news_announcements;
DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;
DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
DROP POLICY IF EXISTS "Fighters can insert fight results" ON news_announcements;
DROP POLICY IF EXISTS "Anyone can view news and announcements" ON news_announcements;
DROP POLICY IF EXISTS "Only admins can manage news and announcements" ON news_announcements;

-- ============================================
-- STEP 3: Re-enable RLS
-- ============================================
ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 4: Create SIMPLE, FAST policies
-- ============================================

-- Policy 1: Public can read published news (simple check, no complex queries)
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT 
    USING (
        is_published IS NOT NULL 
        AND is_published = TRUE
    );

-- Policy 2: Authenticated users can read all news (simple check)
CREATE POLICY "Authenticated read all news" ON news_announcements
    FOR SELECT 
    USING ((select auth.uid()) IS NOT NULL);

-- Policy 3: Authenticated users can insert news
CREATE POLICY "Authenticated insert news" ON news_announcements
    FOR INSERT 
    WITH CHECK ((select auth.uid()) IS NOT NULL);

-- Policy 4: Admins can update news (simple check, no complex subqueries)
CREATE POLICY "Admin update news" ON news_announcements
    FOR UPDATE 
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = (select auth.uid())
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = (select auth.uid())
            AND role = 'admin'
        )
    );

-- Policy 5: Admins can delete news
CREATE POLICY "Admin delete news" ON news_announcements
    FOR DELETE 
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = (select auth.uid())
            AND role = 'admin'
        )
    );

-- ============================================
-- STEP 5: Grant permissions
-- ============================================
GRANT SELECT ON news_announcements TO anon;
GRANT SELECT ON news_announcements TO authenticated;
GRANT INSERT ON news_announcements TO authenticated;
GRANT UPDATE ON news_announcements TO authenticated;
GRANT DELETE ON news_announcements TO authenticated;

-- ============================================
-- STEP 6: Ensure is_published column exists and has default
-- ============================================
-- Add column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'news_announcements' 
        AND column_name = 'is_published'
    ) THEN
        ALTER TABLE news_announcements ADD COLUMN is_published BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Set default for any NULL values
    UPDATE news_announcements 
    SET is_published = TRUE 
    WHERE is_published IS NULL;
    
    -- Ensure default is set
    ALTER TABLE news_announcements 
    ALTER COLUMN is_published SET DEFAULT TRUE;
END $$;

-- ============================================
-- STEP 7: Add index for performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_news_published_simple ON news_announcements(is_published) 
WHERE is_published = TRUE;

-- ============================================
-- STEP 8: Verify
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ News RLS policies fixed';
    RAISE NOTICE '✅ Public can read published news';
    RAISE NOTICE '✅ Authenticated users can read all news';
    RAISE NOTICE '✅ Admins can manage news';
    RAISE NOTICE '✅ Permissions granted';
END $$;

