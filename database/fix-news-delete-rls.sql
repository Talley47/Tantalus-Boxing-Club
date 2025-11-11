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
    DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create comprehensive admin policy that covers all operations (INSERT, UPDATE, DELETE, SELECT)
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Admin can manage all news (insert, update, delete, select)
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

-- Add helpful comment
COMMENT ON POLICY "Admin manage news" ON news_announcements IS 
    'Allows admins to create, update, and delete all news items';

