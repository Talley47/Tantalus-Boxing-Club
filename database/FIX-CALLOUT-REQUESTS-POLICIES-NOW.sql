-- FIX CALLOUT_REQUESTS POLICIES - Remove broken challenger_id references
-- This script drops ALL policies on callout_requests and recreates them correctly
-- Run this FIRST before running any other database fix scripts

-- ============================================
-- STEP 1: Disable RLS to avoid policy validation errors
-- ============================================
DO $$
BEGIN
    ALTER TABLE callout_requests DISABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Disabled RLS on callout_requests';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not disable RLS on callout_requests: %', SQLERRM;
END $$;

-- ============================================
-- STEP 2: Drop ALL existing policies dynamically
-- ============================================
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Find and drop all policies on callout_requests
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'callout_requests'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON callout_requests', policy_record.policyname);
            RAISE NOTICE '✅ Dropped policy: %', policy_record.policyname;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Could not drop policy %: %', policy_record.policyname, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '✅ Finished dropping all policies on callout_requests';
END $$;

-- ============================================
-- STEP 3: Re-enable RLS
-- ============================================
DO $$
BEGIN
    ALTER TABLE callout_requests ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ Re-enabled RLS on callout_requests';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️ Could not enable RLS on callout_requests: %', SQLERRM;
END $$;

-- ============================================
-- STEP 4: Create correct policies using caller_id and target_id
-- ============================================

-- 1. Fighters can view callouts where they are caller or target
CREATE POLICY "Fighters can view own callouts" ON callout_requests
    FOR SELECT
    USING (
        caller_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        ) OR
        target_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 2. Fighters can create callouts
CREATE POLICY "Fighters can create callouts" ON callout_requests
    FOR INSERT
    WITH CHECK (
        caller_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 3. Targets can update (accept/decline) callouts
CREATE POLICY "Targets can update callouts" ON callout_requests
    FOR UPDATE
    USING (
        target_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        target_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 4. Admins can manage all callouts
CREATE POLICY "Admins can manage all callouts" ON callout_requests
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
        ) OR
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND email = 'tantalusboxingclub@gmail.com'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'admin'
        ) OR
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND email = 'tantalusboxingclub@gmail.com'
        )
    );

-- 5. Public can view scheduled callouts
CREATE POLICY "Anyone can view scheduled callouts" ON callout_requests
    FOR SELECT
    USING (status = 'scheduled');

-- ============================================
-- STEP 5: Verify policies
-- ============================================
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'callout_requests';
    
    RAISE NOTICE '✅ Created % policies for callout_requests table', policy_count;
END $$;

-- ============================================
-- DONE - callout_requests policies are now fixed
-- ============================================

