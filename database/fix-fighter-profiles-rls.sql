-- Fix RLS Policies for fighter_profiles to prevent 406 errors
-- This ensures proper access control without causing API errors
-- Run this in Supabase SQL Editor

-- Drop existing conflicting policies first
DO $$ 
DECLARE
    policy_rec RECORD;
BEGIN
    -- Drop all existing policies on fighter_profiles
    FOR policy_rec IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'fighter_profiles'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        -- Continue even if there's an error
        NULL;
END $$;

-- Create comprehensive RLS policies for fighter_profiles

-- 1. Public can view fighter profiles (for rankings, matchmaking, public pages)
-- Restricted to anon only to avoid multiple permissive policies for authenticated role
DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
CREATE POLICY "Public can view all fighter profiles" 
    ON public.fighter_profiles 
    FOR SELECT
    TO anon
    USING (true);

-- 2. Combined SELECT policy: Users can view their own fighter profile OR admins can view all
-- This avoids multiple permissive policies for the same role and action
DROP POLICY IF EXISTS "Users can view own fighter profile" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Users and admins can view fighter profiles" ON public.fighter_profiles;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Users and admins can view fighter profiles" 
            ON public.fighter_profiles 
            FOR SELECT
            TO authenticated
            USING (
                (select auth.uid()) = user_id 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Users and admins can view fighter profiles" 
            ON public.fighter_profiles 
            FOR SELECT
            TO authenticated
            USING (
                (select auth.uid()) = user_id 
                OR EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- 3. Combined INSERT policy: Users can insert their own fighter profile OR admins can insert any
-- This avoids multiple permissive policies for the same role and action
DROP POLICY IF EXISTS "Users insert own profile" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Users can insert own fighter profile" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Users and admins can insert fighter profiles" ON public.fighter_profiles;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Users and admins can insert fighter profiles" 
            ON public.fighter_profiles 
            FOR INSERT
            TO authenticated
            WITH CHECK (
                (select auth.uid()) = user_id 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Users and admins can insert fighter profiles" 
            ON public.fighter_profiles 
            FOR INSERT
            TO authenticated
            WITH CHECK (
                (select auth.uid()) = user_id 
                OR EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- 4. Combined UPDATE policy: Users can update their own fighter profile OR admins can update any
-- This avoids multiple permissive policies for the same role and action
DROP POLICY IF EXISTS "Users can update own fighter profile" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Users and admins can update fighter profiles" ON public.fighter_profiles;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Users and admins can update fighter profiles" 
            ON public.fighter_profiles 
            FOR UPDATE
            TO authenticated
            USING (
                (select auth.uid()) = user_id 
                OR is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Users and admins can update fighter profiles" 
            ON public.fighter_profiles 
            FOR UPDATE
            TO authenticated
            USING (
                (select auth.uid()) = user_id 
                OR EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- 5. Admins can delete fighter profiles (UPDATE is handled by combined policy above, SELECT and INSERT are also handled by combined policies)
-- Drop old policy names first
DROP POLICY IF EXISTS "Admins can manage fighter profiles" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Admins can view fighter profiles" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Admins can update fighter profiles" ON public.fighter_profiles;
DROP POLICY IF EXISTS "Admins can delete fighter profiles" ON public.fighter_profiles;

DO $$
BEGIN
    -- Check if is_admin_user function exists (from fix-news-rls-policy.sql)
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Create admin policy for DELETE only (UPDATE, SELECT, and INSERT are handled by combined policies above)
        EXECUTE 'CREATE POLICY "Admins can delete fighter profiles" 
            ON public.fighter_profiles 
            FOR DELETE TO authenticated
            USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Admins can delete fighter profiles" 
            ON public.fighter_profiles 
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = (select auth.uid()) 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.fighter_profiles TO authenticated;
GRANT SELECT ON public.fighter_profiles TO anon;

-- Add comment
COMMENT ON POLICY "Public can view all fighter profiles" ON public.fighter_profiles IS 
    'Allows anyone to view fighter profiles for rankings and public pages';

COMMENT ON POLICY "Users and admins can view fighter profiles" ON public.fighter_profiles IS 
    'Allows users to view their own fighter profile or admins to view all fighter profiles. Combined policy to avoid multiple permissive policies.';

COMMENT ON POLICY "Users and admins can insert fighter profiles" ON public.fighter_profiles IS 
    'Allows users to create their own fighter profile or admins to create any fighter profile. Combined policy to avoid multiple permissive policies.';

COMMENT ON POLICY "Users and admins can update fighter profiles" ON public.fighter_profiles IS 
    'Allows users to update their own fighter profile or admins to update any fighter profile. Combined policy to avoid multiple permissive policies.';

