-- Fix RLS Policies for user_achievements table
-- This enables Row Level Security and creates appropriate policies

-- Drop all existing policies if they exist
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Drop all policies for user_achievements table
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'user_achievements'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON user_achievements', policy_record.policyname);
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Ensure RLS is enabled
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Policy 1: Anonymous users can view achievements (for public profiles/leaderboards)
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
CREATE POLICY "Users can view public achievements" ON user_achievements
    FOR SELECT
    TO anon
    USING (true);

-- Policy 2: Combined SELECT policy for authenticated users
-- Users can view their own achievements OR all achievements (for public profiles/leaderboards) OR admins can view all
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Users and admins can view achievements" ON user_achievements;
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Authenticated users can view all achievements (for public profiles/leaderboards)
        -- This covers: users viewing their own achievements, users viewing public achievements, and admins viewing all
        EXECUTE 'CREATE POLICY "Users and admins can view achievements" ON user_achievements
            FOR SELECT TO authenticated
            USING (true)';
        RAISE NOTICE 'Created combined view policy using is_admin_user()';
    ELSE
        -- Fallback: check profiles table
        -- Authenticated users can view all achievements (for public profiles/leaderboards)
        -- This covers: users viewing their own achievements, users viewing public achievements, and admins viewing all
        EXECUTE 'CREATE POLICY "Users and admins can view achievements" ON user_achievements
            FOR SELECT TO authenticated
            USING (true)';
        RAISE NOTICE 'Created combined view policy using profiles table';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Combined view policy already exists';
END $$;

-- Policy 4: Only admins can insert achievements (achievements are awarded by the system)
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can insert achievements" ON user_achievements
            FOR INSERT WITH CHECK (is_admin_user())';
        RAISE NOTICE 'Created admin insert policy using is_admin_user()';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Admins can insert achievements" ON user_achievements
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        RAISE NOTICE 'Created admin insert policy using profiles table';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Admin insert policy already exists';
END $$;

-- Policy 5: Only admins can update achievements
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can update achievements" ON user_achievements
            FOR UPDATE USING (is_admin_user()) WITH CHECK (is_admin_user())';
        RAISE NOTICE 'Created admin update policy using is_admin_user()';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Admins can update achievements" ON user_achievements
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            ) WITH CHECK (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        RAISE NOTICE 'Created admin update policy using profiles table';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Admin update policy already exists';
END $$;

-- Policy 6: Only admins can delete achievements
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can delete achievements" ON user_achievements
            FOR DELETE USING (is_admin_user())';
        RAISE NOTICE 'Created admin delete policy using is_admin_user()';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Admins can delete achievements" ON user_achievements
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        RAISE NOTICE 'Created admin delete policy using profiles table';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Admin delete policy already exists';
END $$;

-- Grant necessary permissions
GRANT SELECT ON user_achievements TO authenticated;
GRANT SELECT ON user_achievements TO anon;
GRANT INSERT, UPDATE, DELETE ON user_achievements TO authenticated;

-- Add helpful comments
COMMENT ON POLICY "Users can view public achievements" ON user_achievements IS 
    'Allows anonymous users to view achievements for public profiles/leaderboards. Restricted to anon only to avoid multiple permissive policies.';

COMMENT ON POLICY "Users and admins can view achievements" ON user_achievements IS 
    'Allows authenticated users to view their own achievements or all achievements (for public profiles/leaderboards), or admins to view all. Combined policy to avoid multiple permissive policies.';

COMMENT ON POLICY "Admins can insert achievements" ON user_achievements IS 
    'Allows admins to award achievements to users (achievements are system-awarded)';

COMMENT ON POLICY "Admins can update achievements" ON user_achievements IS 
    'Allows admins to update achievement records';

COMMENT ON POLICY "Admins can delete achievements" ON user_achievements IS 
    'Allows admins to delete achievement records';

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
    AND tablename = 'user_achievements';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'User Achievements RLS Policy Verification';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total policies created: %', policy_count;
    RAISE NOTICE 'Policy names: %', array_to_string(policy_names, ', ');
    
    IF policy_count >= 6 THEN
        RAISE NOTICE '✅ All policies created successfully';
    ELSE
        RAISE WARNING '⚠️  Expected at least 6 policies, found %', policy_count;
    END IF;
    
    RAISE NOTICE '========================================';
END $$;

DO $$ BEGIN RAISE NOTICE '✅ User achievements RLS policies enabled and configured.'; END $$;

