-- Verify Admin User Management Functions Exist
-- Run this in Supabase SQL Editor to check if the functions are set up correctly

-- Check if functions exist
SELECT 
    proname AS function_name,
    pg_get_function_arguments(oid) AS arguments,
    CASE 
        WHEN prosecdef THEN 'SECURITY DEFINER'
        ELSE 'SECURITY INVOKER'
    END AS security_type
FROM pg_proc
WHERE proname IN (
    'update_user_role',
    'ban_user',
    'unban_user',
    'suspend_user',
    'unsuspend_user',
    'is_admin_user'
)
AND pronamespace = 'public'::regnamespace
ORDER BY proname;

-- Check if profiles table exists and has required columns
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Test is_admin_user function (should return true/false)
SELECT is_admin_user() AS current_user_is_admin;

-- Summary
DO $$
DECLARE
    func_count INTEGER;
    col_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO func_count
    FROM pg_proc
    WHERE proname IN ('update_user_role', 'ban_user', 'unban_user', 'suspend_user', 'unsuspend_user', 'is_admin_user')
    AND pronamespace = 'public'::regnamespace;
    
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'profiles'
    AND column_name IN ('id', 'email', 'role', 'banned_until', 'banned_reason', 'is_active');
    
    IF func_count = 6 THEN
        RAISE NOTICE '✅ All 6 admin functions exist!';
    ELSE
        RAISE WARNING '❌ Missing functions! Found % out of 6. Please run admin-user-management-functions.sql', func_count;
    END IF;
    
    IF col_count >= 6 THEN
        RAISE NOTICE '✅ Profiles table has required columns!';
    ELSE
        RAISE WARNING '❌ Profiles table missing columns! Found % out of 6 required. Please run admin-user-management-functions.sql', col_count;
    END IF;
END $$;

