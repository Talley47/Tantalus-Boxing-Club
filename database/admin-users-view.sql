-- Admin Users View and Function
-- Creates a secure way for admins to view all users
-- Run this in Supabase SQL Editor

-- Create a function that returns all users with their data
-- This function uses SECURITY DEFINER so it can access auth.users safely
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
DECLARE
    has_is_active BOOLEAN;
BEGIN
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM auth.users u
        WHERE u.id = auth.uid()
        AND (
            u.email = 'tantalusboxingclub@gmail.com'
            OR u.email LIKE '%@admin.tantalus%'
            OR (u.raw_app_meta_data->>'role')::TEXT = 'admin'
        )
    ) AND NOT EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id = auth.uid()
        AND p.role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Access denied. Admin privileges required.';
    END IF;

    -- Check if is_active column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'is_active'
    ) INTO has_is_active;

    -- Return all users with their profiles and fighter data
    IF has_is_active THEN
        RETURN QUERY
        SELECT 
            u.id AS user_id,
            u.email,
            COALESCE(p.role, 'fighter') AS role,
            p.full_name,
            u.created_at,
            u.last_sign_in_at,
            p.banned_until,
            p.banned_reason,
            COALESCE(p.is_active, TRUE) AS is_active,
            fp.name AS fighter_name,
            fp.tier AS fighter_tier,
            fp.points AS fighter_points,
            fp.wins AS fighter_wins,
            fp.losses AS fighter_losses
        FROM auth.users u
        LEFT JOIN profiles p ON p.id = u.id
        LEFT JOIN fighter_profiles fp ON fp.user_id = u.id
        ORDER BY u.created_at DESC;
    ELSE
        RETURN QUERY
        SELECT 
            u.id AS user_id,
            u.email,
            COALESCE(p.role, 'fighter') AS role,
            p.full_name,
            u.created_at,
            u.last_sign_in_at,
            p.banned_until,
            p.banned_reason,
            TRUE AS is_active,  -- Default to active if column doesn't exist
            fp.name AS fighter_name,
            fp.tier AS fighter_tier,
            fp.points AS fighter_points,
            fp.wins AS fighter_wins,
            fp.losses AS fighter_losses
        FROM auth.users u
        LEFT JOIN profiles p ON p.id = u.id
        LEFT JOIN fighter_profiles fp ON fp.user_id = u.id
        ORDER BY u.created_at DESC;
    END IF;
END;
$$;

-- Grant execute permission to authenticated users (RLS will still check admin status)
GRANT EXECUTE ON FUNCTION get_all_users_for_admin() TO authenticated;

-- Create a view for easier querying (if function access is complex)
-- Note: Views don't support SECURITY DEFINER, so we'll use the function instead

-- Add helpful comment
COMMENT ON FUNCTION get_all_users_for_admin() IS 'Returns all users with their profiles and fighter data. Only accessible by admins.';

