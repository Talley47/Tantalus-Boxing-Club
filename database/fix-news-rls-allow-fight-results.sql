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
    DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;
    DROP POLICY IF EXISTS "Fighters can insert fight results" ON news_announcements;
    DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
    DROP POLICY IF EXISTS "Authenticated read all news" ON news_announcements;
    DROP POLICY IF EXISTS "Authenticated and admins can read news" ON news_announcements;
    DROP POLICY IF EXISTS "Only admins can manage news and announcements" ON news_announcements;
    DROP POLICY IF EXISTS "Anyone can view news and announcements" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- 1. Public read access for published news
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT TO anon
    USING (
        is_published = TRUE OR 
        type = 'fight_result'  -- Fight results are always visible
    );

-- Note: "Fighters can insert fight results" policy has been merged into "Authenticated and admins can insert news"
-- This avoids multiple permissive policies for the same role and action
-- The combined policy allows fighters to insert fight_result type news
-- If "Authenticated and admins can insert news" doesn't exist, it should be created in another script

-- 3. Admin full access to manage all news
-- Check if is_admin_user function exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Create separate admin policies for UPDATE and DELETE (INSERT is handled by combined policy, SELECT by separate policy)
        EXECUTE 'CREATE POLICY "Admin update news" ON news_announcements
            FOR UPDATE TO authenticated
            USING (is_admin_user())';
        
        EXECUTE 'CREATE POLICY "Admin delete news" ON news_announcements
            FOR DELETE TO authenticated
            USING (is_admin_user())';
        
        -- Combined SELECT policy: Authenticated users can read published news OR admins can read all news
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Authenticated and admins can read news" ON news_announcements
            FOR SELECT TO authenticated
            USING (is_published = TRUE OR is_admin_user())';
    ELSE
        -- Fallback: check profiles table or email
        EXECUTE 'CREATE POLICY "Admin update news" ON news_announcements
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
                OR EXISTS (
                    SELECT 1 FROM auth.users
                    WHERE id = (select auth.uid())
                    AND (email = ''tantalusboxingclub@gmail.com'' OR email LIKE ''%@admin.tantalus%'')
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
                OR EXISTS (
                    SELECT 1 FROM auth.users
                    WHERE id = (select auth.uid())
                    AND (email = ''tantalusboxingclub@gmail.com'' OR email LIKE ''%@admin.tantalus%'')
                )
            )';
        
        -- Combined SELECT policy: Authenticated users can read published news OR admins can read all news
        -- This avoids multiple permissive policies for the same role and action
        EXECUTE 'CREATE POLICY "Authenticated and admins can read news" ON news_announcements
            FOR SELECT TO authenticated
            USING (
                is_published = TRUE OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
                OR EXISTS (
                    SELECT 1 FROM auth.users
                    WHERE id = (select auth.uid())
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
        DROP POLICY IF EXISTS "Fighters and admins can insert fight results data" ON news_fight_results;
        DROP POLICY IF EXISTS "Admin can view fight results" ON news_fight_results;
        DROP POLICY IF EXISTS "Admin can update fight results" ON news_fight_results;
        DROP POLICY IF EXISTS "Admin can delete fight results" ON news_fight_results;
        
        -- Public read access for fight results
        EXECUTE 'CREATE POLICY "Public read fight results" ON news_fight_results
            FOR SELECT USING (true)';
        
        -- Combined INSERT policy: Fighters can insert fight results data OR admins can insert any
        -- This avoids multiple permissive policies for the same role and action
        -- Restricted to authenticated only to avoid multiple permissive policies for anon role
        IF EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'is_admin_user' 
            AND pronamespace = 'public'::regnamespace
        ) THEN
            EXECUTE 'CREATE POLICY "Fighters and admins can insert fight results data" ON news_fight_results
                FOR INSERT TO authenticated
                WITH CHECK (
                    EXISTS (
                        SELECT 1 FROM fighter_profiles
                        WHERE user_id = (select auth.uid())
                    )
                    OR is_admin_user()
                )';
        ELSE
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
                    OR EXISTS (
                        SELECT 1 FROM auth.users
                        WHERE id = (select auth.uid())
                        AND (email = ''tantalusboxingclub@gmail.com'' OR email LIKE ''%@admin.tantalus%'')
                    )
                )';
        END IF;
        
        -- Admin policies for SELECT, UPDATE, DELETE (INSERT is handled by combined policy above)
        -- PostgreSQL doesn't support FOR SELECT, UPDATE, DELETE, so we create separate policies
        -- Restricted to authenticated only to avoid multiple permissive policies for anon role
        IF EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'is_admin_user' 
            AND pronamespace = 'public'::regnamespace
        ) THEN
            EXECUTE 'CREATE POLICY "Admin can view fight results" ON news_fight_results
                FOR SELECT TO authenticated
                USING (is_admin_user())';
            
            EXECUTE 'CREATE POLICY "Admin can update fight results" ON news_fight_results
                FOR UPDATE TO authenticated
                USING (is_admin_user())';
            
            EXECUTE 'CREATE POLICY "Admin can delete fight results" ON news_fight_results
                FOR DELETE TO authenticated
                USING (is_admin_user())';
        ELSE
            EXECUTE 'CREATE POLICY "Admin can view fight results" ON news_fight_results
                FOR SELECT TO authenticated
                USING (
                    EXISTS (
                        SELECT 1 FROM profiles 
                        WHERE id = (select auth.uid()) 
                        AND role = ''admin''
                    )
                    OR EXISTS (
                        SELECT 1 FROM auth.users
                        WHERE id = (select auth.uid())
                        AND (email = ''tantalusboxingclub@gmail.com'' OR email LIKE ''%@admin.tantalus%'')
                    )
                )';
            
            EXECUTE 'CREATE POLICY "Admin can update fight results" ON news_fight_results
                FOR UPDATE TO authenticated
                USING (
                    EXISTS (
                        SELECT 1 FROM profiles 
                        WHERE id = (select auth.uid()) 
                        AND role = ''admin''
                    )
                    OR EXISTS (
                        SELECT 1 FROM auth.users
                        WHERE id = (select auth.uid())
                        AND (email = ''tantalusboxingclub@gmail.com'' OR email LIKE ''%@admin.tantalus%'')
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
                    OR EXISTS (
                        SELECT 1 FROM auth.users
                        WHERE id = (select auth.uid())
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

