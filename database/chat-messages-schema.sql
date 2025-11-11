-- Chat Messages Schema
-- This creates a table for real-time chat messages in the Social page

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    attachment_url TEXT, -- URL to uploaded image/video/file
    attachment_type VARCHAR(20), -- 'image', 'video', 'file', or NULL for text-only
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries by created_at
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- Add attachment columns if they don't exist
ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS attachment_url TEXT,
ADD COLUMN IF NOT EXISTS attachment_type VARCHAR(20) CHECK (attachment_type IN ('image', 'video', 'file') OR attachment_type IS NULL);

-- Add updated_at trigger
DROP TRIGGER IF EXISTS update_chat_messages_updated_at ON chat_messages;

CREATE OR REPLACE FUNCTION update_chat_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_chat_messages_updated_at
    BEFORE UPDATE ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_messages_updated_at();

-- Enable Row Level Security
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Anyone can view chat messages" ON chat_messages;
    DROP POLICY IF EXISTS "Authenticated users can view chat messages" ON chat_messages;
    DROP POLICY IF EXISTS "Authenticated users can create chat messages" ON chat_messages;
    DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
    DROP POLICY IF EXISTS "Users can delete their own messages" ON chat_messages;
    DROP POLICY IF EXISTS "Admins can delete all messages" ON chat_messages;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Policy: Authenticated users can view all chat messages
CREATE POLICY "Authenticated users can view chat messages" ON chat_messages
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Policy: Authenticated users can create chat messages
CREATE POLICY "Authenticated users can create chat messages" ON chat_messages
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

-- Policy: Users can update their own messages (always allowed)
CREATE POLICY "Users can update their own messages" ON chat_messages
    FOR UPDATE
    USING (
        auth.role() = 'authenticated' 
        AND auth.uid() = user_id
    )
    WITH CHECK (
        auth.role() = 'authenticated' 
        AND auth.uid() = user_id
    );

-- Policy: Users can delete their own messages (always allowed)
CREATE POLICY "Users can delete their own messages" ON chat_messages
    FOR DELETE
    USING (
        auth.role() = 'authenticated' 
        AND auth.uid() = user_id
    );

-- Policy: Admins can delete all messages
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can delete all messages" ON chat_messages
            FOR DELETE USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Admins can delete all messages" ON chat_messages
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_messages TO authenticated;
GRANT SELECT ON chat_messages TO anon;

-- Add helpful comments
COMMENT ON TABLE chat_messages IS 'Stores real-time chat messages for the Social page';
COMMENT ON COLUMN chat_messages.user_id IS 'The user who sent the message';
COMMENT ON COLUMN chat_messages.message IS 'The chat message content';
COMMENT ON COLUMN chat_messages.attachment_url IS 'URL to uploaded image/video/file attachment';
COMMENT ON COLUMN chat_messages.attachment_type IS 'Type of attachment: image, video, or file';
COMMENT ON COLUMN chat_messages.created_at IS 'When the message was created';
COMMENT ON COLUMN chat_messages.updated_at IS 'When the message was last updated';

