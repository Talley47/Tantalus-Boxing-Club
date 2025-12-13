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

-- Policy 1: Users can view their own achievements
CREATE POLICY "Users can view their own achievements" ON user_achievements
    FOR SELECT
    USING (user_id = (select auth.uid()));

-- Policy 2: Users can view other users' achievements (for public profiles/leaderboards)
-- This allows viewing achievements for public display
CREATE POLICY "Users can view public achievements" ON user_achievements
    FOR SELECT
    USING (auth.role() = 'authenticated' OR auth.role() = 'anon');

-- Policy 3: Admins can view all achievements
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can view all achievements" ON user_achievements
            FOR SELECT USING (is_admin_user())';
        RAISE NOTICE 'Created admin view policy using is_admin_user()';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Admins can view all achievements" ON user_achievements
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
        RAISE NOTICE 'Created admin view policy using profiles table';
    END IF;
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Admin view policy already exists';
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
COMMENT ON POLICY "Users can view their own achievements" ON user_achievements IS 
    'Allows users to view their own unlocked achievements';

COMMENT ON POLICY "Users can view public achievements" ON user_achievements IS 
    'Allows authenticated and anonymous users to view achievements for public profiles/leaderboards';

COMMENT ON POLICY "Admins can view all achievements" ON user_achievements IS 
    'Allows admins to view all user achievements';

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

