-- RLS Policy to allow viewing all active training camps on HomePage
-- This allows anyone (including unauthenticated users) to view active training camps
-- Run this in Supabase SQL Editor

-- Drop existing "view own" policy if we want to replace it, or add a new public policy
-- We'll add a new policy that allows viewing active training camps publicly
DROP POLICY IF EXISTS "Anyone can view active training camps" ON training_camp_invitations;

-- Create policy to allow viewing active training camps (status = 'accepted' and not expired)
-- This policy works for both authenticated and anonymous users
CREATE POLICY "Anyone can view active training camps" ON training_camp_invitations
    FOR SELECT
    USING (
        status = 'accepted' 
        AND expires_at >= NOW()
    );

-- Keep the existing policy for viewing own invitations (pending, etc.)
-- The "Fighters can view own training camp invitations" policy should remain
-- This new policy is additive - users can see both their own AND all active camps

-- Grant SELECT permission to anon role if not already granted
-- This allows unauthenticated users to view active training camps
GRANT SELECT ON training_camp_invitations TO anon;

-- Add comment
COMMENT ON POLICY "Anyone can view active training camps" ON training_camp_invitations IS 
    'Allows anyone (authenticated or anonymous) to view active training camps (accepted and not expired) for display on HomePage. This enables the league-wide view of all active training camps.';

