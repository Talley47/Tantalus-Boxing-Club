-- Fix RLS policies for matchmaking_requests table
-- This script ensures users can create, view, and manage their own matchmaking requests

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view own matchmaking requests" ON matchmaking_requests;
DROP POLICY IF EXISTS "Users can create own matchmaking requests" ON matchmaking_requests;
DROP POLICY IF EXISTS "Users can update own matchmaking requests" ON matchmaking_requests;
DROP POLICY IF EXISTS "Users can delete own matchmaking requests" ON matchmaking_requests;
DROP POLICY IF EXISTS "Users can view matchmaking requests where they are target" ON matchmaking_requests;
DROP POLICY IF EXISTS "Users can update matchmaking requests where they are target" ON matchmaking_requests;
DROP POLICY IF EXISTS "Admins can manage all matchmaking requests" ON matchmaking_requests;

-- Ensure RLS is enabled
ALTER TABLE matchmaking_requests ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON matchmaking_requests TO authenticated;

-- Policy: Users can view their own matchmaking requests (as requester)
CREATE POLICY "Users can view own matchmaking requests" ON matchmaking_requests
  FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = requester_id)
  );

-- Policy: Users can view matchmaking requests where they are the target
CREATE POLICY "Users can view matchmaking requests where they are target" ON matchmaking_requests
  FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = target_id)
  );

-- Policy: Users can create their own matchmaking requests
CREATE POLICY "Users can create own matchmaking requests" ON matchmaking_requests
  FOR INSERT WITH CHECK (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = requester_id)
  );

-- Policy: Users can update their own matchmaking requests (as requester)
CREATE POLICY "Users can update own matchmaking requests" ON matchmaking_requests
  FOR UPDATE USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = requester_id)
  );

-- Policy: Users can update matchmaking requests where they are the target (to accept/decline)
CREATE POLICY "Users can update matchmaking requests where they are target" ON matchmaking_requests
  FOR UPDATE USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = target_id)
  );

-- Policy: Users can delete their own matchmaking requests
CREATE POLICY "Users can delete own matchmaking requests" ON matchmaking_requests
  FOR DELETE USING (
    auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = requester_id)
  );

-- Policy: Admins can manage all matchmaking requests
CREATE POLICY "Admins can manage all matchmaking requests" ON matchmaking_requests
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );




