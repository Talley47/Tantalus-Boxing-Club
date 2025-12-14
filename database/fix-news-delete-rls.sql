-- Fix RLS Policies for news_announcements table to allow admins to DELETE
-- This ensures admins can delete news items
-- Run this in Supabase SQL Editor

-- Enable RLS on news_announcements table if not already enabled
ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admins can delete news" ON news_announcements;
    DROP POLICY IF EXISTS "Admins can delete all news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create separate admin policies for UPDATE and DELETE (INSERT and SELECT are handled by other policies)
-- This avoids multiple permissive policies for the same role and action
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Create separate admin policies for UPDATE and DELETE only
        -- (INSERT is handled by combined policy, SELECT is handled by "Admin read all news")
        EXECUTE 'CREATE POLICY "Admin update news" ON news_announcements
            FOR UPDATE TO authenticated
            USING (is_admin_user())';
        
        EXECUTE 'CREATE POLICY "Admin delete news" ON news_announcements
            FOR DELETE TO authenticated
            USING (is_admin_user())';
        
        -- Admin can read all news (including unpublished)
        EXECUTE 'CREATE POLICY "Admin read all news" ON news_announcements
            FOR SELECT TO authenticated
            USING (is_published = TRUE OR is_admin_user())';
    ELSE
        -- Fallback: check profiles table only
        EXECUTE 'CREATE POLICY "Admin update news" ON news_announcements
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admin delete news" ON news_announcements
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admin read all news" ON news_announcements
            FOR SELECT TO authenticated
            USING (
                is_published = TRUE OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Also ensure public can read published news (if not already exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'news_announcements' 
        AND policyname = 'Public read published news'
    ) THEN
        EXECUTE 'CREATE POLICY "Public read published news" ON news_announcements
            FOR SELECT USING (is_published = TRUE)';
    END IF;
END $$;

-- Grant DELETE permission
GRANT DELETE ON news_announcements TO authenticated;

-- Add helpful comments
COMMENT ON POLICY "Admin update news" ON news_announcements IS 
    'Allows admins to update all news items';

COMMENT ON POLICY "Admin delete news" ON news_announcements IS 
    'Allows admins to delete all news items';

