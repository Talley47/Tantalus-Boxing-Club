-- Fix RLS Policies for News Announcements
-- Allows fighters to auto-post fight_result type news when they add fight records
-- Run this in Supabase SQL Editor

-- Ensure RLS is enabled
ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies to start fresh
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
    DROP POLICY IF EXISTS "Fighters can insert fight results" ON news_announcements;
    DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
    DROP POLICY IF EXISTS "Only admins can manage news and announcements" ON news_announcements;
    DROP POLICY IF EXISTS "Anyone can view news and announcements" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- 1. Public read access for published news
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT USING (
        is_published = TRUE OR 
        type = 'fight_result'  -- Fight results are always visible
    );

-- 2. Fighters can insert fight_result type news (for auto-posting fight results)
-- This is critical for the auto-post feature when fighters add fight records
CREATE POLICY "Fighters can insert fight results" ON news_announcements
    FOR INSERT WITH CHECK (
        type = 'fight_result' AND
        EXISTS (
            SELECT 1 FROM fighter_profiles
            WHERE user_id = auth.uid()
        )
    );

-- 3. Admin full access to manage all news
-- Check if is_admin_user function exists
DO $$
BEGIN
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
        -- Fallback: check profiles table or email
        EXECUTE 'CREATE POLICY "Admin manage news" ON news_announcements
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
                OR EXISTS (
                    SELECT 1 FROM auth.users
                    WHERE id = auth.uid()
                    AND (email = ''tantalusboxingclub@gmail.com'' OR email LIKE ''%@admin.tantalus%'')
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
                OR EXISTS (
                    SELECT 1 FROM auth.users
                    WHERE id = auth.uid()
                    AND (email = ''tantalusboxingclub@gmail.com'' OR email LIKE ''%@admin.tantalus%'')
                )
            )';
    END IF;
END $$;

-- 4. If news_fight_results table exists, set up policies for it too
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'news_fight_results'
    ) THEN
        ALTER TABLE news_fight_results ENABLE ROW LEVEL SECURITY;
        
        -- Drop existing policies
        DROP POLICY IF EXISTS "Public read fight results" ON news_fight_results;
        DROP POLICY IF EXISTS "Admin manage fight results" ON news_fight_results;
        DROP POLICY IF EXISTS "Fighters can insert fight results data" ON news_fight_results;
        
        -- Public read access for fight results
        EXECUTE 'CREATE POLICY "Public read fight results" ON news_fight_results
            FOR SELECT USING (true)';
        
        -- Fighters can insert fight results data (when creating fight_result news)
        EXECUTE 'CREATE POLICY "Fighters can insert fight results data" ON news_fight_results
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM fighter_profiles
                    WHERE user_id = auth.uid()
                )
            )';
        
        -- Admin full access
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
                    OR EXISTS (
                        SELECT 1 FROM auth.users
                        WHERE id = auth.uid()
                        AND (email = ''tantalusboxingclub@gmail.com'' OR email LIKE ''%@admin.tantalus%'')
                    )
                )';
        END IF;
    END IF;
END $$;

-- 5. Verify policies were created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'news_announcements'
ORDER BY policyname;

-- Summary
DO $$
BEGIN
    RAISE NOTICE '✅ News RLS policies updated!';
    RAISE NOTICE '✅ Fighters can now insert fight_result type news';
    RAISE NOTICE '✅ Public can read published news and all fight results';
    RAISE NOTICE '✅ Admins have full access to manage all news';
END $$;

