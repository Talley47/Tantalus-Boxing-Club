-- CRITICAL FIX: Notifications RLS for @Mention Notifications
-- This script will fix the RLS policy to allow authenticated users to create notifications
-- Run this in Supabase SQL Editor

-- Step 1: Ensure RLS is enabled
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing policies (using multiple methods to be sure)
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Method 1: Drop by name (common policy names)
    DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
    DROP POLICY IF EXISTS "Users can insert notifications" ON notifications;
    DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
    DROP POLICY IF EXISTS "Admins can insert notifications" ON notifications;
    DROP POLICY IF EXISTS "Authenticated users can create notifications" ON notifications;
    DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
    DROP POLICY IF EXISTS "Users can delete their own notifications" ON notifications;
    DROP POLICY IF EXISTS "Admins can view all notifications" ON notifications;
    
    -- Method 2: Drop all policies dynamically
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'notifications'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON notifications', r.policyname);
            RAISE NOTICE 'Dropped policy: %', r.policyname;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not drop policy %: %', r.policyname, SQLERRM;
        END;
    END LOOP;
END $$;

-- Step 3: Create the essential policies

-- Policy 1: Users can view their own notifications
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy 2: CRITICAL - Allow ANY authenticated user to INSERT notifications for ANY user_id
-- This uses auth.uid() IS NOT NULL which is more reliable than auth.role()
CREATE POLICY "Authenticated users can create notifications" ON notifications
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Policy 3: Users can update their own notifications
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy 4: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE
    USING (auth.uid() = user_id);

-- Step 4: Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT SELECT ON notifications TO anon;

-- Step 5: Verify the fix
DO $$
DECLARE
    policy_count INTEGER;
    insert_policy_exists BOOLEAN;
    insert_policy_check TEXT;
BEGIN
    -- Count total policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'notifications';
    
    -- Check if INSERT policy exists
    SELECT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'notifications'
        AND policyname = 'Authenticated users can create notifications'
        AND cmd = 'INSERT'
    ) INTO insert_policy_exists;
    
    -- Get the WITH CHECK expression
    SELECT with_check INTO insert_policy_check
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'notifications'
    AND policyname = 'Authenticated users can create notifications'
    AND cmd = 'INSERT'
    LIMIT 1;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Notifications RLS Fix Verification';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total policies: %', policy_count;
    
    IF insert_policy_exists THEN
        RAISE NOTICE '✅ INSERT policy EXISTS';
        RAISE NOTICE '   Policy name: Authenticated users can create notifications';
        RAISE NOTICE '   WITH CHECK: %', COALESCE(insert_policy_check, 'NULL');
        RAISE NOTICE '✅ @mention notifications should now work!';
    ELSE
        RAISE EXCEPTION '❌ INSERT policy MISSING - Fix failed!';
    END IF;
    
    IF policy_count >= 4 THEN
        RAISE NOTICE '✅ All essential policies created';
    ELSE
        RAISE WARNING '⚠️  Expected at least 4 policies, found %', policy_count;
    END IF;
    
    RAISE NOTICE '========================================';
END $$;

