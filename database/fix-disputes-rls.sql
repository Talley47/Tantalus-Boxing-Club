-- Fix RLS Policies for disputes table
-- This ensures admins and fighters can access disputes properly
-- Run this in Supabase SQL Editor

-- Enable RLS on disputes table if not already enabled
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own disputes" ON disputes;
    DROP POLICY IF EXISTS "Users can create own disputes" ON disputes;
    DROP POLICY IF EXISTS "Users can update own unresolved disputes" ON disputes;
    DROP POLICY IF EXISTS "Admins can view all disputes" ON disputes;
    DROP POLICY IF EXISTS "Admins can resolve disputes" ON disputes;
    DROP POLICY IF EXISTS "Fighters can view their disputes" ON disputes;
    DROP POLICY IF EXISTS "Fighters can create their disputes" ON disputes;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Admins can view all disputes
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can view all disputes" ON disputes
            FOR SELECT USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table only
        EXECUTE 'CREATE POLICY "Admins can view all disputes" ON disputes
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Fighters can view their own disputes (where they are the disputer or opponent)
CREATE POLICY "Fighters can view their disputes" ON disputes
    FOR SELECT USING (
        disputer_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
        OR opponent_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Fighters can create their own disputes
-- Updated to use simpler IN clause for better compatibility
CREATE POLICY "Fighters can create their disputes" ON disputes
    FOR INSERT WITH CHECK (
        disputer_id IN (
            SELECT id FROM fighter_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- Admins can update/resolve all disputes
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can resolve disputes" ON disputes
            FOR UPDATE USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table only
        EXECUTE 'CREATE POLICY "Admins can resolve disputes" ON disputes
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON disputes TO authenticated;
GRANT SELECT ON disputes TO anon;

-- Add helpful comments
COMMENT ON POLICY "Admins can view all disputes" ON disputes IS 
    'Allows admins to view all disputes in the system';

COMMENT ON POLICY "Fighters can view their disputes" ON disputes IS 
    'Allows fighters to view disputes where they are the disputer or opponent';

COMMENT ON POLICY "Fighters can create their disputes" ON disputes IS 
    'Allows fighters to create disputes where they are the disputer';

COMMENT ON POLICY "Admins can resolve disputes" ON disputes IS 
    'Allows admins to update and resolve disputes';

