-- Fix RLS Policies for News & Announcements
-- Allows fighters to auto-post fight_result type news when they add fight records
-- Run this in Supabase SQL Editor

-- Ensure RLS is enabled
ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_fight_results ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
    DROP POLICY IF EXISTS "Fighters can insert fight results" ON news_announcements;
    DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
    DROP POLICY IF EXISTS "Public read fight results" ON news_fight_results;
    DROP POLICY IF EXISTS "Admin manage fight results" ON news_fight_results;
    DROP POLICY IF EXISTS "Fighters can insert fight results data" ON news_fight_results;
    DROP POLICY IF EXISTS "Only admins can manage news and announcements" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Public read access for published news
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT USING (
        is_published = TRUE OR 
        (type = 'fight_result' AND is_published = TRUE)
    );

-- Fighters can insert fight_result type news (for auto-posting)
CREATE POLICY "Fighters can insert fight results" ON news_announcements
    FOR INSERT WITH CHECK (
        type = 'fight_result' AND
        EXISTS (
            SELECT 1 FROM fighter_profiles
            WHERE user_id = auth.uid()
        )
    );

-- Admin full access to manage all news
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Admin can manage all news (insert, update, delete)
        EXECUTE 'CREATE POLICY "Admin manage news" ON news_announcements
            FOR ALL USING (is_admin_user())';
        
        -- Admin can read all news (including unpublished)
        EXECUTE 'CREATE POLICY "Admin read all news" ON news_announcements
            FOR SELECT USING (is_published = TRUE OR is_admin_user())';
    ELSE
        -- Fallback: check profiles table only
        EXECUTE 'CREATE POLICY "Admin manage news" ON news_announcements
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admin read all news" ON news_announcements
            FOR SELECT USING (
                is_published = TRUE OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Public read access for fight results
CREATE POLICY "Public read fight results" ON news_fight_results
    FOR SELECT USING (true);

-- Fighters can insert fight results data (when creating fight_result news)
-- This policy allows fighters to insert into news_fight_results if they own the related news item
CREATE POLICY "Fighters can insert fight results data" ON news_fight_results
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM fighter_profiles
            WHERE user_id = auth.uid()
        )
    );

-- Admin full access to manage fight results
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admin manage fight results" ON news_fight_results
            FOR ALL USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admin manage fight results" ON news_fight_results
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON news_announcements TO authenticated;
GRANT SELECT ON news_announcements TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON news_fight_results TO authenticated;
GRANT SELECT ON news_fight_results TO anon;

-- Add helpful comments
COMMENT ON POLICY "Fighters can insert fight results" ON news_announcements IS 
    'Allows fighters to auto-post fight_result type news when they add fight records';

COMMENT ON POLICY "Public read published news" ON news_announcements IS 
    'Allows anyone to view published news items';

COMMENT ON POLICY "Admin manage news" ON news_announcements IS 
    'Allows admins to create, update, and delete all news items';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ News RLS policies updated!';
    RAISE NOTICE '';
    RAISE NOTICE 'Policies created:';
    RAISE NOTICE '  - Fighters can insert fight_result type news';
    RAISE NOTICE '  - Public can read published news';
    RAISE NOTICE '  - Admins can manage all news';
    RAISE NOTICE '';
    RAISE NOTICE 'Fighters can now auto-post fight results when they add records!';
END $$;

