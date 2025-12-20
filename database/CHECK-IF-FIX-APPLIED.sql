-- =====================================================
-- SIMPLE CHECK: Did you run the fix?
-- Run this FIRST to see what's currently set up
-- =====================================================

-- This will show you EXACTLY what's configured right now
SELECT 
    'CURRENT SETUP' as info,
    policyname as policy_name,
    roles::text as who_can_access,
    cmd as command_type
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- If you see 0 rows = NO POLICIES (this is the problem!)
-- If you see 1 row = Only one role can access (might be the problem!)
-- If you see 2 rows = Both policies exist (should work!)

