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
DROP POLICY IF EXISTS "Admin insert news" ON news_announcements;
DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;
DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated insert news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated read all news" ON news_announcements;
DROP POLICY IF EXISTS "Fighters can insert fight results" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated and admins can insert news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated and admins can read news" ON news_announcements;

DO $$
BEGIN
    -- Create separate admin policies for UPDATE and DELETE
    EXECUTE 'CREATE POLICY "Admin update news" ON news_announcements
        FOR UPDATE TO authenticated
        USING (is_admin_user())';
    
    EXECUTE 'CREATE POLICY "Admin delete news" ON news_announcements
        FOR DELETE TO authenticated
        USING (is_admin_user())';
    
    -- Create combined INSERT policy: Authenticated users OR admins OR fighters (for fight_result type) can insert news
    -- This avoids multiple permissive policies for the same role and action
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
END $$;

-- Drop old "Authenticated insert news" policy if it exists (replaced by combined policy above)
DROP POLICY IF EXISTS "Authenticated insert news" ON news_announcements;

-- Admin policies for SELECT, UPDATE, DELETE (INSERT is handled by combined policy below)
-- PostgreSQL doesn't support FOR SELECT, UPDATE, DELETE, so we create separate policies
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Admin manage fight results" ON news_fight_results;
DROP POLICY IF EXISTS "Fighters can insert fight results data" ON news_fight_results;
DROP POLICY IF EXISTS "Fighters and admins can insert fight results data" ON news_fight_results;
DROP POLICY IF EXISTS "Admin can view fight results" ON news_fight_results;
DROP POLICY IF EXISTS "Authenticated can read fight results" ON news_fight_results;
DROP POLICY IF EXISTS "Admin can update fight results" ON news_fight_results;
DROP POLICY IF EXISTS "Admin can delete fight results" ON news_fight_results;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Combined INSERT policy: Fighters can insert fight results data OR admins can insert any
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Fighters and admins can insert fight results data" ON news_fight_results
            FOR INSERT TO authenticated
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM fighter_profiles
                    WHERE user_id = (select auth.uid())
                )
                OR is_admin_user()
            )';
        
        -- Admin policies for SELECT, UPDATE, DELETE
        -- Combined SELECT policy: All authenticated users can read fight results (admins have additional privileges via other policies)
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Authenticated can read fight results" ON news_fight_results
            FOR SELECT TO authenticated
            USING (true)';
        
        EXECUTE 'CREATE POLICY "Admin can update fight results" ON news_fight_results
            FOR UPDATE TO authenticated
            USING (is_admin_user())';
        
        EXECUTE 'CREATE POLICY "Admin can delete fight results" ON news_fight_results
            FOR DELETE TO authenticated
            USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Fighters and admins can insert fight results data" ON news_fight_results
            FOR INSERT TO authenticated
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM fighter_profiles
                    WHERE user_id = (select auth.uid())
                )
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        
        -- Combined SELECT policy: All authenticated users can read fight results (admins have additional privileges via other policies)
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Authenticated can read fight results" ON news_fight_results
            FOR SELECT TO authenticated
            USING (true)';
        
        EXECUTE 'CREATE POLICY "Admin can update fight results" ON news_fight_results
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admin can delete fight results" ON news_fight_results
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Combined SELECT policy: Authenticated users can read published news OR admins can read all news
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Authenticated read all news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated and admins can read news" ON news_announcements;

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

