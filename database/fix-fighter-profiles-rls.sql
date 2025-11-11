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

-- 1. Anyone can view fighter profiles (for rankings, matchmaking, public pages)
CREATE POLICY "Public can view fighter profiles" 
    ON public.fighter_profiles 
    FOR SELECT 
    USING (true);

-- 2. Users can view their own fighter profile
CREATE POLICY "Users can view own fighter profile" 
    ON public.fighter_profiles 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- 3. Users can insert their own fighter profile
CREATE POLICY "Users can insert own fighter profile" 
    ON public.fighter_profiles 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- 4. Users can update their own fighter profile
CREATE POLICY "Users can update own fighter profile" 
    ON public.fighter_profiles 
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- 5. Admins can manage all fighter profiles (using is_admin_user function if available)
DO $$
BEGIN
    -- Check if is_admin_user function exists (from fix-news-rls-policy.sql)
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Use is_admin_user function for admin policies
        EXECUTE 'CREATE POLICY "Admins can manage fighter profiles" 
            ON public.fighter_profiles 
            FOR ALL 
            USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Admins can manage fighter profiles" 
            ON public.fighter_profiles 
            FOR ALL 
            USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.fighter_profiles TO authenticated;
GRANT SELECT ON public.fighter_profiles TO anon;

-- Add comment
COMMENT ON POLICY "Public can view fighter profiles" ON public.fighter_profiles IS 
    'Allows anyone to view fighter profiles for rankings and public pages';

COMMENT ON POLICY "Users can view own fighter profile" ON public.fighter_profiles IS 
    'Allows users to view their own fighter profile';

COMMENT ON POLICY "Users can insert own fighter profile" ON public.fighter_profiles IS 
    'Allows users to create their own fighter profile';

COMMENT ON POLICY "Users can update own fighter profile" ON public.fighter_profiles IS 
    'Allows users to update their own fighter profile';

