-- Security: Verify Row Level Security (RLS) is enabled on all tables
-- Run this in Supabase SQL Editor to check RLS status
-- 
-- This script will:
-- 1. List all tables without RLS enabled
-- 2. Show RLS status for all tables
-- 3. List all RLS policies

-- ============================================================================
-- CHECK 1: Tables WITHOUT RLS enabled (should return 0 rows)
-- ============================================================================
SELECT 
    tablename,
    '⚠️ RLS NOT ENABLED' as status
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = false
ORDER BY tablename;

-- ============================================================================
-- CHECK 2: All tables with RLS status
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
    END as policy_count
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- CHECK 3: List all RLS policies
-- ============================================================================
SELECT 
    tablename,
    policyname,
    cmd as command,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        WHEN cmd = 'ALL' THEN 'All Operations'
        ELSE cmd
    END as operation_type
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- CHECK 4: Critical tables that MUST have RLS
-- ============================================================================
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ Protected'
        ELSE '❌ NOT PROTECTED - CRITICAL!'
    END as security_status
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
    'matchmaking_requests'
)
ORDER BY rowsecurity, tablename;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================
DO $$
DECLARE
    total_tables INTEGER;
    tables_without_rls INTEGER;
    total_policies INTEGER;
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
    
    -- Count total policies
    SELECT COUNT(*) INTO total_policies
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    -- Print summary
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RLS SECURITY AUDIT SUMMARY';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total tables: %', total_tables;
    RAISE NOTICE 'Tables with RLS: %', total_tables - tables_without_rls;
    RAISE NOTICE 'Tables WITHOUT RLS: %', tables_without_rls;
    RAISE NOTICE 'Total RLS policies: %', total_policies;
    RAISE NOTICE '========================================';
    
    IF tables_without_rls > 0 THEN
        RAISE WARNING '⚠️  SECURITY ISSUE: % table(s) do NOT have RLS enabled!', tables_without_rls;
        RAISE NOTICE 'Run the queries above to see which tables need RLS enabled.';
    ELSE
        RAISE NOTICE '✅ All tables have RLS enabled!';
    END IF;
    
    IF total_policies = 0 THEN
        RAISE WARNING '⚠️  WARNING: No RLS policies found. Tables may be accessible to all users!';
    END IF;
END $$;

