-- =====================================================
-- COMPREHENSIVE RLS DIAGNOSTIC SCRIPT
-- Run this in Supabase SQL Editor to find the issue
-- =====================================================

-- 1. Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles';

-- 2. List ALL policies on fighter_profiles
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

-- 3. Check if there's data in the table (bypassing RLS)
SET ROLE postgres;
SELECT COUNT(*) as total_fighters FROM fighter_profiles;
SELECT COUNT(*) as fighters_with_user_id FROM fighter_profiles WHERE user_id IS NOT NULL;
RESET ROLE;

-- 4. Test query as authenticated user (simulate what your app does)
-- This will show what an authenticated user can see
SET ROLE authenticated;
SELECT COUNT(*) as visible_fighters FROM fighter_profiles;
SELECT user_id, name, handle FROM fighter_profiles LIMIT 5;
RESET ROLE;

-- 5. Check profiles table policies (needed for admin filtering)
SELECT 
    tablename,
    policyname,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'profiles';

-- 6. If RLS is enabled but no policies match, we need to fix it
-- Check if there are any restrictive policies
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'fighter_profiles'
AND (qual IS NOT NULL OR with_check IS NOT NULL);

