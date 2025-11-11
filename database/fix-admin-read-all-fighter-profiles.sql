-- Fix RLS policies to allow admins to read all fighter_profiles
-- This ensures the Admin Panel User Management can see all fighters
-- Run this in Supabase SQL Editor

-- Ensure RLS is enabled
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing admin read policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admin can read all fighter profiles" ON fighter_profiles;
    DROP POLICY IF EXISTS "Admins can view all fighter profiles" ON fighter_profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create admin read policy for fighter_profiles
-- Check if is_admin_user function exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Use is_admin_user function
        EXECUTE 'CREATE POLICY "Admin can read all fighter profiles" ON fighter_profiles
            FOR SELECT USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table or email
        EXECUTE 'CREATE POLICY "Admin can read all fighter profiles" ON fighter_profiles
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM profiles p
                    WHERE p.id = auth.uid()
                    AND p.role = ''admin''
                )
                OR EXISTS (
                    SELECT 1 FROM auth.users u
                    WHERE u.id = auth.uid()
                    AND (
                        u.email = ''tantalusboxingclub@gmail.com''
                        OR u.email LIKE ''%@admin.tantalus%''
                    )
                )
            )';
    END IF;
END $$;

-- Verify the policy was created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'fighter_profiles'
AND policyname LIKE '%admin%'
ORDER BY policyname;

-- Summary
DO $$
BEGIN
    RAISE NOTICE '✅ Admin read policy for fighter_profiles created!';
    RAISE NOTICE '✅ Admins can now see all fighters in User Management!';
END $$;

