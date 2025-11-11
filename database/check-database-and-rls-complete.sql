-- ============================================
-- COMPLETE DATABASE & RLS DIAGNOSTIC
-- Run this to check your Supabase database schema and RLS policies
-- ============================================

-- ============================================
-- PART 1: CHECK TABLES
-- ============================================
SELECT 
    'TABLE CHECK' as check_type,
    table_name,
    CASE 
        WHEN table_schema = 'public' THEN '✅ Exists in public schema'
        ELSE '⚠️ Exists in ' || table_schema || ' schema'
    END as status
FROM information_schema.tables
WHERE table_schema IN ('public', 'auth')
AND table_name IN (
    -- Core tables
    'profiles',
    'fighter_profiles',
    'fight_records',
    'rankings',
    'scheduled_fights',
    
    -- Matchmaking & Training
    'matchmaking_requests',
    'training_camp_invitations',
    'training_camps',
    'callout_requests',
    
    -- Tournaments
    'tournaments',
    'tournament_participants',
    'tournament_brackets',
    'tournament_results',
    
    -- Disputes
    'disputes',
    'dispute_messages',
    
    -- News & Media
    'news_announcements',
    'news_fight_results',
    'media_assets',
    
    -- Events
    'events',
    
    -- Notifications
    'notifications',
    
    -- Admin
    'admin_logs',
    'system_settings',
    
    -- Other
    'tiers',
    'tier_history',
    'fight_url_submissions',
    'title_belts',
    'achievements',
    'user_achievements'
)
ORDER BY table_name;

-- ============================================
-- PART 2: CHECK RLS STATUS
-- ============================================
SELECT 
    'RLS STATUS' as check_type,
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Enabled'
        ELSE '❌ RLS Disabled'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN (
    'profiles',
    'fighter_profiles',
    'fight_records',
    'rankings',
    'scheduled_fights',
    'matchmaking_requests',
    'training_camp_invitations',
    'training_camps',
    'callout_requests',
    'tournaments',
    'tournament_participants',
    'disputes',
    'dispute_messages',
    'news_announcements',
    'news_fight_results',
    'media_assets',
    'events',
    'notifications',
    'fight_url_submissions'
)
ORDER BY tablename;

-- ============================================
-- PART 3: CHECK RLS POLICIES
-- ============================================
SELECT 
    'RLS POLICIES' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================
-- PART 4: FIND DUPLICATE/CONFLICTING POLICIES
-- ============================================
SELECT 
    'DUPLICATE POLICIES' as check_type,
    tablename,
    policyname,
    COUNT(*) as duplicate_count,
    STRING_AGG(cmd::text, ', ') as commands
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename, policyname
HAVING COUNT(*) > 1
ORDER BY tablename, policyname;

-- ============================================
-- PART 5: CHECK FIGHTER_PROFILES SPECIFICALLY
-- ============================================
SELECT 
    'FIGHTER_PROFILES POLICIES' as check_type,
    policyname,
    cmd as command,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN 'User-specific'
        WHEN qual LIKE '%true%' OR qual IS NULL THEN 'Public/Open'
        WHEN qual LIKE '%admin%' THEN 'Admin-only'
        ELSE 'Other'
    END as policy_type
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- ============================================
-- PART 6: CHECK NOTIFICATIONS POLICIES
-- ============================================
SELECT 
    'NOTIFICATIONS POLICIES' as check_type,
    policyname,
    cmd as command,
    qual as using_expression
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'notifications'
ORDER BY policyname;

-- ============================================
-- PART 7: CHECK FOR PROBLEMATIC POLICIES
-- ============================================
-- Policies that might be too restrictive or conflicting
SELECT 
    'PROBLEMATIC POLICIES' as check_type,
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%false%' THEN '⚠️ Always blocks (qual = false)'
        WHEN cmd = 'SELECT' AND qual NOT LIKE '%true%' AND qual NOT LIKE '%auth.uid()%' THEN '⚠️ Might be too restrictive'
        ELSE 'Check manually'
    END as issue
FROM pg_policies
WHERE schemaname = 'public'
AND (
    qual LIKE '%false%'
    OR (cmd = 'SELECT' AND qual IS NULL)
)
ORDER BY tablename, policyname;

-- ============================================
-- PART 8: CHECK CONSTRAINT ON TIER
-- ============================================
SELECT 
    'TIER CONSTRAINT' as check_type,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname LIKE '%tier%';

-- ============================================
-- PART 9: SUMMARY & RECOMMENDATIONS
-- ============================================
DO $$
DECLARE
    table_count INTEGER;
    rls_enabled_count INTEGER;
    policy_count INTEGER;
    duplicate_policy_count INTEGER;
BEGIN
    -- Count tables
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE';
    
    -- Count RLS enabled tables
    SELECT COUNT(*) INTO rls_enabled_count
    FROM pg_tables
    WHERE schemaname = 'public'
    AND rowsecurity = true;
    
    -- Count policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public';
    
    -- Count duplicate policies
    SELECT COUNT(*) INTO duplicate_policy_count
    FROM (
        SELECT tablename, policyname, COUNT(*) as cnt
        FROM pg_policies
        WHERE schemaname = 'public'
        GROUP BY tablename, policyname
        HAVING COUNT(*) > 1
    ) duplicates;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DATABASE SUMMARY';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total tables in public schema: %', table_count;
    RAISE NOTICE 'Tables with RLS enabled: %', rls_enabled_count;
    RAISE NOTICE 'Total RLS policies: %', policy_count;
    RAISE NOTICE 'Duplicate policies found: %', duplicate_policy_count;
    RAISE NOTICE '';
    
    IF duplicate_policy_count > 0 THEN
        RAISE WARNING '⚠️ You have duplicate policies. Check PART 4 above for details.';
        RAISE NOTICE '   Recommendation: Drop duplicate policies and keep only one.';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;



