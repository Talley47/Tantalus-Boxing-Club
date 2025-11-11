-- Fix RLS Policies for fight_records table
-- Ensures fighters can insert their own fight records and admins can manage all records
-- Run this in Supabase SQL Editor

-- Enable RLS on fight_records table if not already enabled
ALTER TABLE fight_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (comprehensive list)
DO $$
BEGIN
    -- Old policy names
    DROP POLICY IF EXISTS "Users can view own fight records" ON fight_records;
    DROP POLICY IF EXISTS "Users can insert own fight records" ON fight_records;
    DROP POLICY IF EXISTS "Users can update own fight records" ON fight_records;
    DROP POLICY IF EXISTS "Users can delete own fight records" ON fight_records;
    
    -- New policy names
    DROP POLICY IF EXISTS "Public can view fight records" ON fight_records;
    DROP POLICY IF EXISTS "Admins can manage all fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters can view their fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters can insert their fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters can update their fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters can delete their fight records" ON fight_records;
    
    -- Additional potential policy names
    DROP POLICY IF EXISTS "Users can view all fight records" ON fight_records;
    DROP POLICY IF EXISTS "Users can insert their own fight records" ON fight_records;
    DROP POLICY IF EXISTS "Users can update their own fight records" ON fight_records;
    DROP POLICY IF EXISTS "Users can delete their own fight records" ON fight_records;
EXCEPTION
    WHEN OTHERS THEN
        -- Continue even if some policies don't exist
        NULL;
END $$;

-- Public read access (for rankings, statistics, etc.)
CREATE POLICY "Public can view fight records" ON fight_records
    FOR SELECT USING (true);

-- Fighters can view their own fight records
-- Since fighter_id references fighter_profiles(user_id), we can check directly
CREATE POLICY "Fighters can view their fight records" ON fight_records
    FOR SELECT USING (
        fighter_id = auth.uid()
    );

-- Fighters can insert their own fight records
-- Since fighter_id references fighter_profiles(user_id), we can check directly
CREATE POLICY "Fighters can insert their fight records" ON fight_records
    FOR INSERT WITH CHECK (
        fighter_id = auth.uid()
    );

-- Fighters can update their own fight records
CREATE POLICY "Fighters can update their fight records" ON fight_records
    FOR UPDATE USING (
        fighter_id = auth.uid()
    );

-- Fighters can delete their own fight records
CREATE POLICY "Fighters can delete their fight records" ON fight_records
    FOR DELETE USING (
        fighter_id = auth.uid()
    );

-- Admins can manage all fight records
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can manage all fight records" ON fight_records
            FOR ALL USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table only
        EXECUTE 'CREATE POLICY "Admins can manage all fight records" ON fight_records
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON fight_records TO authenticated;
GRANT SELECT ON fight_records TO anon;

-- Add helpful comments
COMMENT ON POLICY "Public can view fight records" ON fight_records IS 
    'Allows anyone to view fight records for rankings and statistics';

COMMENT ON POLICY "Fighters can view their fight records" ON fight_records IS 
    'Allows fighters to view their own fight records';

COMMENT ON POLICY "Fighters can insert their fight records" ON fight_records IS 
    'Allows fighters to insert their own fight records';

COMMENT ON POLICY "Fighters can update their fight records" ON fight_records IS 
    'Allows fighters to update their own fight records';

COMMENT ON POLICY "Fighters can delete their fight records" ON fight_records IS 
    'Allows fighters to delete their own fight records';

COMMENT ON POLICY "Admins can manage all fight records" ON fight_records IS 
    'Allows admins to view, insert, update, and delete all fight records';

