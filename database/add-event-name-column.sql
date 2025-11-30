-- Add event_name column to admin_direct_messages table
-- Run this in Supabase SQL Editor if the column doesn't exist

ALTER TABLE admin_direct_messages 
ADD COLUMN IF NOT EXISTS event_name TEXT;

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'admin_direct_messages' 
AND column_name = 'event_name';

