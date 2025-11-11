-- Enhanced Notifications Schema
-- Updates the notifications table to support all notification types

-- First, update any existing rows with invalid types to 'General'
UPDATE notifications 
SET type = 'General' 
WHERE type NOT IN (
  'Match', 
  'Tournament', 
  'Tier', 
  'Dispute', 
  'Award', 
  'General',
  'FightRequest',
  'TrainingCamp',
  'Callout',
  'FightUrlSubmission',
  'Event',
  'News',
  'NewFighter'
);

-- Update notification type constraint to include all new types
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
  'Match', 
  'Tournament', 
  'Tier', 
  'Dispute', 
  'Award', 
  'General',
  'FightRequest',
  'TrainingCamp',
  'Callout',
  'FightUrlSubmission',
  'Event',
  'News',
  'NewFighter'
));

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created_at ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_is_read ON notifications(user_id, is_read) WHERE is_read = false;

-- Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
    DROP POLICY IF EXISTS "Authenticated users can create notifications" ON notifications;
    DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
    DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;
    DROP POLICY IF EXISTS "Admins can view all notifications" ON notifications;
    DROP POLICY IF EXISTS "Anyone can view chat messages" ON notifications;
    DROP POLICY IF EXISTS "Authenticated users can view chat messages" ON notifications;
    DROP POLICY IF EXISTS "Authenticated users can create chat messages" ON notifications;
    DROP POLICY IF EXISTS "Users can update their own messages" ON notifications;
    DROP POLICY IF EXISTS "Users can delete their own messages" ON notifications;
    DROP POLICY IF EXISTS "Admins can delete all messages" ON notifications;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Policy: Users can view their own notifications
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Authenticated users can create notifications (for system triggers)
CREATE POLICY "Authenticated users can create notifications" ON notifications
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy: Users can update their own notifications
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE
    USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT SELECT ON notifications TO anon;

