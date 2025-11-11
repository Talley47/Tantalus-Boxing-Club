-- Fix Chat Messages Update and Delete RLS Policies
-- This ensures users can update and delete their own messages

-- Drop ALL existing policies to avoid conflicts
-- Using DO block to handle errors gracefully
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Drop all policies for chat_messages table
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'chat_messages'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON chat_messages', policy_record.policyname);
    END LOOP;
END $$;

-- Policy: Authenticated users can view all chat messages
CREATE POLICY "Authenticated users can view chat messages" ON chat_messages
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Policy: Authenticated users can create chat messages
CREATE POLICY "Authenticated users can create chat messages" ON chat_messages
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

-- Policy: Users can update their own messages
-- Both USING and WITH CHECK clauses are required for UPDATE policies
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

-- Policy: Users can delete their own messages
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
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_messages TO authenticated;
GRANT SELECT ON chat_messages TO anon;

-- Verify the policies exist
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'chat_messages';
    
    IF policy_count < 4 THEN
        RAISE NOTICE 'Warning: Expected at least 4 policies, found %', policy_count;
    ELSE
        RAISE NOTICE 'Success: Created % policies for chat_messages', policy_count;
    END IF;
END $$;

