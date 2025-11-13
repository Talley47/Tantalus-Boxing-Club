-- Comprehensive Fix for Callout Requests RLS Policies
-- This ensures fighters can create callout requests properly
-- Run this in Supabase SQL Editor

-- Enable RLS on callout_requests table if not already enabled
ALTER TABLE callout_requests ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies to avoid conflicts
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters can view own callouts" ON callout_requests;
    DROP POLICY IF EXISTS "Fighters can create callouts" ON callout_requests;
    DROP POLICY IF EXISTS "Targets can update callouts" ON callout_requests;
    DROP POLICY IF EXISTS "Admins can manage all callouts" ON callout_requests;
    DROP POLICY IF EXISTS "Anyone can view scheduled callouts" ON callout_requests;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

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

-- 2. Fighters can create callouts (INSERT policy)
-- This is the critical policy that was failing
CREATE POLICY "Fighters can create callouts" ON callout_requests
    FOR INSERT
    WITH CHECK (
        -- Check that caller_id matches a fighter profile owned by the current user
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
-- Check if is_admin_user function exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user'
    ) THEN
        -- Use is_admin_user function if available
        EXECUTE '
        CREATE POLICY "Admins can manage all callouts" ON callout_requests
            FOR ALL
            USING (is_admin_user())
            WITH CHECK (is_admin_user())';
    ELSE
        -- Fallback: Check if user is in admin_profiles table
        EXECUTE '
        CREATE POLICY "Admins can manage all callouts" ON callout_requests
            FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM profiles
                    WHERE id = auth.uid()
                    AND role = ''admin''
                )
            )
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM profiles
                    WHERE id = auth.uid()
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- 5. Public can view scheduled callouts (for matchmaking display)
CREATE POLICY "Anyone can view scheduled callouts" ON callout_requests
    FOR SELECT
    USING (status = 'scheduled');

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON callout_requests TO authenticated;
GRANT SELECT ON callout_requests TO anon;

-- Add helpful comments
COMMENT ON POLICY "Fighters can create callouts" ON callout_requests IS 
    'Allows fighters to create callout requests where they are the caller. Checks that caller_id matches a fighter profile owned by auth.uid().';

COMMENT ON POLICY "Fighters can view own callouts" ON callout_requests IS 
    'Allows fighters to view callouts where they are either the caller or target.';

COMMENT ON POLICY "Targets can update callouts" ON callout_requests IS 
    'Allows fighters to update (accept/decline) callouts where they are the target.';

-- Verify the policies were created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'callout_requests';
    
    IF policy_count >= 4 THEN
        RAISE NOTICE '✅ Successfully created % policies for callout_requests table!', policy_count;
    ELSE
        RAISE WARNING '⚠️ Only % policies found for callout_requests table. Expected at least 4.', policy_count;
    END IF;
END $$;

-- Test query to verify RLS is working (should return 0 rows if not logged in as a fighter)
-- Uncomment to test:
-- SELECT COUNT(*) FROM callout_requests;

