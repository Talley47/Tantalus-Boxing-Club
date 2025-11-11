-- Fix Chat Messages Update RLS Policy
-- This ensures users can update their own messages

-- Drop existing update policy if it exists
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update own messages" ON chat_messages;

-- Create comprehensive update policy with both USING and WITH CHECK clauses
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

-- Grant UPDATE permission
GRANT UPDATE ON chat_messages TO authenticated;

-- Verify the policy exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'chat_messages' 
        AND policyname = 'Users can update their own messages'
    ) THEN
        RAISE EXCEPTION 'Policy creation failed';
    END IF;
END $$;

