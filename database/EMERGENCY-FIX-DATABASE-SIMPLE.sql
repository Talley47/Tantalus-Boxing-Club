-- EMERGENCY FIX: Database Overload - SIMPLIFIED VERSION
-- This version avoids complex loops and handles callout_requests separately
-- IMPORTANT: Run FIX-CALLOUT-REQUESTS-POLICIES-NOW.sql FIRST if you get challenger_id errors
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: DISABLE RLS ON CRITICAL TABLES
-- ============================================
DO $$
BEGIN
    ALTER TABLE news_announcements DISABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Disabled RLS on news_announcements';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not disable RLS on news_announcements: %', SQLERRM;
END $$;

DO $$
BEGIN
    ALTER TABLE fighter_profiles DISABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Disabled RLS on fighter_profiles';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not disable RLS on fighter_profiles: %', SQLERRM;
END $$;

DO $$
BEGIN
    ALTER TABLE scheduled_fights DISABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Disabled RLS on scheduled_fights';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not disable RLS on scheduled_fights: %', SQLERRM;
END $$;

DO $$
BEGIN
    ALTER TABLE tournaments DISABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Disabled RLS on tournaments';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not disable RLS on tournaments: %', SQLERRM;
END $$;

DO $$
BEGIN
    ALTER TABLE training_camp_invitations DISABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Disabled RLS on training_camp_invitations';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not disable RLS on training_camp_invitations: %', SQLERRM;
END $$;

DO $$
BEGIN
    ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Disabled RLS on profiles';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not disable RLS on profiles: %', SQLERRM;
END $$;

-- Skip callout_requests - fix it separately with FIX-CALLOUT-REQUESTS-POLICIES-NOW.sql

-- ============================================
-- STEP 2: Drop common policy names (no loops)
-- ============================================
-- News policies
DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated read all news" ON news_announcements;
DROP POLICY IF EXISTS "Authenticated insert news" ON news_announcements;
DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
DROP POLICY IF EXISTS "Admin read all news" ON news_announcements;
DROP POLICY IF EXISTS "Fighters can insert fight results" ON news_announcements;
DROP POLICY IF EXISTS "Anyone can view news and announcements" ON news_announcements;
DROP POLICY IF EXISTS "Only admins can manage news and announcements" ON news_announcements;

-- Fighter profiles policies
DROP POLICY IF EXISTS "Public read fighters" ON fighter_profiles;
DROP POLICY IF EXISTS "Public can view all fighter profiles" ON fighter_profiles;
DROP POLICY IF EXISTS "Users update own profile" ON fighter_profiles;
DROP POLICY IF EXISTS "Users can update own fighter profile" ON fighter_profiles;
DROP POLICY IF EXISTS "Users insert own profile" ON fighter_profiles;

-- Scheduled fights policies
DROP POLICY IF EXISTS "Public read scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Authenticated manage fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Anyone can view scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Only admins can manage scheduled fights" ON scheduled_fights;

-- Tournaments policies
DROP POLICY IF EXISTS "Public read tournaments" ON tournaments;
DROP POLICY IF EXISTS "Authenticated manage tournaments" ON tournaments;

-- Training camp invitations policies
DROP POLICY IF EXISTS "Users read own invitations" ON training_camp_invitations;
DROP POLICY IF EXISTS "Users manage own invitations" ON training_camp_invitations;

-- Profiles policies
DROP POLICY IF EXISTS "Public read profiles for filtering" ON profiles;
DROP POLICY IF EXISTS "Users update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can check roles for filtering" ON profiles;

-- ============================================
-- STEP 3: Re-enable RLS with SIMPLE policies
-- ============================================

-- NEWS_ANNOUNCEMENTS
DO $$
BEGIN
    ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on news_announcements';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on news_announcements: %', SQLERRM;
END $$;

-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT 
    TO anon
    USING (is_published = TRUE);

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

-- Admin write access for news (UPDATE and DELETE only - INSERT is handled by combined policy, SELECT by separate policy)
-- Split into separate policies to avoid multiple permissive policies for the same role and action
DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
DROP POLICY IF EXISTS "Admin update news" ON news_announcements;
DROP POLICY IF EXISTS "Admin delete news" ON news_announcements;

CREATE POLICY "Admin update news" ON news_announcements
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = (select auth.uid())
            AND email = 'tantalusboxingclub@gmail.com'
        )
    );

CREATE POLICY "Admin delete news" ON news_announcements
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = (select auth.uid())
            AND email = 'tantalusboxingclub@gmail.com'
        )
    );

-- FIGHTER_PROFILES
DO $$
BEGIN
    ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on fighter_profiles';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on fighter_profiles: %', SQLERRM;
END $$;

-- Public can view all fighter profiles - restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public can view all fighter profiles" ON fighter_profiles
    FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "Users can update own fighter profile" ON fighter_profiles
    FOR UPDATE
    TO authenticated
    USING (user_id = (select auth.uid()))
    WITH CHECK (user_id = (select auth.uid()));

-- Use combined policy: "Users and admins can insert fighter profiles" (matches fix-fighter-profiles-rls.sql)
DROP POLICY IF EXISTS "Users can insert own fighter profile" ON fighter_profiles;
DROP POLICY IF EXISTS "Users and admins can insert fighter profiles" ON fighter_profiles;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Users and admins can insert fighter profiles" 
            ON fighter_profiles 
            FOR INSERT
            TO authenticated
            WITH CHECK (
                user_id = (select auth.uid()) 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Users and admins can insert fighter profiles" 
            ON fighter_profiles 
            FOR INSERT
            TO authenticated
            WITH CHECK (
                user_id = (select auth.uid()) 
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- SCHEDULED_FIGHTS
DO $$
BEGIN
    ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on scheduled_fights';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on scheduled_fights: %', SQLERRM;
END $$;

-- Consolidated policy name to avoid multiple permissive policies
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
DROP POLICY IF EXISTS "Public can view scheduled fights" ON scheduled_fights;
CREATE POLICY "Public can view scheduled fights" ON scheduled_fights
    FOR SELECT 
    TO anon
    USING (true);

-- Split "Authenticated manage fights" from FOR ALL into separate policies
-- PostgreSQL doesn't support FOR SELECT, INSERT, UPDATE, so we create separate policies
-- DELETE is handled by admin-only policy to avoid multiple permissive policies
DROP POLICY IF EXISTS "Authenticated manage fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Authenticated can view scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Authenticated can insert scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Authenticated can update scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Fighters and admins can update scheduled fights" ON scheduled_fights;

-- Authenticated users can view scheduled fights
CREATE POLICY "Authenticated can view scheduled fights" ON scheduled_fights
    FOR SELECT
    TO authenticated
    USING ((select auth.uid()) IS NOT NULL);

-- Note: INSERT is handled by "Fighters and admins can create scheduled fights" policy
-- This avoids multiple permissive policies for the same role and action
-- The combined policy allows fighters (who are one of the fighters) or admins to insert

-- Note: UPDATE is handled by "Fighters and admins can update scheduled fights" policy
-- This avoids multiple permissive policies for the same role and action
-- The combined policy allows fighters (who are one of the fighters) or admins to update

-- Note: DELETE is handled by "Admins can delete scheduled fights" policy only
-- This avoids multiple permissive policies for the same role and action

-- TOURNAMENTS
DO $$
BEGIN
    ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on tournaments';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on tournaments: %', SQLERRM;
END $$;

-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read tournaments" ON tournaments
    FOR SELECT 
    TO anon
    USING (true);

-- Split "Authenticated manage tournaments" from FOR ALL into separate policies
-- PostgreSQL doesn't support FOR SELECT, INSERT, UPDATE, DELETE, so we create separate policies
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Authenticated manage tournaments" ON tournaments;
DROP POLICY IF EXISTS "Authenticated can view tournaments" ON tournaments;
DROP POLICY IF EXISTS "Authenticated can insert tournaments" ON tournaments;
DROP POLICY IF EXISTS "Authenticated can update tournaments" ON tournaments;
DROP POLICY IF EXISTS "Authenticated can delete tournaments" ON tournaments;

-- Authenticated users can view tournaments
CREATE POLICY "Authenticated can view tournaments" ON tournaments
    FOR SELECT
    TO authenticated
    USING ((select auth.uid()) IS NOT NULL);

-- Note: INSERT, UPDATE, DELETE policies for authenticated users can be added here if needed
-- For now, only SELECT is handled to avoid multiple permissive policies

-- TRAINING_CAMP_INVITATIONS
DO $$
BEGIN
    ALTER TABLE training_camp_invitations ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on training_camp_invitations';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on training_camp_invitations: %', SQLERRM;
END $$;

-- Combined SELECT policy: Users can read their own invitations (as inviter or invitee)
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
CREATE POLICY "Users read own invitations" ON training_camp_invitations
    FOR SELECT
    TO authenticated
    USING (
        inviter_id = (select auth.uid()) 
        OR invitee_id = (select auth.uid())
    );

-- Split "Users manage own invitations" from FOR ALL into separate policies for INSERT, UPDATE, DELETE
-- PostgreSQL doesn't support FOR INSERT, UPDATE, DELETE, so we create separate policies
-- SELECT is handled by "Users read own invitations" policy above
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Users manage own invitations" ON training_camp_invitations;
DROP POLICY IF EXISTS "Users can insert invitations" ON training_camp_invitations;
DROP POLICY IF EXISTS "Users can update invitations" ON training_camp_invitations;
DROP POLICY IF EXISTS "Users can delete invitations" ON training_camp_invitations;

-- Users can insert invitations (as inviter)
CREATE POLICY "Users can insert invitations" ON training_camp_invitations
    FOR INSERT
    TO authenticated
    WITH CHECK (
        inviter_id = (select auth.uid())
    );

-- Users can update their own invitations (as inviter or invitee)
CREATE POLICY "Users can update invitations" ON training_camp_invitations
    FOR UPDATE
    TO authenticated
    USING (
        inviter_id = (select auth.uid()) 
        OR invitee_id = (select auth.uid())
    );

-- Users can delete their own invitations (as inviter or invitee)
CREATE POLICY "Users can delete invitations" ON training_camp_invitations
    FOR DELETE
    TO authenticated
    USING (
        inviter_id = (select auth.uid()) 
        OR invitee_id = (select auth.uid())
    );

-- PROFILES
DO $$
BEGIN
    ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on profiles';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on profiles: %', SQLERRM;
END $$;

-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public read profiles for filtering" ON profiles
    FOR SELECT 
    TO anon
    USING (true);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE
    TO authenticated
    USING (id = (select auth.uid()))
    WITH CHECK (id = (select auth.uid()));

-- ============================================
-- STEP 4: Add critical indexes
-- ============================================
-- Drop duplicate indexes if they exist
DROP INDEX IF EXISTS idx_news_published;
DROP INDEX IF EXISTS idx_news_published_simple;
DROP INDEX IF EXISTS idx_news_is_published;

-- Create index with consistent naming (idx_news_announcements_is_published)
CREATE INDEX IF NOT EXISTS idx_news_announcements_is_published ON news_announcements(is_published) WHERE is_published = TRUE;
-- Drop duplicate indexes if they exist
DROP INDEX IF EXISTS idx_news_created_at;
DROP INDEX IF EXISTS idx_news_announcements_created;

-- Create index with consistent naming (idx_news_announcements_created_at)
CREATE INDEX IF NOT EXISTS idx_news_announcements_created_at ON news_announcements(created_at DESC);
-- Drop duplicate index if it exists (idx_fighters_user_id is duplicate of idx_fighter_profiles_user_id)
DROP INDEX IF EXISTS idx_fighters_user_id;

-- Create index with consistent naming (idx_fighter_profiles_user_id)
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_user_id ON fighter_profiles(user_id);
-- Drop duplicate index if it exists (idx_fighters_points is duplicate of idx_fighter_profiles_points)
DROP INDEX IF EXISTS idx_fighters_points;

-- Create index with consistent naming (idx_fighter_profiles_points)
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_points ON fighter_profiles(points DESC);
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);

-- ============================================
-- STEP 5: Analyze tables
-- ============================================
ANALYZE news_announcements;
ANALYZE fighter_profiles;
ANALYZE profiles;

-- ============================================
-- DONE - Database should now be fast
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ Emergency database fix completed successfully!';
    RAISE NOTICE '⚠️ If you still get challenger_id errors, run FIX-CALLOUT-REQUESTS-POLICIES-NOW.sql first';
END $$;

