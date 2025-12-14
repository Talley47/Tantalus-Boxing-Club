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
    DROP POLICY IF EXISTS "Admins can view all fight records" ON fight_records;
    DROP POLICY IF EXISTS "Admins can insert fight records" ON fight_records;
    DROP POLICY IF EXISTS "Admins can update fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters can view their fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters and admins can view fight records" ON fight_records;
    DROP POLICY IF EXISTS "Authenticated can view fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters can insert their fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters and admins can insert fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters can update their fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters and admins can update fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters can delete their fight records" ON fight_records;
    DROP POLICY IF EXISTS "Fighters and admins can delete fight records" ON fight_records;
    
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
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Public can view fight records" ON fight_records
    FOR SELECT
    TO anon
    USING (true);

-- Authenticated users can view all fight records
-- This avoids multiple permissive policies for the same role and action
-- Note: This policy applies to authenticated users, while "Public can view fight records" applies to anon users
DO $$
BEGIN
    -- Drop old policies if they exist
    DROP POLICY IF EXISTS "Fighters can view their fight records" ON fight_records;
    DROP POLICY IF EXISTS "Admins can view all fight records" ON fight_records;
    DROP POLICY IF EXISTS "Authenticated can view fight records" ON fight_records;
    
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Authenticated can view fight records" ON fight_records
            FOR SELECT TO authenticated USING (true)';
    ELSE
        -- Fallback: same policy (no function dependency)
        EXECUTE 'CREATE POLICY "Authenticated can view fight records" ON fight_records
            FOR SELECT TO authenticated USING (true)';
    END IF;
END $$;

-- Combined INSERT policy: Fighters can insert their own records OR admins can insert any record
-- This avoids multiple permissive policies for the same role and action
DO $$
BEGIN
    -- Drop old policies if they exist
    DROP POLICY IF EXISTS "Fighters can insert their fight records" ON fight_records;
    
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Fighters and admins can insert fight records" ON fight_records
            FOR INSERT TO authenticated WITH CHECK (
                fighter_id = (select auth.uid()) 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Fighters and admins can insert fight records" ON fight_records
            FOR INSERT TO authenticated WITH CHECK (
                fighter_id = (select auth.uid()) 
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Combined UPDATE policy: Fighters can update their own records OR admins can update any record
-- This avoids multiple permissive policies for the same role and action
-- The policy is created in the DO block below

-- Combined DELETE policy: Fighters can delete their own records OR admins can delete any record
-- This avoids multiple permissive policies for the same role and action
DO $$
BEGIN
    -- Drop old policies if they exist
    DROP POLICY IF EXISTS "Fighters can delete their fight records" ON fight_records;
    
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Fighters and admins can delete fight records" ON fight_records
            FOR DELETE TO authenticated USING (
                fighter_id = (select auth.uid()) 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Fighters and admins can delete fight records" ON fight_records
            FOR DELETE TO authenticated USING (
                fighter_id = (select auth.uid()) 
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Admins can manage fight records (SELECT, INSERT, UPDATE only - DELETE is handled above)
-- Use is_admin_user function if available, otherwise check profiles table
DO $$
BEGIN
    -- Drop old FOR ALL policy if it exists
    DROP POLICY IF EXISTS "Admins can manage all fight records" ON fight_records;
    
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Create combined UPDATE policy: Fighters can update their own records OR admins can update any record
        EXECUTE 'CREATE POLICY "Fighters and admins can update fight records" ON fight_records
            FOR UPDATE TO authenticated USING (
                fighter_id = (select auth.uid()) 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Fighters and admins can update fight records" ON fight_records
            FOR UPDATE TO authenticated USING (
                fighter_id = (select auth.uid()) 
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
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

COMMENT ON POLICY "Authenticated can view fight records" ON fight_records IS 
    'Allows authenticated users to view all fight records. This avoids multiple permissive policies for the authenticated role.';

COMMENT ON POLICY "Fighters and admins can insert fight records" ON fight_records IS 
    'Allows fighters to insert their own fight records or admins to insert any fight record. Combined policy to avoid multiple permissive policies.';

COMMENT ON POLICY "Fighters and admins can delete fight records" ON fight_records IS 
    'Allows fighters to delete their own fight records or admins to delete any fight record. Combined policy to avoid multiple permissive policies.';

COMMENT ON POLICY "Fighters and admins can update fight records" ON fight_records IS 
    'Allows fighters to update their own fight records or admins to update any fight record. Combined policy to avoid multiple permissive policies.';

