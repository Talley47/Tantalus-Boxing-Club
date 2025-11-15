-- ============================================================================
-- COMPLETE RLS SECURITY VERIFICATION SCRIPT
-- ============================================================================
-- Run this in Supabase SQL Editor to comprehensively verify RLS security
-- This script will:
-- 1. Check all tables for RLS status
-- 2. List all RLS policies
-- 3. Identify security gaps
-- 4. Provide fix recommendations
-- ============================================================================

-- ============================================================================
-- SECTION 1: TABLES WITHOUT RLS (CRITICAL - Should return 0 rows)
-- ============================================================================
SELECT 
    '🔴 CRITICAL' as severity,
    tablename,
    'RLS NOT ENABLED' as status,
    'Run: ALTER TABLE ' || tablename || ' ENABLE ROW LEVEL SECURITY;' as fix_command
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = false
ORDER BY tablename;

-- ============================================================================
-- SECTION 2: ALL TABLES WITH RLS STATUS
-- ============================================================================
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Enabled'
        ELSE '❌ RLS Disabled'
    END as rls_status,
    CASE 
        WHEN rowsecurity THEN (
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = pg_tables.tablename
        )
        ELSE 0
    END as policy_count,
    CASE 
        WHEN rowsecurity AND (
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = pg_tables.tablename
        ) = 0 THEN '⚠️ RLS enabled but NO POLICIES - Table is locked!'
        WHEN rowsecurity THEN '✅ Protected'
        ELSE '❌ NOT PROTECTED'
    END as security_status
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY 
    CASE WHEN rowsecurity THEN 1 ELSE 0 END,
    tablename;

-- ============================================================================
-- SECTION 3: ALL RLS POLICIES (Detailed View)
-- ============================================================================
SELECT 
    tablename,
    policyname,
    cmd as operation,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        WHEN cmd = 'ALL' THEN 'All Operations'
        ELSE cmd
    END as operation_type,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- SECTION 4: CRITICAL TABLES SECURITY STATUS
-- ============================================================================
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ Protected'
        ELSE '🔴 NOT PROTECTED - CRITICAL!'
    END as security_status,
    CASE 
        WHEN rowsecurity THEN (
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = critical_tables.tablename
        )
        ELSE 0
    END as policy_count,
    CASE 
        WHEN NOT rowsecurity THEN 'ALTER TABLE ' || tablename || ' ENABLE ROW LEVEL SECURITY;'
        ELSE '✅ RLS enabled'
    END as action_required
FROM (
    SELECT tablename, rowsecurity
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename IN (
        'fighter_profiles',
        'fight_records',
        'chat_messages',
        'notifications',
        'training_camp_invitations',
        'callout_requests',
        'disputes',
        'scheduled_fights',
        'matchmaking_requests',
        'profiles',
        'users',
        'media_assets',
        'tournaments',
        'tournament_participants',
        'news',
        'calendar_events'
    )
) as critical_tables
ORDER BY 
    CASE WHEN rowsecurity THEN 1 ELSE 0 END,
    tablename;

-- ============================================================================
-- SECTION 5: TABLES WITH RLS BUT NO POLICIES (LOCKED TABLES)
-- ============================================================================
SELECT 
    '⚠️ WARNING' as severity,
    t.tablename,
    'RLS enabled but NO POLICIES' as status,
    'Table is completely locked - no one can access it!' as issue,
    'You need to create policies for this table' as fix_required
FROM pg_tables t
WHERE t.schemaname = 'public'
AND t.rowsecurity = true
AND NOT EXISTS (
    SELECT 1 
    FROM pg_policies p
    WHERE p.schemaname = 'public'
    AND p.tablename = t.tablename
)
ORDER BY t.tablename;

-- ============================================================================
-- SECTION 6: POLICY COVERAGE ANALYSIS
-- ============================================================================
SELECT 
    tablename,
    COUNT(DISTINCT CASE WHEN cmd = 'SELECT' THEN 1 END) as select_policies,
    COUNT(DISTINCT CASE WHEN cmd = 'INSERT' THEN 1 END) as insert_policies,
    COUNT(DISTINCT CASE WHEN cmd = 'UPDATE' THEN 1 END) as update_policies,
    COUNT(DISTINCT CASE WHEN cmd = 'DELETE' THEN 1 END) as delete_policies,
    COUNT(DISTINCT CASE WHEN cmd = 'ALL' THEN 1 END) as all_policies,
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN cmd = 'SELECT' THEN 1 END) = 0 THEN '⚠️ No SELECT policy'
        WHEN COUNT(DISTINCT CASE WHEN cmd = 'INSERT' THEN 1 END) = 0 THEN '⚠️ No INSERT policy'
        WHEN COUNT(DISTINCT CASE WHEN cmd = 'UPDATE' THEN 1 END) = 0 THEN '⚠️ No UPDATE policy'
        WHEN COUNT(DISTINCT CASE WHEN cmd = 'DELETE' THEN 1 END) = 0 THEN '⚠️ No DELETE policy'
        ELSE '✅ All operations covered'
    END as coverage_status
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- ============================================================================
-- SECTION 7: SUMMARY REPORT
-- ============================================================================
DO $$
DECLARE
    total_tables INTEGER;
    tables_without_rls INTEGER;
    tables_with_rls INTEGER;
    tables_with_rls_no_policies INTEGER;
    total_policies INTEGER;
    critical_tables_count INTEGER;
    critical_tables_protected INTEGER;
BEGIN
    -- Count total tables
    SELECT COUNT(*) INTO total_tables
    FROM pg_tables 
    WHERE schemaname = 'public';
    
    -- Count tables without RLS
    SELECT COUNT(*) INTO tables_without_rls
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND rowsecurity = false;
    
    -- Count tables with RLS
    SELECT COUNT(*) INTO tables_with_rls
    FROM pg_tables 
    WHERE schemaname = 'public' 
    AND rowsecurity = true;
    
    -- Count tables with RLS but no policies (locked)
    SELECT COUNT(*) INTO tables_with_rls_no_policies
    FROM pg_tables t
    WHERE t.schemaname = 'public'
    AND t.rowsecurity = true
    AND NOT EXISTS (
        SELECT 1 
        FROM pg_policies p
        WHERE p.schemaname = 'public'
        AND p.tablename = t.tablename
    );
    
    -- Count total policies
    SELECT COUNT(*) INTO total_policies
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    -- Count critical tables
    SELECT COUNT(*) INTO critical_tables_count
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename IN (
        'fighter_profiles', 'fight_records', 'chat_messages',
        'notifications', 'training_camp_invitations', 'callout_requests',
        'disputes', 'scheduled_fights', 'matchmaking_requests',
        'profiles', 'users', 'media_assets'
    );
    
    -- Count protected critical tables
    SELECT COUNT(*) INTO critical_tables_protected
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND rowsecurity = true
    AND tablename IN (
        'fighter_profiles', 'fight_records', 'chat_messages',
        'notifications', 'training_camp_invitations', 'callout_requests',
        'disputes', 'scheduled_fights', 'matchmaking_requests',
        'profiles', 'users', 'media_assets'
    );
    
    -- Print comprehensive summary
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '🔒 COMPLETE RLS SECURITY AUDIT SUMMARY';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
    RAISE NOTICE '📊 OVERALL STATISTICS:';
    RAISE NOTICE '   Total tables: %', total_tables;
    RAISE NOTICE '   Tables with RLS: %', tables_with_rls;
    RAISE NOTICE '   Tables WITHOUT RLS: %', tables_without_rls;
    RAISE NOTICE '   Tables locked (RLS but no policies): %', tables_with_rls_no_policies;
    RAISE NOTICE '   Total RLS policies: %', total_policies;
    RAISE NOTICE '';
    RAISE NOTICE '🔴 CRITICAL TABLES:';
    RAISE NOTICE '   Total critical tables: %', critical_tables_count;
    RAISE NOTICE '   Protected critical tables: %', critical_tables_protected;
    RAISE NOTICE '   Unprotected critical tables: %', (critical_tables_count - critical_tables_protected);
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    
    -- Security assessment
    IF tables_without_rls > 0 THEN
        RAISE WARNING '🔴 CRITICAL: % table(s) do NOT have RLS enabled!', tables_without_rls;
        RAISE NOTICE '   → These tables are accessible to all users!';
        RAISE NOTICE '   → Review Section 1 for list and fix commands.';
    ELSE
        RAISE NOTICE '✅ All tables have RLS enabled!';
    END IF;
    
    IF tables_with_rls_no_policies > 0 THEN
        RAISE WARNING '⚠️  WARNING: % table(s) have RLS but NO POLICIES!', tables_with_rls_no_policies;
        RAISE NOTICE '   → These tables are completely locked!';
        RAISE NOTICE '   → Review Section 5 for list.';
    END IF;
    
    IF critical_tables_protected < critical_tables_count THEN
        RAISE WARNING '🔴 CRITICAL: % critical table(s) are NOT protected!', (critical_tables_count - critical_tables_protected);
        RAISE NOTICE '   → Review Section 4 for details.';
    ELSE
        RAISE NOTICE '✅ All critical tables are protected!';
    END IF;
    
    IF total_policies = 0 THEN
        RAISE WARNING '⚠️  WARNING: No RLS policies found!';
        RAISE NOTICE '   → Tables may be locked or unprotected.';
    ELSE
        RAISE NOTICE '✅ % RLS policies are configured.', total_policies;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '📋 NEXT STEPS:';
    RAISE NOTICE '   1. Review all sections above';
    RAISE NOTICE '   2. Fix any tables without RLS (Section 1)';
    RAISE NOTICE '   3. Add policies to locked tables (Section 5)';
    RAISE NOTICE '   4. Verify critical tables are protected (Section 4)';
    RAISE NOTICE '   5. Test with different user accounts';
    RAISE NOTICE '============================================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- END OF VERIFICATION SCRIPT
-- ============================================================================
-- After running this script:
-- 1. Review all sections
-- 2. Fix any issues found
-- 3. Re-run to verify fixes
-- 4. Test with actual user accounts
-- ============================================================================

