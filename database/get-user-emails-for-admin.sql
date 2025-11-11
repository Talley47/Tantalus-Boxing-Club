-- Function to get user emails for admin panel
-- This allows admins to see email addresses from auth.users
-- Run this in Supabase SQL Editor

-- Create function to get user emails (SECURITY DEFINER to access auth.users)
CREATE OR REPLACE FUNCTION get_user_emails_for_admin(user_ids UUID[])
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    created_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Check if current user is admin
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        IF NOT is_admin_user() THEN
            RAISE EXCEPTION 'Access denied. Admin privileges required.';
        END IF;
    ELSE
        -- Fallback: check profiles table or email
        IF NOT EXISTS (
            SELECT 1 FROM auth.users u
            WHERE u.id = auth.uid()
            AND (
                u.email = 'tantalusboxingclub@gmail.com'
                OR u.email LIKE '%@admin.tantalus%'
                OR EXISTS (
                    SELECT 1 FROM profiles p
                    WHERE p.id = auth.uid()
                    AND p.role = 'admin'
                )
            )
        ) THEN
            RAISE EXCEPTION 'Access denied. Admin privileges required.';
        END IF;
    END IF;

    -- Return user emails
    RETURN QUERY
    SELECT 
        u.id::UUID AS user_id,
        u.email::TEXT AS email,
        u.created_at::TIMESTAMPTZ AS created_at,
        u.last_sign_in_at::TIMESTAMPTZ AS last_sign_in_at
    FROM auth.users u
    WHERE u.id = ANY(user_ids)
    ORDER BY u.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_emails_for_admin(UUID[]) TO authenticated;

COMMENT ON FUNCTION get_user_emails_for_admin(UUID[]) IS 'Returns user emails from auth.users for admin panel. Only accessible by admins.';

