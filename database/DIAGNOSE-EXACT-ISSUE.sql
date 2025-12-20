-- =====================================================
-- COMPREHENSIVE DIAGNOSTIC: Find exactly why RLS is blocking
-- Run this FIRST to see what's wrong
-- =====================================================

-- 1) Check if table exists and where
SELECT 
    schemaname, 
    tablename, 
    'Table exists' as status
FROM pg_tables 
WHERE tablename = 'fighter_profiles';

-- 2) Check current GRANTs (permissions)
SELECT 
    grantee, 
    privilege_type, 
    'Current grants' as info
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name = 'fighter_profiles'
AND grantee IN ('anon', 'authenticated', 'public');

-- 3) Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE WHEN rowsecurity THEN 'RLS is ON' ELSE 'RLS is OFF' END as status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles';

-- 4) List ALL policies on fighter_profiles
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

-- 5) Check if there's actual data
SELECT COUNT(*) as total_rows FROM public.fighter_profiles;

-- 6) Test query as authenticated role
SET ROLE authenticated;
SELECT COUNT(*) as visible_as_authenticated FROM public.fighter_profiles;
SELECT user_id, name FROM public.fighter_profiles LIMIT 3;
RESET ROLE;

-- 7) Test query as anon role
SET ROLE anon;
SELECT COUNT(*) as visible_as_anon FROM public.fighter_profiles;
SELECT user_id, name FROM public.fighter_profiles LIMIT 3;
RESET ROLE;

-- 8) Check schema permissions
SELECT 
    grantee,
    privilege_type
FROM information_schema.usage_privileges 
WHERE object_schema = 'public' 
AND grantee IN ('anon', 'authenticated');

