-- ============================================================================
-- ⚠️ EMERGENCY TEST: Temporarily Disable RLS
-- ============================================================================
-- This script temporarily disables RLS to test if RLS is the root cause.
-- WARNING: This is for DIAGNOSTIC PURPOSES ONLY. Do NOT use in production!
-- ============================================================================
-- Run this ONLY to confirm RLS is the issue. Then run the fix script.
-- ============================================================================

-- Temporarily disable RLS on fighter_profiles
ALTER TABLE public.fighter_profiles DISABLE ROW LEVEL SECURITY;

-- Temporarily disable RLS on profiles
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Test query
SELECT 
  'Test Result (RLS Disabled)' as check_type,
  COUNT(*) as row_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ NO DATA - Issue is NOT RLS (check data exists)'
    WHEN COUNT(*) > 0 THEN '✅ DATA EXISTS - RLS was blocking! Now run the fix script.'
  END as status
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Show sample rows
SELECT 
  'Sample Rows (RLS Disabled)' as check_type,
  id,
  user_id,
  name,
  points
FROM public.fighter_profiles
WHERE user_id IS NOT NULL
ORDER BY points DESC
LIMIT 5;

-- IMPORTANT: After confirming RLS is the issue, run:
-- 1. 🚨-NUCLEAR-RLS-FIX.sql (to fix RLS properly)
-- 2. This will re-enable RLS with correct policies
