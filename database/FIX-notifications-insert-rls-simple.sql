-- SIMPLE FIX: Allow authenticated users to create notifications for any user
-- This fixes @mention notifications in Club Chat
-- Run this in Supabase SQL Editor

-- Step 1: Drop ALL existing policies on notifications table
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'notifications'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON notifications', r.policyname);
    END LOOP;
END $$;

-- Step 2: Create the essential policies

-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- CRITICAL: Authenticated users can INSERT notifications for ANY user
-- This allows @mentions, callouts, invitations, etc.
CREATE POLICY "Authenticated users can create notifications" ON notifications
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Users can update their own notifications
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE
    USING (auth.uid() = user_id);

-- Step 3: Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT SELECT ON notifications TO anon;

-- Step 4: Verify
DO $$
DECLARE
    insert_policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO insert_policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'notifications'
    AND cmd = 'INSERT'
    AND policyname = 'Authenticated users can create notifications';
    
    IF insert_policy_count > 0 THEN
        RAISE NOTICE '✅ SUCCESS: INSERT policy created! @mention notifications will now work.';
    ELSE
        RAISE EXCEPTION '❌ FAILED: INSERT policy was not created. Please check for errors above.';
    END IF;
END $$;

