-- User Management Schema Updates
-- Adds fields needed for user management features (ban, status, etc.)
-- Run this in Supabase SQL Editor

-- Add ban and status fields to profiles table
DO $$ 
BEGIN
    -- Add banned_until column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'banned_until'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN banned_until TIMESTAMPTZ;
    END IF;

    -- Add banned_reason column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'banned_reason'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN banned_reason TEXT;
    END IF;

    -- Add last_sign_in_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'last_sign_in_at'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN last_sign_in_at TIMESTAMPTZ;
    END IF;

    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- Create a function to sync last_sign_in_at from auth.users
-- This will be triggered when users sign in
CREATE OR REPLACE FUNCTION sync_user_last_sign_in()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Update profiles.last_sign_in_at when auth.users.last_sign_in_at changes
    IF NEW.last_sign_in_at IS DISTINCT FROM OLD.last_sign_in_at THEN
        UPDATE public.profiles
        SET last_sign_in_at = NEW.last_sign_in_at
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

-- Create trigger to sync last_sign_in_at (if auth.users trigger is possible)
-- Note: Direct triggers on auth.users may not be allowed in all Supabase setups
-- This would need to be implemented via a database webhook or Edge Function

-- Update RLS policies for admin user management
DO $$ 
BEGIN
    -- Drop existing admin policies if they exist
    DROP POLICY IF EXISTS "Admin can view all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can update all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can delete profiles" ON public.profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create admin policies using the is_admin_user function (from fix-news-rls-policy.sql)
-- Make sure is_admin_user() exists before running this
CREATE POLICY "Admin can view all profiles" ON public.profiles
    FOR SELECT USING (is_admin_user() OR auth.uid() = id);

CREATE POLICY "Admin can update all profiles" ON public.profiles
    FOR UPDATE USING (is_admin_user() OR auth.uid() = id);

CREATE POLICY "Admin can delete profiles" ON public.profiles
    FOR DELETE USING (is_admin_user());

-- Add index for banned users lookup
CREATE INDEX IF NOT EXISTS idx_profiles_banned_until 
ON public.profiles(banned_until) 
WHERE banned_until IS NOT NULL;

-- Add index for active users lookup
CREATE INDEX IF NOT EXISTS idx_profiles_is_active 
ON public.profiles(is_active) 
WHERE is_active = TRUE;

-- Comment on columns
COMMENT ON COLUMN public.profiles.banned_until IS 'Timestamp when user ban expires. NULL means not banned. Past timestamp means ban expired.';
COMMENT ON COLUMN public.profiles.banned_reason IS 'Reason for banning the user';
COMMENT ON COLUMN public.profiles.last_sign_in_at IS 'Last time the user signed in (synced from auth.users)';
COMMENT ON COLUMN public.profiles.is_active IS 'Whether the user account is active';

