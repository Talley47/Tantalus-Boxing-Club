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

-- Create separate admin policies for SELECT, UPDATE, DELETE (INSERT is handled by combined policy below)
-- PostgreSQL doesn't support FOR SELECT, UPDATE, DELETE, so we create separate policies
DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated and admins can insert news" ON news_announcements;

DO $$
BEGIN
    -- Create separate admin policies for UPDATE and DELETE
    EXECUTE 'CREATE POLICY "Admin update news" ON news_announcements
        FOR UPDATE TO authenticated
        USING (is_admin_user())';
    
    EXECUTE 'CREATE POLICY "Admin delete news" ON news_announcements
        FOR DELETE TO authenticated
        USING (is_admin_user())';
    
    -- Create combined INSERT policy: Authenticated users OR admins can insert news
    -- This avoids multiple permissive policies for the same role and action
    EXECUTE 'CREATE POLICY "Authenticated and admins can insert news" ON news_announcements
        FOR INSERT TO authenticated
        WITH CHECK (
            (select auth.uid()) IS NOT NULL 
            OR is_admin_user()
        )';
END $$;

-- Drop old "Authenticated insert news" policy if it exists (replaced by combined policy above)
DROP POLICY IF EXISTS "Authenticated insert news" ON news_announcements;

-- Create admin manage policy for fight results
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
CREATE POLICY "Admin manage fight results" ON news_fight_results
    FOR ALL
    TO authenticated
    USING (is_admin_user());

-- Allow admin to read unpublished news
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
CREATE POLICY "Admin read all news" ON news_announcements
    FOR SELECT
    TO authenticated
    USING (
        is_published = TRUE OR is_admin_user()
    );

