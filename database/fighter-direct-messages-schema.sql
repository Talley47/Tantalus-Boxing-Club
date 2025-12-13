-- Fighter Direct Messages Schema
-- Allows fighters to send direct messages to each other (one-on-one personal chat)
-- Run this in Supabase SQL Editor

-- Create fighter_direct_messages table
CREATE TABLE IF NOT EXISTS fighter_direct_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES fighter_profiles(user_id) ON DELETE CASCADE NOT NULL,
    recipient_id UUID REFERENCES fighter_profiles(user_id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Ensure sender and recipient are different
    CONSTRAINT different_sender_recipient CHECK (sender_id != recipient_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_fighter_direct_messages_sender_id ON fighter_direct_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_fighter_direct_messages_recipient_id ON fighter_direct_messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_fighter_direct_messages_created_at ON fighter_direct_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fighter_direct_messages_read_at ON fighter_direct_messages(read_at);
-- Composite index for conversation queries
CREATE INDEX IF NOT EXISTS idx_fighter_direct_messages_conversation ON fighter_direct_messages(sender_id, recipient_id, created_at DESC);

-- Enable RLS
ALTER TABLE fighter_direct_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters can view their own messages" ON fighter_direct_messages;
    DROP POLICY IF EXISTS "Fighters can send messages" ON fighter_direct_messages;
    DROP POLICY IF EXISTS "Fighters can mark messages as read" ON fighter_direct_messages;
    DROP POLICY IF EXISTS "Fighters can delete their own messages" ON fighter_direct_messages;
END $$;

-- RLS Policies

-- Fighters can view messages where they are sender or recipient
CREATE POLICY "Fighters can view their own messages"
ON fighter_direct_messages
FOR SELECT
TO authenticated
USING (
    sender_id = (select auth.uid()) OR recipient_id = (select auth.uid())
);

-- Fighters can send messages (must be authenticated and sender_id must match auth.uid())
CREATE POLICY "Fighters can send messages"
ON fighter_direct_messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = (select auth.uid())
    AND sender_id != recipient_id
);

-- Fighters can mark messages as read (only if they are the recipient)
-- Note: RLS policies cannot check OLD/NEW values, so we rely on application logic
-- to ensure only read_at is updated. This policy just ensures fighters can only
-- update their own received messages.
CREATE POLICY "Fighters can mark messages as read"
ON fighter_direct_messages
FOR UPDATE
TO authenticated
USING (recipient_id = (select auth.uid()))
WITH CHECK (recipient_id = (select auth.uid()));

-- Fighters can delete their own sent messages
CREATE POLICY "Fighters can delete their own messages"
ON fighter_direct_messages
FOR DELETE
TO authenticated
USING (sender_id = (select auth.uid()));

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_fighter_direct_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_fighter_direct_messages_updated_at ON fighter_direct_messages;
CREATE TRIGGER update_fighter_direct_messages_updated_at
    BEFORE UPDATE ON fighter_direct_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_direct_messages_updated_at();

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON fighter_direct_messages TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Fighter direct messages table created successfully';
    RAISE NOTICE '✅ RLS policies configured';
    RAISE NOTICE '✅ Indexes created';
END $$;

