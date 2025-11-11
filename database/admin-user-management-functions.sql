-- Admin User Management Functions
-- Functions for admins to manage user roles and ban status
-- Run this in Supabase SQL Editor

-- 1. Ensure profiles table exists with all required columns
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    role TEXT DEFAULT 'fighter',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    banned_until TIMESTAMPTZ,
    banned_reason TEXT,
    last_sign_in_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

-- Add missing columns if they don't exist
DO $$
BEGIN
    ALTER TABLE public.profiles
        ADD COLUMN IF NOT EXISTS email TEXT,
        ADD COLUMN IF NOT EXISTS full_name TEXT,
        ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'fighter',
        ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
        ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
        ADD COLUMN IF NOT EXISTS banned_until TIMESTAMPTZ,
        ADD COLUMN IF NOT EXISTS banned_reason TEXT,
        ADD COLUMN IF NOT EXISTS last_sign_in_at TIMESTAMPTZ,
        ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
END $$;

-- 2. Function to check if current user is admin
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Check if user is admin via profiles table
    IF EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role = 'admin'
    ) THEN
        RETURN TRUE;
    END IF;
    
    -- Check if user is admin via email
    IF EXISTS (
        SELECT 1 FROM auth.users u
        WHERE u.id = auth.uid()
        AND (
            u.email = 'tantalusboxingclub@gmail.com'
            OR u.email LIKE '%@admin.tantalus%'
            OR (u.raw_app_meta_data->>'role')::TEXT = 'admin'
        )
    ) THEN
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$;

-- 3. Function to update user role
CREATE OR REPLACE FUNCTION update_user_role(
    target_user_id UUID,
    new_role TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    result JSON;
BEGIN
    -- Check if current user is admin
    IF NOT is_admin_user() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Access denied. Admin privileges required.'
        );
    END IF;
    
    -- Validate role
    IF new_role NOT IN ('admin', 'fighter', 'user') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid role. Must be admin, fighter, or user.'
        );
    END IF;
    
    -- Ensure profile exists
    INSERT INTO public.profiles (id, email, role, updated_at)
    SELECT 
        u.id,
        u.email,
        new_role,
        NOW()
    FROM auth.users u
    WHERE u.id = target_user_id
    ON CONFLICT (id) 
    DO UPDATE SET 
        role = new_role,
        updated_at = NOW();
    
    -- Also update auth.users metadata if possible
    -- Note: This requires admin API, so we'll just update profiles
    
    RETURN json_build_object(
        'success', true,
        'message', 'User role updated successfully'
    );
END;
$$;

-- 4. Function to ban a user
CREATE OR REPLACE FUNCTION ban_user(
    target_user_id UUID,
    duration_days INTEGER DEFAULT NULL,
    ban_reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    banned_until_date TIMESTAMPTZ;
BEGIN
    -- Check if current user is admin
    IF NOT is_admin_user() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Access denied. Admin privileges required.'
        );
    END IF;
    
    -- Calculate banned_until date
    IF duration_days IS NULL OR duration_days <= 0 THEN
        banned_until_date := NULL; -- Permanent ban
    ELSE
        banned_until_date := NOW() + (duration_days || ' days')::INTERVAL;
    END IF;
    
    -- Ensure profile exists and update ban status
    INSERT INTO public.profiles (id, email, banned_until, banned_reason, updated_at)
    SELECT 
        u.id,
        u.email,
        banned_until_date,
        ban_reason,
        NOW()
    FROM auth.users u
    WHERE u.id = target_user_id
    ON CONFLICT (id) 
    DO UPDATE SET 
        banned_until = banned_until_date,
        banned_reason = ban_reason,
        updated_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'message', 'User banned successfully',
        'banned_until', banned_until_date
    );
END;
$$;

-- 5. Function to unban a user
CREATE OR REPLACE FUNCTION unban_user(
    target_user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Check if current user is admin
    IF NOT is_admin_user() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Access denied. Admin privileges required.'
        );
    END IF;
    
    -- Update profile to remove ban
    UPDATE public.profiles
    SET 
        banned_until = NULL,
        banned_reason = NULL,
        updated_at = NOW()
    WHERE id = target_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'User unbanned successfully'
    );
END;
$$;

-- 6. Function to suspend a user (set is_active = false)
CREATE OR REPLACE FUNCTION suspend_user(
    target_user_id UUID,
    reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Check if current user is admin
    IF NOT is_admin_user() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Access denied. Admin privileges required.'
        );
    END IF;
    
    -- Ensure profile exists and update suspension status
    INSERT INTO public.profiles (id, email, is_active, updated_at)
    SELECT 
        u.id,
        u.email,
        FALSE,
        NOW()
    FROM auth.users u
    WHERE u.id = target_user_id
    ON CONFLICT (id) 
    DO UPDATE SET 
        is_active = FALSE,
        updated_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'message', 'User suspended successfully'
    );
END;
$$;

-- 7. Function to unsuspend a user (set is_active = true)
CREATE OR REPLACE FUNCTION unsuspend_user(
    target_user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Check if current user is admin
    IF NOT is_admin_user() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Access denied. Admin privileges required.'
        );
    END IF;
    
    -- Update profile to remove suspension
    UPDATE public.profiles
    SET 
        is_active = TRUE,
        updated_at = NOW()
    WHERE id = target_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'User unsuspended successfully'
    );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION update_user_role(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION ban_user(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION unban_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION suspend_user(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION unsuspend_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin_user() TO authenticated;

-- Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for profiles
-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Admin can manage all profiles
CREATE POLICY "Admins can manage all profiles" ON public.profiles
    FOR ALL
    USING (is_admin_user())
    WITH CHECK (is_admin_user());

-- Users can read their own profile
CREATE POLICY "Users can read their own profile" ON public.profiles
    FOR SELECT
    USING (id = auth.uid());

-- Summary
DO $$
BEGIN
    RAISE NOTICE '✅ Admin user management functions created!';
    RAISE NOTICE '✅ Functions available:';
    RAISE NOTICE '   - update_user_role(user_id, role)';
    RAISE NOTICE '   - ban_user(user_id, duration_days, reason)';
    RAISE NOTICE '   - unban_user(user_id)';
    RAISE NOTICE '   - suspend_user(user_id, reason)';
    RAISE NOTICE '   - unsuspend_user(user_id)';
END $$;

