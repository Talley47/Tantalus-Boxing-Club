-- Comprehensive Fix for viewing ALL active training camps on HomePage
-- This ensures fighters can see all League Active Training Camps, not just their own
-- Run this in Supabase SQL Editor

-- Enable RLS on training_camp_invitations table if not already enabled
ALTER TABLE training_camp_invitations ENABLE ROW LEVEL SECURITY;

-- Drop existing "view active camps" policy if it exists (to recreate it properly)
DROP POLICY IF EXISTS "Anyone can view active training camps" ON training_camp_invitations;

-- Create policy to allow viewing ALL active training camps (status = 'accepted' and not expired)
-- This policy works for both authenticated and anonymous users
-- IMPORTANT: This policy uses OR logic with other SELECT policies, so users can see:
-- 1. Their own camps (from "Fighters can view own training camp invitations")
-- 2. ALL active camps (from this policy)
CREATE POLICY "Anyone can view active training camps" ON training_camp_invitations
    FOR SELECT
    USING (
        status = 'accepted' 
        AND expires_at >= NOW()
    );

-- Grant SELECT permission to authenticated and anon roles
-- This allows all users (authenticated or anonymous) to view active training camps
GRANT SELECT ON training_camp_invitations TO authenticated;
GRANT SELECT ON training_camp_invitations TO anon;

-- Verify the policy was created
DO $$
DECLARE
    policy_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'training_camp_invitations'
        AND policyname = 'Anyone can view active training camps'
    ) INTO policy_exists;
    
    IF policy_exists THEN
        RAISE NOTICE '✅ Policy "Anyone can view active training camps" exists';
    ELSE
        RAISE WARNING '⚠️ Policy "Anyone can view active training camps" was not created';
    END IF;
END $$;

-- List all policies on training_camp_invitations for verification
DO $$
DECLARE
    policy_record RECORD;
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'training_camp_invitations';
    
    RAISE NOTICE '📋 Total policies on training_camp_invitations: %', policy_count;
    
    FOR policy_record IN 
        SELECT policyname, cmd, qual 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'training_camp_invitations'
        ORDER BY policyname
    LOOP
        RAISE NOTICE '  - Policy: % (Command: %)', policy_record.policyname, policy_record.cmd;
    END LOOP;
END $$;

-- Add comment
COMMENT ON POLICY "Anyone can view active training camps" ON training_camp_invitations IS 
    'Allows anyone (authenticated or anonymous) to view ALL active training camps (accepted and not expired) for display on HomePage League Active Training Camps section. This enables the league-wide view of all active training camps, matching Admin Home Page behavior.';

