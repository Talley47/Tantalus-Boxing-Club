-- Fix RLS Policy for fight_url_submissions INSERT
-- This ensures fighters can create submissions properly
-- Run this in Supabase SQL Editor

-- Enable RLS on fight_url_submissions table if not already enabled
ALTER TABLE fight_url_submissions ENABLE ROW LEVEL SECURITY;

-- Drop existing INSERT policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters can create their submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Fighters can insert their submissions" ON fight_url_submissions;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create a more robust INSERT policy
-- This policy allows fighters to create submissions where they are the fighter
CREATE POLICY "Fighters can create their submissions" ON fight_url_submissions
    FOR INSERT WITH CHECK (
        -- Check if fighter_id matches a fighter profile owned by the current user
        fighter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- Grant INSERT permission
GRANT INSERT ON fight_url_submissions TO authenticated;

-- Add helpful comment
COMMENT ON POLICY "Fighters can create their submissions" ON fight_url_submissions IS 
    'Allows fighters to create fight URL submissions where they are the fighter. Checks that fighter_id matches a fighter profile owned by auth.uid().';

-- Verify the policy was created
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'fight_url_submissions' 
        AND policyname = 'Fighters can create their submissions'
    ) THEN
        RAISE NOTICE '✅ Policy "Fighters can create their submissions" created successfully!';
    ELSE
        RAISE WARNING '⚠️ Policy "Fighters can create their submissions" was not created!';
    END IF;
END $$;

