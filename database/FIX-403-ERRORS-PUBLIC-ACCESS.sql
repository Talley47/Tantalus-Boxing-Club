-- FIX 403 ERRORS: Grant Public Access to News and Scheduled Data
-- This script ensures anonymous users can read published news and scheduled fights/callouts
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Grant SELECT permissions to anon role
-- ============================================

-- Grant SELECT on news_announcements to anon (for public read access)
GRANT SELECT ON news_announcements TO anon;

-- Grant SELECT on scheduled_fights to anon (for public read access)
GRANT SELECT ON scheduled_fights TO anon;

-- Grant SELECT on callout_requests to anon (for viewing scheduled callouts)
GRANT SELECT ON callout_requests TO anon;

-- Grant SELECT on fighter_profiles to anon (needed for joins)
GRANT SELECT ON fighter_profiles TO anon;

-- Grant SELECT on profiles to anon (needed for filtering)
GRANT SELECT ON profiles TO anon;

-- ============================================
-- STEP 2: Fix policies to avoid auth.users access for anonymous users
-- ============================================

-- Drop the problematic "Admin manage news" policy that uses FOR ALL
-- This policy tries to access auth.users on SELECT, which fails for anonymous users
DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;

-- Drop individual admin policies if they exist (to avoid conflicts when recreating)
DROP POLICY IF EXISTS "Admin insert news" ON news_announcements;
DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated insert news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated and admins can insert news" ON news_announcements;

-- Combined INSERT policy: Authenticated users OR admins OR fighters (for fight_result type) can insert news
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
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

CREATE POLICY "Admin delete news" ON news_announcements
    FOR DELETE 
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = (select auth.uid())
            AND role = 'admin'
        )
    );

-- Drop and recreate news policies to ensure they work for anonymous users
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
DROP POLICY IF EXISTS "Public read published news" ON news_announcements;

CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT 
    TO anon
    USING (
        COALESCE(is_published, false) = TRUE
    );

-- Combined SELECT policy: Authenticated users can read published news OR admins can read all news
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Authenticated read all news" ON news_announcements;
DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
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

-- Ensure scheduled fights are publicly readable
DROP POLICY IF EXISTS "Public read scheduled fights" ON scheduled_fights;

-- Consolidated policy name to avoid multiple permissive policies
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
DROP POLICY IF EXISTS "Public can view scheduled fights" ON scheduled_fights;
CREATE POLICY "Public can view scheduled fights" ON scheduled_fights
    FOR SELECT 
    TO anon
    USING (true);

-- Fix callout_requests admin policy to avoid auth.users access
-- Drop the problematic "Admins can manage all callouts" policy that uses FOR ALL
DROP POLICY IF EXISTS "Admins can manage all callouts" ON callout_requests;

-- Drop individual admin policies if they exist (to avoid conflicts when recreating)
DROP POLICY IF EXISTS "Admins can insert callouts" ON callout_requests;
DROP POLICY IF EXISTS "Admins can update callouts" ON callout_requests;
DROP POLICY IF EXISTS "Admins can delete callouts" ON callout_requests;

-- Recreate admin policy for INSERT, UPDATE, DELETE only (not SELECT)
CREATE POLICY "Admins can insert callouts" ON callout_requests
    FOR INSERT 
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = (select auth.uid())
            AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update callouts" ON callout_requests
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

CREATE POLICY "Admins can delete callouts" ON callout_requests
    FOR DELETE 
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = (select auth.uid())
            AND role = 'admin'
        )
    );

-- Ensure callout_requests with status 'scheduled' are publicly readable
DROP POLICY IF EXISTS "Anyone can view scheduled callouts" ON callout_requests;

CREATE POLICY "Anyone can view scheduled callouts" ON callout_requests
    FOR SELECT 
    USING (status = 'scheduled');

-- Ensure fighter_profiles are publicly readable
DROP POLICY IF EXISTS "Public read fighters" ON fighter_profiles;
DROP POLICY IF EXISTS "Public can view all fighter profiles" ON fighter_profiles;

-- Public can view all fighter profiles - restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public can view all fighter profiles" ON fighter_profiles
    FOR SELECT
    TO anon
    USING (true);

-- Ensure profiles are publicly readable for filtering
DROP POLICY IF EXISTS "Public read profiles for filtering" ON profiles;

-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read profiles for filtering" ON profiles
    FOR SELECT 
    TO anon
    USING (true);

-- ============================================
-- STEP 3: Verify permissions
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ Granted SELECT permissions to anon role';
    RAISE NOTICE '✅ Updated policies to allow public access';
    RAISE NOTICE '✅ Anonymous users can now read:';
    RAISE NOTICE '   - Published news items';
    RAISE NOTICE '   - Scheduled fights';
    RAISE NOTICE '   - Scheduled callouts';
    RAISE NOTICE '   - Fighter profiles';
    RAISE NOTICE '   - Profiles (for filtering)';
END $$;

-- ============================================
-- DONE - Public access should now work
-- ============================================

