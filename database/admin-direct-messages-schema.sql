-- Admin Direct Messages Schema
-- Allows Admin to send direct messages to fighters (e.g., Live Event selection notifications)
-- Run this in Supabase SQL Editor

-- Create admin_direct_messages table
CREATE TABLE IF NOT EXISTS admin_direct_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter_id UUID REFERENCES fighter_profiles(user_id) ON DELETE CASCADE NOT NULL,
    admin_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    subject TEXT NOT NULL DEFAULT 'Live Event Selection',
    message TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'live_event_selection' CHECK (message_type IN ('live_event_selection', 'tournament_selection', 'general', 'announcement')),
    event_name TEXT, -- Optional: name of the event or tournament (e.g., "King of the Hill Event")
    event_type VARCHAR(50), -- Optional: 'live_event' or 'tournament'
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_admin_direct_messages_fighter_id ON admin_direct_messages(fighter_id);
CREATE INDEX IF NOT EXISTS idx_admin_direct_messages_admin_id ON admin_direct_messages(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_direct_messages_created_at ON admin_direct_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_direct_messages_read_at ON admin_direct_messages(read_at);
CREATE INDEX IF NOT EXISTS idx_admin_direct_messages_message_type ON admin_direct_messages(message_type);

-- Enable RLS
ALTER TABLE admin_direct_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admins can view all messages" ON admin_direct_messages;
    DROP POLICY IF EXISTS "Admins can send messages" ON admin_direct_messages;
    DROP POLICY IF EXISTS "Admins can insert messages" ON admin_direct_messages;
    DROP POLICY IF EXISTS "Admins can update messages" ON admin_direct_messages;
    DROP POLICY IF EXISTS "Admins can delete messages" ON admin_direct_messages;
    DROP POLICY IF EXISTS "Fighters can view their own messages" ON admin_direct_messages;
    DROP POLICY IF EXISTS "Fighters can mark messages as read" ON admin_direct_messages;
END $$;

-- RLS Policies

-- Admins can view all messages
CREATE POLICY "Admins can view all messages"
ON admin_direct_messages
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = (select auth.uid())
        AND profiles.role = 'admin'
    )
);

-- Admins can send messages
CREATE POLICY "Admins can send messages"
ON admin_direct_messages
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = (select auth.uid())
        AND profiles.role = 'admin'
    )
    AND admin_id = (select auth.uid())
);

-- Admins can update messages
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

-- Admins can delete messages
CREATE POLICY "Admins can delete messages"
ON admin_direct_messages
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = (select auth.uid())
        AND profiles.role = 'admin'
    )
);

-- Fighters can view their own messages
CREATE POLICY "Fighters can view their own messages"
ON admin_direct_messages
FOR SELECT
TO authenticated
USING (fighter_id = (select auth.uid()));

-- Fighters can mark messages as read (UPDATE only for read_at)
-- Note: RLS policies cannot check OLD/NEW values, so we rely on application logic
-- to ensure only read_at is updated. This policy just ensures fighters can only
-- update their own messages.
CREATE POLICY "Fighters can mark messages as read"
ON admin_direct_messages
FOR UPDATE
TO authenticated
USING (fighter_id = (select auth.uid()))
WITH CHECK (fighter_id = (select auth.uid()));

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_admin_direct_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if it exists, then create it
DROP TRIGGER IF EXISTS update_admin_direct_messages_updated_at ON admin_direct_messages;
CREATE TRIGGER update_admin_direct_messages_updated_at
    BEFORE UPDATE ON admin_direct_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_admin_direct_messages_updated_at();

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_direct_messages TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Admin direct messages table created successfully';
    RAISE NOTICE '✅ RLS policies configured';
    RAISE NOTICE '✅ Indexes created';
END $$;

