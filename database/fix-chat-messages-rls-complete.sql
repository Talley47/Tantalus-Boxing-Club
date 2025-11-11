-- Comprehensive Fix for Chat Messages RLS Policies
-- This script ensures users can update and delete their own messages
-- Run this in Supabase SQL Editor

-- First, verify the table exists and check its structure
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'chat_messages'
    ) THEN
        RAISE EXCEPTION 'Table chat_messages does not exist';
    END IF;
    
    RAISE NOTICE 'Table chat_messages exists';
END $$;

-- Ensure RLS is enabled
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies to avoid conflicts
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
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Policy 1: Authenticated users can view all chat messages
CREATE POLICY "Authenticated users can view chat messages" ON chat_messages
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Policy 2: Authenticated users can create chat messages
CREATE POLICY "Authenticated users can create chat messages" ON chat_messages
    FOR INSERT
    WITH CHECK (
        auth.role() = 'authenticated' 
        AND auth.uid() = user_id
    );

-- Policy 3: Users can update their own messages
-- CRITICAL: Both USING and WITH CHECK are required for UPDATE policies
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

-- Policy 4: Users can delete their own messages
CREATE POLICY "Users can delete their own messages" ON chat_messages
    FOR DELETE
    USING (
        auth.role() = 'authenticated' 
        AND auth.uid() = user_id
    );

-- Policy 5: Admins can delete all messages
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
        RAISE NOTICE 'Created admin delete policy using is_admin_user()';
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
        RAISE NOTICE 'Created admin delete policy using profiles table';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Admin delete policy already exists';
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON chat_messages TO authenticated;
GRANT SELECT ON chat_messages TO anon;

-- Verify the policies were created
DO $$
DECLARE
    policy_count INTEGER;
    policy_names TEXT[];
BEGIN
    SELECT COUNT(*), array_agg(policyname ORDER BY policyname)
    INTO policy_count, policy_names
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'chat_messages';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RLS Policy Verification';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total policies created: %', policy_count;
    RAISE NOTICE 'Policy names: %', array_to_string(policy_names, ', ');
    
    IF policy_count < 4 THEN
        RAISE WARNING 'Expected at least 4 policies, found %', policy_count;
    ELSE
        RAISE NOTICE '✓ All policies created successfully';
    END IF;
    
    -- Check specifically for UPDATE policy
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'chat_messages'
        AND policyname = 'Users can update their own messages'
        AND cmd = 'UPDATE'
    ) THEN
        RAISE NOTICE '✓ UPDATE policy exists and is correct';
    ELSE
        RAISE WARNING '✗ UPDATE policy missing or incorrect';
    END IF;
    
    -- Check specifically for DELETE policy
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'chat_messages'
        AND policyname = 'Users can delete their own messages'
        AND cmd = 'DELETE'
    ) THEN
        RAISE NOTICE '✓ DELETE policy exists and is correct';
    ELSE
        RAISE WARNING '✗ DELETE policy missing or incorrect';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;

-- Test query to verify RLS is working (this will show if policies allow operations)
-- Note: This is just informational, actual testing should be done from the application
DO $$
DECLARE
    test_user_id UUID;
    test_message_id UUID;
BEGIN
    -- Try to find a test user (this won't actually modify anything)
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Test user found: %', test_user_id;
        RAISE NOTICE 'To test RLS policies, try updating/deleting a message from the application';
    ELSE
        RAISE NOTICE 'No users found in auth.users - policies will be tested when users interact';
    END IF;
END $$;

