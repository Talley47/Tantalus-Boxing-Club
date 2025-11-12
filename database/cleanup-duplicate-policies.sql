-- ============================================
-- CLEANUP DUPLICATE POLICIES
-- This script safely removes duplicate RLS policies
-- Run this AFTER reviewing check-database-and-rls-complete.sql
-- ============================================

BEGIN;

-- ============================================
-- STEP 1: Delete duplicate policies (keep the first one)
-- ============================================
DO $$
DECLARE
    policy_rec RECORD;
    kept_policy TEXT;
BEGIN
    -- Find and delete duplicate policies
    FOR policy_rec IN 
        SELECT 
            tablename,
            policyname,
            cmd,
            ROW_NUMBER() OVER (PARTITION BY tablename, policyname ORDER BY cmd) as rn
        FROM pg_policies
        WHERE schemaname = 'public'
        AND (tablename, policyname) IN (
            SELECT tablename, policyname
            FROM pg_policies
            WHERE schemaname = 'public'
            GROUP BY tablename, policyname
            HAVING COUNT(*) > 1
        )
    LOOP
        -- Keep the first one, delete the rest
        IF policy_rec.rn > 1 THEN
            BEGIN
                EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 
                    policy_rec.policyname, 
                    policy_rec.tablename);
                RAISE NOTICE 'Deleted duplicate: %.% (command: %)', 
                    policy_rec.tablename, 
                    policy_rec.policyname, 
                    policy_rec.cmd;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Could not delete %.%: %', 
                        policy_rec.tablename, 
                        policy_rec.policyname, 
                        SQLERRM;
            END;
        ELSE
            RAISE NOTICE 'Keeping: %.% (command: %)', 
                policy_rec.tablename, 
                policy_rec.policyname, 
                policy_rec.cmd;
        END IF;
    END LOOP;
END $$;

-- ============================================
-- STEP 2: Delete blocking policies (qual = false)
-- ============================================
DO $$
DECLARE
    policy_rec RECORD;
BEGIN
    FOR policy_rec IN 
        SELECT tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
        AND qual LIKE '%false%'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 
                policy_rec.policyname, 
                policy_rec.tablename);
            RAISE NOTICE 'Deleted blocking policy: %.%', 
                policy_rec.tablename, 
                policy_rec.policyname;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Could not delete %.%: %', 
                    policy_rec.tablename, 
                    policy_rec.policyname, 
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- ============================================
-- STEP 3: Clean up old/legacy policy names
-- ============================================
DO $$
DECLARE
    policy_rec RECORD;
BEGIN
    FOR policy_rec IN 
        SELECT tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
        AND (
            policyname LIKE '%old%'
            OR policyname LIKE '%legacy%'
            OR policyname LIKE '%backup%'
            OR policyname LIKE '%temp%'
            OR policyname LIKE '%test%'
        )
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 
                policy_rec.policyname, 
                policy_rec.tablename);
            RAISE NOTICE 'Deleted legacy policy: %.%', 
                policy_rec.tablename, 
                policy_rec.policyname;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Could not delete %.%: %', 
                    policy_rec.tablename, 
                    policy_rec.policyname, 
                    SQLERRM;
        END;
    END LOOP;
END $$;

COMMIT;

-- ============================================
-- STEP 4: Final summary
-- ============================================
DO $$
DECLARE
    remaining_duplicates INTEGER;
BEGIN
    SELECT COUNT(*) INTO remaining_duplicates
    FROM (
        SELECT tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
        GROUP BY tablename, policyname
        HAVING COUNT(*) > 1
    ) duplicates;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'CLEANUP COMPLETE';
    RAISE NOTICE '========================================';
    
    IF remaining_duplicates > 0 THEN
        RAISE WARNING '⚠️ Still have % duplicate policies. Manual review needed.', remaining_duplicates;
    ELSE
        RAISE NOTICE '✅ All duplicate policies removed.';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;




