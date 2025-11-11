-- RLS Policy to allow viewing scheduled callouts (callout_requests with status = 'scheduled')
-- This allows anyone to view scheduled callouts for display on HomePage and My Profile
-- Run this in Supabase SQL Editor

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Anyone can view scheduled callouts" ON callout_requests;

-- Create policy to allow viewing scheduled callouts (status = 'scheduled')
-- This policy works for both authenticated and anonymous users
CREATE POLICY "Anyone can view scheduled callouts" ON callout_requests
    FOR SELECT
    USING (
        status = 'scheduled'
    );

-- Keep the existing policies for viewing own callouts (pending, etc.)
-- The "Fighters can view own callouts" policy should remain
-- This new policy is additive - users can see both their own AND all scheduled callouts

-- Grant SELECT permission to anon role if not already granted
-- This allows unauthenticated users to view scheduled callouts
GRANT SELECT ON callout_requests TO anon;

-- Add comment
COMMENT ON POLICY "Anyone can view scheduled callouts" ON callout_requests IS 
    'Allows anyone (authenticated or anonymous) to view scheduled callouts (status = scheduled) for display on HomePage and My Profile. This enables the league-wide view of all scheduled callout rematches.';

