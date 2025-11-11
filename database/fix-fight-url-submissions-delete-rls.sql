-- Fix RLS Policies for fight_url_submissions table to allow admins to DELETE
-- This ensures admins can delete approved and rejected submissions
-- Run this in Supabase SQL Editor

-- Enable RLS on fight_url_submissions table if not already enabled
ALTER TABLE fight_url_submissions ENABLE ROW LEVEL SECURITY;

-- Drop existing DELETE policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admins can delete submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Admins can delete all submissions" ON fight_url_submissions;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Admins can delete all submissions
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can delete submissions" ON fight_url_submissions
            FOR DELETE USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table only
        EXECUTE 'CREATE POLICY "Admins can delete submissions" ON fight_url_submissions
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
GRANT DELETE ON fight_url_submissions TO authenticated;

-- Add helpful comment
COMMENT ON POLICY "Admins can delete submissions" ON fight_url_submissions IS 
    'Allows admins to delete submissions from the system';




