-- Check if the trigger is working and if RLS is blocking inserts
-- Run this in Supabase SQL Editor to diagnose issues

-- 1. Check if the trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created_fighter';

-- 2. Check if the function exists and has correct permissions
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'handle_new_fighter_profile_from_auth';

-- 3. Check RLS policies on fighter_profiles
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- 4. Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'fighter_profiles';

-- 5. Check recent fighter profiles to see if physical info is being saved
SELECT 
    fp.id,
    fp.user_id,
    fp.name as fighter_name,
    fp.height_feet,
    fp.height_inches,
    fp.weight,
    fp.reach,
    fp.hometown,
    fp.stance,
    fp.weight_class,
    fp.trainer,
    fp.gym,
    fp.platform,
    fp.timezone,
    fp.birthday,
    fp.created_at,
    u.email
FROM public.fighter_profiles fp
JOIN auth.users u ON fp.user_id = u.id
ORDER BY fp.created_at DESC
LIMIT 5;

-- 6. Check a specific user's metadata (replace EMAIL_HERE with actual email)
-- SELECT 
--     id,
--     email,
--     raw_user_meta_data,
--     created_at
-- FROM auth.users
-- WHERE email = 'EMAIL_HERE'
-- ORDER BY created_at DESC
-- LIMIT 1;

