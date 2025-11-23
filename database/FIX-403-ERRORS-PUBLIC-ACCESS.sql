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
-- STEP 2: Ensure policies allow anonymous access
-- ============================================

-- Drop and recreate news policies to ensure they work for anonymous users
DROP POLICY IF EXISTS "Public read published news" ON news_announcements;

CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT 
    USING (
        COALESCE(is_published, false) = TRUE
    );

-- Ensure authenticated users can read all news (keep existing policy if it works)
-- If the policy doesn't exist, create it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'news_announcements'
        AND policyname = 'Authenticated read all news'
    ) THEN
        CREATE POLICY "Authenticated read all news" ON news_announcements
            FOR SELECT 
            USING (auth.uid() IS NOT NULL);
    END IF;
END $$;

-- Ensure scheduled fights are publicly readable
DROP POLICY IF EXISTS "Public read scheduled fights" ON scheduled_fights;

CREATE POLICY "Public read scheduled fights" ON scheduled_fights
    FOR SELECT 
    USING (true);

-- Ensure callout_requests with status 'scheduled' are publicly readable
DROP POLICY IF EXISTS "Anyone can view scheduled callouts" ON callout_requests;

CREATE POLICY "Anyone can view scheduled callouts" ON callout_requests
    FOR SELECT 
    USING (status = 'scheduled');

-- Ensure fighter_profiles are publicly readable
DROP POLICY IF EXISTS "Public read fighters" ON fighter_profiles;

CREATE POLICY "Public read fighters" ON fighter_profiles
    FOR SELECT 
    USING (true);

-- Ensure profiles are publicly readable for filtering
DROP POLICY IF EXISTS "Public read profiles for filtering" ON profiles;

CREATE POLICY "Public read profiles for filtering" ON profiles
    FOR SELECT 
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

