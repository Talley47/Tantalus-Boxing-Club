-- Fix RLS policies to allow authenticated users to view HomePage data
-- This fixes the issue where authenticated users see "No fighters found" and empty sections
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. FIGHTER_PROFILES - Allow authenticated users to view all profiles
-- ============================================
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing authenticated policy if it exists
DROP POLICY IF EXISTS "Authenticated users can view all fighter profiles" ON fighter_profiles;

-- Create policy for authenticated users to view all fighter profiles
-- This is needed for HomePage rankings, matchmaking, etc.
CREATE POLICY "Authenticated users can view all fighter profiles" ON fighter_profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- ============================================
-- 2. SCHEDULED_FIGHTS - Allow authenticated users to view scheduled fights
-- ============================================
ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;

-- Drop existing authenticated policy if it exists
DROP POLICY IF EXISTS "Authenticated users can view scheduled fights" ON scheduled_fights;

-- Create policy for authenticated users to view scheduled fights
CREATE POLICY "Authenticated users can view scheduled fights" ON scheduled_fights
    FOR SELECT
    TO authenticated
    USING (true);

-- ============================================
-- 3. FIGHT_RECORDS - Allow authenticated users to view fight records
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'fight_records') THEN
        ALTER TABLE fight_records ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Authenticated users can view fight records" ON fight_records;
        
        CREATE POLICY "Authenticated users can view fight records" ON fight_records
            FOR SELECT
            TO authenticated
            USING (true);
    END IF;
END $$;

-- ============================================
-- 4. NEWS_ANNOUNCEMENTS - Allow authenticated users to view news
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'news_announcements') THEN
        ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Authenticated users can view news announcements" ON news_announcements;
        
        CREATE POLICY "Authenticated users can view news announcements" ON news_announcements
            FOR SELECT
            TO authenticated
            USING (COALESCE(is_published, true) = true);
    END IF;
END $$;

-- ============================================
-- 5. TOURNAMENTS - Allow authenticated users to view tournaments
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tournaments') THEN
        ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Authenticated users can view tournaments" ON tournaments;
        
        CREATE POLICY "Authenticated users can view tournaments" ON tournaments
            FOR SELECT
            TO authenticated
            USING (true);
    END IF;
END $$;

-- ============================================
-- 6. TRAINING_CAMP_INVITATIONS - Allow authenticated users to view training camps
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'training_camp_invitations') THEN
        ALTER TABLE training_camp_invitations ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Authenticated users can view training camp invitations" ON training_camp_invitations;
        
        CREATE POLICY "Authenticated users can view training camp invitations" ON training_camp_invitations
            FOR SELECT
            TO authenticated
            USING (status = 'active' OR status = 'Active');
    END IF;
END $$;

-- ============================================
-- 7. CALLOUT_REQUESTS - Allow authenticated users to view scheduled callouts
-- ============================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'callout_requests') THEN
        ALTER TABLE callout_requests ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Authenticated users can view callout requests" ON callout_requests;
        
        CREATE POLICY "Authenticated users can view callout requests" ON callout_requests
            FOR SELECT
            TO authenticated
            USING (status = 'scheduled' OR status = 'Scheduled' OR scheduled_fight_id IS NOT NULL);
    END IF;
END $$;

-- ============================================
-- VERIFICATION - Show all policies
-- ============================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename IN (
        'fighter_profiles',
        'scheduled_fights',
        'news_announcements',
        'tournaments',
        'training_camp_invitations',
        'callout_requests',
        'fight_records'
    )
    AND roles::text LIKE '%authenticated%'
ORDER BY tablename, policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE '✅ AUTHENTICATED USER ACCESS FIXED!';
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'Authenticated users can now view:';
    RAISE NOTICE '  ✅ All fighter profiles (for rankings)';
    RAISE NOTICE '  ✅ Scheduled fights';
    RAISE NOTICE '  ✅ Fight records';
    RAISE NOTICE '  ✅ News announcements';
    RAISE NOTICE '  ✅ Tournaments';
    RAISE NOTICE '  ✅ Training camp invitations';
    RAISE NOTICE '  ✅ Scheduled callouts';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Your HomePage should now display all data!';
    RAISE NOTICE '═══════════════════════════════════════';
END $$;






