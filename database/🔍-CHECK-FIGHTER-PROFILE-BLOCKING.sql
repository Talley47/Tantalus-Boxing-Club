-- ============================================================================
-- 🔍 DIAGNOSTIC: Check What's Blocking Fighter Profile Creation
-- ============================================================================
-- Run this to see what might be preventing profile creation
-- ============================================================================

-- Step 1: Check if RLS is enabled
SELECT 
  'RLS Status' as check_type,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles';

-- Step 2: Check INSERT policies
SELECT 
  'INSERT Policies' as check_type,
  policyname,
  cmd as command,
  roles,
  with_check as policy_condition
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'INSERT';

-- Step 3: Check if user_id column exists and is correct type
SELECT 
  'Column Check' as check_type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'fighter_profiles'
  AND column_name = 'user_id';

-- Step 4: Check for any constraints that might block inserts
SELECT 
  'Constraints' as check_type,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public'
  AND table_name = 'fighter_profiles';

-- Step 5: Summary
SELECT 
  CASE 
    WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' AND cmd = 'INSERT') = 0 
    THEN '❌ NO INSERT POLICY - This will block profile creation!'
    ELSE '✅ INSERT policy exists'
  END as insert_policy_status,
  CASE 
    WHEN (SELECT rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'fighter_profiles') = true
    THEN '✅ RLS is enabled'
    ELSE '⚠️ RLS is disabled'
  END as rls_status;

-- ============================================================================
-- NEXT STEP: If INSERT policy is missing, run:
-- database/🔧-FIX-FIGHTER-PROFILE-INSERT-RLS.sql
-- ============================================================================
