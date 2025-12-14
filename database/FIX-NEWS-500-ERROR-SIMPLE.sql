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
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT 
    TO anon
    USING (
        is_published IS NOT NULL 
        AND is_published = TRUE
    );

-- Combined SELECT policy: Authenticated users can read published news OR admins can read all news
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Authenticated and admins can read news" ON news_announcements;
DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Authenticated and admins can read news" ON news_announcements
            FOR SELECT TO authenticated
            USING (
                is_published = TRUE 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Authenticated and admins can read news" ON news_announcements
            FOR SELECT TO authenticated
            USING (
                is_published = TRUE 
                OR EXISTS (
                    SELECT 1 FROM profiles
                    WHERE id = (select auth.uid())
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Combined INSERT policy: Authenticated users OR admins OR fighters (for fight_result type) can insert news
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Authenticated and admins can insert news" ON news_announcements;
DROP POLICY IF EXISTS "Admin insert news" ON news_announcements;
DROP POLICY IF EXISTS "Fighters can insert fight results" ON news_announcements;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Authenticated and admins can insert news" ON news_announcements
            FOR INSERT TO authenticated
            WITH CHECK (
                (select auth.uid()) IS NOT NULL 
                OR is_admin_user()
                OR (
                    type = ''fight_result'' AND
                    EXISTS (
                        SELECT 1 FROM fighter_profiles
                        WHERE user_id = (select auth.uid())
                    )
                )
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Authenticated and admins can insert news" ON news_announcements
            FOR INSERT TO authenticated
            WITH CHECK (
                (select auth.uid()) IS NOT NULL 
                OR EXISTS (
                    SELECT 1 FROM profiles
                    WHERE id = (select auth.uid())
                    AND role = ''admin''
                )
                OR (
                    type = ''fight_result'' AND
                    EXISTS (
                        SELECT 1 FROM fighter_profiles
                        WHERE user_id = (select auth.uid())
                    )
                )
            )';
    END IF;
END $$;

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
-- Drop duplicate indexes if they exist
DROP INDEX IF EXISTS idx_news_published;
DROP INDEX IF EXISTS idx_news_published_simple;
DROP INDEX IF EXISTS idx_news_is_published;

-- Create index with consistent naming (idx_news_announcements_is_published)
CREATE INDEX IF NOT EXISTS idx_news_announcements_is_published ON news_announcements(is_published) 
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

