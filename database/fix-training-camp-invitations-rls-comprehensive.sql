-- Comprehensive Fix for training_camp_invitations RLS Policies
-- This ensures fighters can create training camp invitations properly
-- Run this in Supabase SQL Editor

-- Enable RLS on training_camp_invitations table if not already enabled
ALTER TABLE training_camp_invitations ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies to avoid conflicts
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters can view own training camp invitations" ON training_camp_invitations;
    DROP POLICY IF EXISTS "Fighters can create training camp invitations" ON training_camp_invitations;
    DROP POLICY IF EXISTS "Invitees can update training camp invitations" ON training_camp_invitations;
    DROP POLICY IF EXISTS "Admins can manage all training camp invitations" ON training_camp_invitations;
    DROP POLICY IF EXISTS "Anyone can view active training camps" ON training_camp_invitations;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- 1. Fighters can view their own invitations (as inviter or invitee)
CREATE POLICY "Fighters can view own training camp invitations" ON training_camp_invitations
    FOR SELECT USING (
        inviter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
        OR invitee_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 2. Fighters can create invitations
-- This is the critical policy that was failing
CREATE POLICY "Fighters can create training camp invitations" ON training_camp_invitations
    FOR INSERT WITH CHECK (
        inviter_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 3. Invitees can update (accept/decline) their invitations
CREATE POLICY "Invitees can update training camp invitations" ON training_camp_invitations
    FOR UPDATE USING (
        invitee_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- 4. Admins can manage all invitations
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can manage all training camp invitations" ON training_camp_invitations
            FOR ALL USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admins can manage all training camp invitations" ON training_camp_invitations
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON training_camp_invitations TO authenticated;

-- Verify all policies were created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'training_camp_invitations';
    
    RAISE NOTICE '✅ Total policies created: %', policy_count;
    
    IF policy_count >= 4 THEN
        RAISE NOTICE '✅ All RLS policies for training_camp_invitations created successfully!';
    ELSE
        RAISE WARNING '⚠️ Expected 4 policies but found %. Please check policy creation.', policy_count;
    END IF;
END $$;

-- Add helpful comments
COMMENT ON POLICY "Fighters can view own training camp invitations" ON training_camp_invitations IS 
    'Allows fighters to view invitations where they are the inviter or invitee';
COMMENT ON POLICY "Fighters can create training camp invitations" ON training_camp_invitations IS 
    'Allows fighters to create training camp invitations. Checks that inviter_id matches a fighter profile owned by auth.uid().';
COMMENT ON POLICY "Invitees can update training camp invitations" ON training_camp_invitations IS 
    'Allows invitees to accept or decline invitations';
COMMENT ON POLICY "Admins can manage all training camp invitations" ON training_camp_invitations IS 
    'Allows admins to manage all training camp invitations';

