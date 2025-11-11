-- Comprehensive Fix for Notifications RLS Policies
-- This ensures authenticated users can create notifications for other users
-- (needed for @mentions, callouts, training camp invitations, etc.)

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
    USING (auth.uid() = user_id);

-- Policy 2: Authenticated users can create notifications for any user
-- This is needed for system notifications (@mentions, callouts, invitations, etc.)
CREATE POLICY "Authenticated users can create notifications" ON notifications
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy 3: Users can update their own notifications (mark as read, etc.)
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy 4: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE
    USING (auth.uid() = user_id);

-- Policy 5: Admins can view all notifications
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can view all notifications" ON notifications
            FOR SELECT USING (is_admin_user())';
        RAISE NOTICE 'Created admin view policy using is_admin_user()';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Admins can view all notifications" ON notifications
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
        RAISE NOTICE 'Created admin view policy using profiles table';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Admin view policy already exists';
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT SELECT ON notifications TO anon;

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
    AND tablename = 'notifications';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Notifications RLS Policy Verification';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total policies created: %', policy_count;
    RAISE NOTICE 'Policy names: %', array_to_string(policy_names, ', ');
    
    IF policy_count < 4 THEN
        RAISE WARNING 'Expected at least 4 policies, found %', policy_count;
    ELSE
        RAISE NOTICE '✓ All policies created successfully';
    END IF;
    
    -- Check specifically for INSERT policy
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'notifications'
        AND policyname = 'Authenticated users can create notifications'
        AND cmd = 'INSERT'
    ) THEN
        RAISE NOTICE '✓ INSERT policy exists and allows authenticated users to create notifications for any user';
    ELSE
        RAISE WARNING '✗ INSERT policy missing or incorrect';
    END IF;
    
    -- Check specifically for SELECT policy
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'notifications'
        AND policyname = 'Users can view their own notifications'
        AND cmd = 'SELECT'
    ) THEN
        RAISE NOTICE '✓ SELECT policy exists and allows users to view their own notifications';
    ELSE
        RAISE WARNING '✗ SELECT policy missing or incorrect';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;

