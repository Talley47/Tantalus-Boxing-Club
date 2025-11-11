-- Fix get_all_users_for_admin function to handle missing columns gracefully
-- This version ensures required columns exist before creating the function
-- Run this in Supabase SQL Editor

-- First, ensure all required columns exist in the profiles table
ALTER TABLE public.profiles 
    ADD COLUMN IF NOT EXISTS banned_until TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS banned_reason TEXT,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Now create the function (all columns should exist now)
CREATE OR REPLACE FUNCTION get_all_users_for_admin()
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    role TEXT,
    full_name TEXT,
    created_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ,
    banned_until TIMESTAMPTZ,
    banned_reason TEXT,
    is_active BOOLEAN,
    fighter_name TEXT,
    fighter_tier TEXT,
    fighter_points INTEGER,
    fighter_wins INTEGER,
    fighter_losses INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Check if current user is admin
    -- Use is_admin_user function if available, otherwise check profiles table
    BEGIN
        IF EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'is_admin_user' 
            AND pronamespace = 'public'::regnamespace
        ) THEN
            IF NOT is_admin_user() THEN
                RAISE EXCEPTION 'Access denied. Admin privileges required.';
            END IF;
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM public.profiles p
                WHERE p.id = auth.uid()
                AND p.role = 'admin'
            ) THEN
                RAISE EXCEPTION 'Access denied. Admin privileges required.';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Access denied. Admin privileges required.';
    END;

    -- Query with all columns (they should exist now since we added them above)
    -- Explicitly cast all values to match the function return type
    RETURN QUERY
    SELECT 
        u.id::UUID AS user_id,
        COALESCE(u.email::TEXT, '')::TEXT AS email,
        COALESCE(p.role::TEXT, 'fighter')::TEXT AS role,
        p.full_name::TEXT AS full_name,
        u.created_at::TIMESTAMPTZ AS created_at,
        u.last_sign_in_at::TIMESTAMPTZ AS last_sign_in_at,
        p.banned_until::TIMESTAMPTZ AS banned_until,
        p.banned_reason::TEXT AS banned_reason,
        COALESCE(p.is_active::BOOLEAN, TRUE)::BOOLEAN AS is_active,
        fp.name::TEXT AS fighter_name,
        fp.tier::TEXT AS fighter_tier,
        COALESCE(fp.points::INTEGER, 0)::INTEGER AS fighter_points,
        COALESCE(fp.wins::INTEGER, 0)::INTEGER AS fighter_wins,
        COALESCE(fp.losses::INTEGER, 0)::INTEGER AS fighter_losses
    FROM auth.users u
    LEFT JOIN public.profiles p ON p.id = u.id
    LEFT JOIN public.fighter_profiles fp ON fp.user_id = u.id
    ORDER BY u.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_all_users_for_admin() TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION get_all_users_for_admin() IS 
    'Returns all users with their profiles and fighter data. Only accessible by admins. Handles missing columns gracefully.';

