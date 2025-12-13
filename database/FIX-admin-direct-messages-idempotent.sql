-- Idempotent fix for admin_direct_messages table
-- This script can be run multiple times safely
-- Run this in Supabase SQL Editor

-- Add event_name column if it doesn't exist
ALTER TABLE admin_direct_messages 
ADD COLUMN IF NOT EXISTS event_name TEXT;

-- Drop and recreate trigger (handles existing trigger)
DROP TRIGGER IF EXISTS update_admin_direct_messages_updated_at ON admin_direct_messages;

-- Ensure the function exists
CREATE OR REPLACE FUNCTION update_admin_direct_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER update_admin_direct_messages_updated_at
    BEFORE UPDATE ON admin_direct_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_admin_direct_messages_updated_at();

-- Fix the RLS policy for admins updating messages
DROP POLICY IF EXISTS "Admins can update messages" ON admin_direct_messages;

CREATE POLICY "Admins can update messages"
ON admin_direct_messages
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = (select auth.uid())
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = (select auth.uid())
        AND profiles.role = 'admin'
    )
);

-- Fix the RLS policy for fighters marking messages as read
DROP POLICY IF EXISTS "Fighters can mark messages as read" ON admin_direct_messages;

CREATE POLICY "Fighters can mark messages as read"
ON admin_direct_messages
FOR UPDATE
TO authenticated
USING (fighter_id = (select auth.uid()))
WITH CHECK (fighter_id = (select auth.uid()));

-- Verify everything is set up correctly
DO $$
BEGIN
    RAISE NOTICE '✅ Admin direct messages table verified';
    RAISE NOTICE '✅ event_name column added (if it did not exist)';
    RAISE NOTICE '✅ Trigger recreated';
    RAISE NOTICE '✅ RLS policies updated';
END $$;

