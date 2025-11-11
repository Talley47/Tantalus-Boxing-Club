-- Comprehensive Fix for fight_url_submissions RLS Policies
-- This ensures fighters can create submissions properly
-- Run this in Supabase SQL Editor

-- Enable RLS on fight_url_submissions table if not already enabled
ALTER TABLE fight_url_submissions ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies to avoid conflicts
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters can view their own submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Fighters can create their submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Fighters can insert their submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Fighters can update their own pending submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Admins can view all submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Admins can update all submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Admins can delete submissions" ON fight_url_submissions;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- 1. Fighters can view their own submissions
CREATE POLICY "Fighters can view their own submissions" ON fight_url_submissions
    FOR SELECT USING (
        fighter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 2. Fighters can create their own submissions
-- This is the critical policy that was failing
CREATE POLICY "Fighters can create their submissions" ON fight_url_submissions
    FOR INSERT WITH CHECK (
        fighter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 3. Fighters can update their own pending submissions (before admin review)
CREATE POLICY "Fighters can update their own pending submissions" ON fight_url_submissions
    FOR UPDATE USING (
        fighter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
        AND status = 'Pending'
    );

-- 4. Admins can view all submissions
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can view all submissions" ON fight_url_submissions
            FOR SELECT USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admins can view all submissions" ON fight_url_submissions
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- 5. Admins can update all submissions (review, approve, reject)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can update all submissions" ON fight_url_submissions
            FOR UPDATE USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admins can update all submissions" ON fight_url_submissions
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- 6. Admins can delete submissions
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can delete submissions" ON fight_url_submissions
            FOR DELETE USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admins can delete submissions" ON fight_url_submissions
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON fight_url_submissions TO authenticated;

-- Verify all policies were created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'fight_url_submissions';
    
    RAISE NOTICE '✅ Total policies created: %', policy_count;
    
    IF policy_count >= 6 THEN
        RAISE NOTICE '✅ All RLS policies for fight_url_submissions created successfully!';
    ELSE
        RAISE WARNING '⚠️ Expected 6 policies but found %. Please check policy creation.', policy_count;
    END IF;
END $$;

-- Add helpful comments
COMMENT ON POLICY "Fighters can view their own submissions" ON fight_url_submissions IS 
    'Allows fighters to view their own fight URL submissions';
COMMENT ON POLICY "Fighters can create their submissions" ON fight_url_submissions IS 
    'Allows fighters to create fight URL submissions. Checks that fighter_id matches a fighter profile owned by auth.uid().';
COMMENT ON POLICY "Fighters can update their own pending submissions" ON fight_url_submissions IS 
    'Allows fighters to update their own submissions that are still pending review';
COMMENT ON POLICY "Admins can view all submissions" ON fight_url_submissions IS 
    'Allows admins to view all fight URL submissions';
COMMENT ON POLICY "Admins can update all submissions" ON fight_url_submissions IS 
    'Allows admins to review, approve, or reject submissions';
COMMENT ON POLICY "Admins can delete submissions" ON fight_url_submissions IS 
    'Allows admins to delete submissions from the system';

