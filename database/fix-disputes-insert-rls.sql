-- Fix RLS Policy for disputes INSERT
-- This ensures fighters can create disputes properly
-- Run this in Supabase SQL Editor

-- Enable RLS on disputes table if not already enabled
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;

-- Drop existing INSERT policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can create own disputes" ON disputes;
    DROP POLICY IF EXISTS "Fighters can create their disputes" ON disputes;
    DROP POLICY IF EXISTS "Authenticated users can create disputes" ON disputes;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create a more robust INSERT policy
-- This policy allows fighters to create disputes where they are the disputer
-- Note: In WITH CHECK clauses, we reference columns directly from the NEW row
CREATE POLICY "Fighters can create their disputes" ON disputes
    FOR INSERT WITH CHECK (
        -- Check if disputer_id matches a fighter profile owned by the current user
        -- Use a subquery that checks if the disputer_id belongs to the current user
        disputer_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- Grant INSERT permission
GRANT INSERT ON disputes TO authenticated;

-- Add helpful comment
COMMENT ON POLICY "Fighters can create their disputes" ON disputes IS 
    'Allows fighters to create disputes where they are the disputer. Checks that disputer_id matches a fighter profile owned by auth.uid().';

-- Verify the policy was created
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'disputes' 
        AND policyname = 'Fighters can create their disputes'
    ) THEN
        RAISE NOTICE '✅ Policy "Fighters can create their disputes" created successfully!';
    ELSE
        RAISE WARNING '⚠️ Policy "Fighters can create their disputes" was not created!';
    END IF;
END $$;

