-- Fix RLS Policies for disputes table to allow admins to DELETE
-- This ensures admins can delete resolved disputes
-- Run this in Supabase SQL Editor

-- Enable RLS on disputes table if not already enabled
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;

-- Drop existing DELETE policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admins can delete disputes" ON disputes;
    DROP POLICY IF EXISTS "Admins can delete all disputes" ON disputes;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Admins can delete all disputes
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can delete disputes" ON disputes
            FOR DELETE USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table only
        EXECUTE 'CREATE POLICY "Admins can delete disputes" ON disputes
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant DELETE permission
GRANT DELETE ON disputes TO authenticated;

-- Add helpful comment
COMMENT ON POLICY "Admins can delete disputes" ON disputes IS 
    'Allows admins to delete disputes from the system';




