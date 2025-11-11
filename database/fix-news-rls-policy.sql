-- Fix RLS Policies for News & Announcements
-- This creates a SECURITY DEFINER function to safely check admin status
-- and updates policies to use it

-- Create a function to check if current user is admin
-- This function runs with SECURITY DEFINER so it can access auth.users
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_email TEXT;
    user_role TEXT;
BEGIN
    -- Get user email and role from auth.users
    SELECT email, COALESCE(raw_app_meta_data->>'role', '')::TEXT
    INTO user_email, user_role
    FROM auth.users
    WHERE id = auth.uid();
    
    -- Check if user is admin
    IF user_email = 'tantalusboxingclub@gmail.com' THEN
        RETURN TRUE;
    END IF;
    
    IF user_email LIKE '%@admin.tantalus%' THEN
        RETURN TRUE;
    END IF;
    
    IF user_role = 'admin' THEN
        RETURN TRUE;
    END IF;
    
    -- Also check profiles table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        IF EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        ) THEN
            RETURN TRUE;
        END IF;
    END IF;
    
    RETURN FALSE;
END;
$$;

-- Drop existing admin policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin manage fight results" ON news_fight_results;
    DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create admin manage policy using the function
CREATE POLICY "Admin manage news" ON news_announcements
    FOR ALL USING (is_admin_user());

-- Create admin manage policy for fight results
CREATE POLICY "Admin manage fight results" ON news_fight_results
    FOR ALL USING (is_admin_user());

-- Allow admin to read unpublished news
CREATE POLICY "Admin read all news" ON news_announcements
    FOR SELECT USING (
        is_published = TRUE OR is_admin_user()
    );

