-- Fix RLS Policies for fighter_profiles to allow queries by id (not just user_id)
-- This fixes 406 errors when querying fighter profiles by their profile id
-- Run this in Supabase SQL Editor

-- Enable RLS on fighter_profiles table if not already enabled
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing SELECT policies that might be causing conflicts
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public can view all fighter profiles" ON fighter_profiles;
    DROP POLICY IF EXISTS "Public can view fighter profiles" ON fighter_profiles;
    DROP POLICY IF EXISTS "Anyone can view fighter profiles" ON fighter_profiles;
    DROP POLICY IF EXISTS "Public read access" ON fighter_profiles;
    DROP POLICY IF EXISTS "Users can view all fighter profiles" ON fighter_profiles;
    DROP POLICY IF EXISTS "Authenticated users can view all fighter profiles" ON fighter_profiles;
    DROP POLICY IF EXISTS "Users can view own fighter profile" ON fighter_profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create a comprehensive public read policy that allows queries by id or user_id
-- Public can view all fighter profiles (restricted to anon only to avoid multiple permissive policies for authenticated role)
CREATE POLICY "Public can view all fighter profiles" 
    ON fighter_profiles 
    FOR SELECT
    TO anon
    USING (true);  -- Allow anonymous users to read all fighter profiles (needed for rankings, matchmaking, disputes)

-- Combined SELECT policy: Users can view their own fighter profile OR admins can view all
-- This avoids multiple permissive policies for the same role and action
DROP POLICY IF EXISTS "Users and admins can view fighter profiles" ON fighter_profiles;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Users and admins can view fighter profiles" 
            ON fighter_profiles 
            FOR SELECT
            TO authenticated
            USING (
                (select auth.uid()) = user_id 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Users and admins can view fighter profiles" 
            ON fighter_profiles 
            FOR SELECT
            TO authenticated
            USING (
                (select auth.uid()) = user_id 
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Ensure INSERT and UPDATE policies exist
DO $$
BEGIN
    -- Drop existing INSERT/UPDATE policies
    DROP POLICY IF EXISTS "Users can insert own fighter profile" ON fighter_profiles;
    DROP POLICY IF EXISTS "Users can update own fighter profile" ON fighter_profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Use combined policy to avoid multiple permissive policies
DROP POLICY IF EXISTS "Users and admins can insert fighter profiles" ON fighter_profiles;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Users and admins can insert fighter profiles" 
            ON fighter_profiles 
            FOR INSERT
            TO authenticated
            WITH CHECK (
                (select auth.uid()) = user_id 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Users and admins can insert fighter profiles" 
            ON fighter_profiles 
            FOR INSERT
            TO authenticated
            WITH CHECK (
                (select auth.uid()) = user_id 
                OR EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

CREATE POLICY "Users can update own fighter profile" 
    ON fighter_profiles 
    FOR UPDATE
    TO authenticated
    USING ((select auth.uid()) = user_id);

-- Admin policies (if is_admin_user function exists)
DO $$
BEGIN
    -- Drop existing admin policy
    DROP POLICY IF EXISTS "Admins can manage fighter profiles" ON fighter_profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
    
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Use is_admin_user function for admin policies
        EXECUTE 'CREATE POLICY "Admins can manage fighter profiles" 
            ON fighter_profiles 
            FOR ALL TO authenticated
            USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Admins can manage fighter profiles" 
            ON fighter_profiles 
            FOR ALL TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON fighter_profiles TO authenticated;
GRANT SELECT ON fighter_profiles TO anon;

-- Add helpful comments
COMMENT ON POLICY "Public can view all fighter profiles" ON fighter_profiles IS 
    'Allows anyone to view fighter profiles for rankings, matchmaking, disputes, and public pages. Works for queries by id or user_id.';

COMMENT ON POLICY "Users and admins can view fighter profiles" ON fighter_profiles IS 
    'Allows users to view their own fighter profile or admins to view all fighter profiles. Combined policy to avoid multiple permissive policies.';

COMMENT ON POLICY "Users and admins can insert fighter profiles" ON fighter_profiles IS 
    'Allows users to create their own fighter profile or admins to create any fighter profile. Combined policy to avoid multiple permissive policies.';

COMMENT ON POLICY "Users can update own fighter profile" ON fighter_profiles IS 
    'Allows users to update their own fighter profile';


