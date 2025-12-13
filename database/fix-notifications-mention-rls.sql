-- Fix Notifications RLS for @Mention Notifications
-- This ensures authenticated users can create notifications for other users
-- (needed for @mentions in Club Chat)
-- Run this in Supabase SQL Editor

-- Ensure RLS is enabled
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies to avoid conflicts
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Drop all policies for notifications table
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'notifications'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON notifications', policy_record.policyname);
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Policy 1: Users can view their own notifications
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT
    USING ((select auth.uid()) = user_id);

-- Policy 2: Authenticated users can create notifications for any user
-- This is needed for system notifications (@mentions, callouts, invitations, etc.)
CREATE POLICY "Authenticated users can create notifications" ON notifications
    FOR INSERT
    WITH CHECK ((select auth.role()) = 'authenticated');

-- Policy 3: Users can update their own notifications (mark as read, etc.)
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE
    USING ((select auth.uid()) = user_id)
    WITH CHECK ((select auth.uid()) = user_id);

-- Policy 4: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE
    USING ((select auth.uid()) = user_id);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT SELECT ON notifications TO anon;

-- Verify the policies were created
DO $$
DECLARE
    policy_count INTEGER;
    insert_policy_exists BOOLEAN;
BEGIN
    SELECT COUNT(*)
    INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'notifications';
    
    SELECT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'notifications'
        AND policyname = 'Authenticated users can create notifications'
        AND cmd = 'INSERT'
    ) INTO insert_policy_exists;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Notifications RLS Policy Verification';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total policies created: %', policy_count;
    
    IF insert_policy_exists THEN
        RAISE NOTICE '✅ INSERT policy exists - @mention notifications will work!';
    ELSE
        RAISE WARNING '✗ INSERT policy missing - @mention notifications will fail!';
    END IF;
    
    IF policy_count >= 4 THEN
        RAISE NOTICE '✅ All policies created successfully';
    ELSE
        RAISE WARNING 'Expected at least 4 policies, found %', policy_count;
    END IF;
    
    RAISE NOTICE '========================================';
END $$;

