-- Chat Room Schema
-- This creates a real-time chat room system for fighters

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    fighter_profile_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'link', 'file')),
    metadata JSONB DEFAULT '{}', -- For storing image URLs, link previews, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_fighter_profile_id ON chat_messages(fighter_profile_id);

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Anyone authenticated can view all messages (public chat room)
CREATE POLICY "Anyone authenticated can view chat messages" ON chat_messages
    FOR SELECT USING (auth.role() = 'authenticated');

-- Anyone authenticated can send messages
CREATE POLICY "Anyone authenticated can send chat messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

-- Users can update their own messages (for editing)
CREATE POLICY "Users can update own messages" ON chat_messages
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own messages
CREATE POLICY "Users can delete own messages" ON chat_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Admins can delete any message
CREATE POLICY "Admins can delete any message" ON chat_messages
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_messages TO authenticated;
GRANT SELECT ON chat_messages TO anon;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_chat_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update updated_at
CREATE TRIGGER update_chat_messages_updated_at
    BEFORE UPDATE ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_messages_updated_at();

-- Add helpful comments
COMMENT ON TABLE chat_messages IS 'Stores messages for the public chat room';
COMMENT ON COLUMN chat_messages.message_type IS 'Type of message: text, image, link, or file';
COMMENT ON COLUMN chat_messages.metadata IS 'JSON object for storing additional data like image URLs, link previews, etc.';

