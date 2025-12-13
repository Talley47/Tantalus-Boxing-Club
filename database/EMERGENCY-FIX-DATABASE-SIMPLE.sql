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
DROP POLICY IF EXISTS "Users update own profile" ON fighter_profiles;
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

CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT 
    USING (is_published = TRUE);

CREATE POLICY "Authenticated read all news" ON news_announcements
    FOR SELECT 
    USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated insert news" ON news_announcements
    FOR INSERT 
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admin manage news" ON news_announcements
    FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
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

CREATE POLICY "Public read fighters" ON fighter_profiles
    FOR SELECT 
    USING (true);

CREATE POLICY "Users update own profile" ON fighter_profiles
    FOR UPDATE 
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users insert own profile" ON fighter_profiles
    FOR INSERT 
    WITH CHECK (user_id = auth.uid());

-- SCHEDULED_FIGHTS
DO $$
BEGIN
    ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on scheduled_fights';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on scheduled_fights: %', SQLERRM;
END $$;

CREATE POLICY "Public read scheduled fights" ON scheduled_fights
    FOR SELECT 
    USING (true);

CREATE POLICY "Authenticated manage fights" ON scheduled_fights
    FOR ALL 
    USING ((select auth.uid()) IS NOT NULL);

-- TOURNAMENTS
DO $$
BEGIN
    ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on tournaments';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on tournaments: %', SQLERRM;
END $$;

CREATE POLICY "Public read tournaments" ON tournaments
    FOR SELECT 
    USING (true);

CREATE POLICY "Authenticated manage tournaments" ON tournaments
    FOR ALL 
    USING ((select auth.uid()) IS NOT NULL);

-- TRAINING_CAMP_INVITATIONS
DO $$
BEGIN
    ALTER TABLE training_camp_invitations ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on training_camp_invitations';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on training_camp_invitations: %', SQLERRM;
END $$;

CREATE POLICY "Users read own invitations" ON training_camp_invitations
    FOR SELECT 
    USING (
        inviter_id = auth.uid() 
        OR invitee_id = auth.uid()
    );

CREATE POLICY "Users manage own invitations" ON training_camp_invitations
    FOR ALL 
    USING (
        inviter_id = auth.uid() 
        OR invitee_id = auth.uid()
    );

-- PROFILES
DO $$
BEGIN
    ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Enabled RLS on profiles';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on profiles: %', SQLERRM;
END $$;

CREATE POLICY "Public read profiles for filtering" ON profiles
    FOR SELECT 
    USING (true);

CREATE POLICY "Users update own profile" ON profiles
    FOR UPDATE 
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- ============================================
-- STEP 4: Add critical indexes
-- ============================================
CREATE INDEX IF NOT EXISTS idx_news_published ON news_announcements(is_published) WHERE is_published = TRUE;
CREATE INDEX IF NOT EXISTS idx_news_created_at ON news_announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fighters_user_id ON fighter_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_fighters_points ON fighter_profiles(points DESC);
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

