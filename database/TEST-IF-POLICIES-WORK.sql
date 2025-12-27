-- ============================================================================
-- TEST: Can You See Fighters Through RLS Policies?
-- ============================================================================
-- This simulates what your app does when querying fighters
-- Run this to see if RLS policies are working
-- ============================================================================

-- ============================================================================
-- TEST 1: Direct query (bypasses RLS - shows actual count)
-- ============================================================================

SELECT 
    'TEST 1: Direct Query (Bypasses RLS)' as test_name,
    COUNT(*) as fighter_count,
    'This shows actual fighters in database' as note
FROM public.fighter_profiles;

-- ============================================================================
-- TEST 2: Query as authenticated user (respects RLS)
-- ============================================================================

SELECT 
    'TEST 2: Query with RLS (as authenticated)' as test_name,
    COUNT(*) as fighter_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ RLS is BLOCKING - policies not working!'
        WHEN COUNT(*) > 0 THEN '✅ RLS allows access - policies working!'
        ELSE '⚠️ Unknown'
    END as result
FROM public.fighter_profiles
LIMIT 100;

-- ============================================================================
-- TEST 3: Query exactly like your app does
-- ============================================================================

SELECT 
    'TEST 3: App Query Simulation' as test_name,
    COUNT(*) as fighter_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ App will see 0 fighters!'
        WHEN COUNT(*) > 0 THEN '✅ App will see ' || COUNT(*) || ' fighters!'
        ELSE '⚠️ Unknown'
    END as result
FROM (
    SELECT *
    FROM public.fighter_profiles
    WHERE user_id IS NOT NULL
    ORDER BY points DESC
    LIMIT 30
) app_query;

-- ============================================================================
-- TEST 4: Check what policies exist
-- ============================================================================

SELECT 
    'TEST 4: Current Policies' as test_name,
    tablename,
    policyname,
    cmd as operation,
    roles,
    CASE 
        WHEN qual LIKE '%true%' OR qual IS NULL OR qual = '' THEN '✅ Permissive (should work)'
        ELSE '⚠️ Has condition: ' || LEFT(qual, 50)
    END as policy_assessment
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY cmd, policyname;

-- ============================================================================
-- TEST 5: Summary
-- ============================================================================

DO $$
DECLARE
    direct_count INTEGER;
    rls_count INTEGER;
    app_count INTEGER;
    policy_count INTEGER;
BEGIN
    -- Get direct count (bypasses RLS)
    SELECT COUNT(*) INTO direct_count FROM public.fighter_profiles;
    
    -- Get RLS count (respects policies)
    SELECT COUNT(*) INTO rls_count FROM public.fighter_profiles LIMIT 100;
    
    -- Get app query count (simulate app query)
    SELECT COUNT(*) INTO app_count 
    FROM (
        SELECT *
        FROM public.fighter_profiles 
        WHERE user_id IS NOT NULL 
        ORDER BY points DESC
        LIMIT 30
    ) app_query;
    
    -- Get policy count
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'fighter_profiles';
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '                    📊 TEST RESULTS SUMMARY';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE 'Fighters in database (direct): %', direct_count;
    RAISE NOTICE 'Fighters through RLS: %', rls_count;
    RAISE NOTICE 'Fighters through app query: %', app_count;
    RAISE NOTICE 'RLS policies: %', policy_count;
    RAISE NOTICE '';
    
    IF direct_count = 0 THEN
        RAISE WARNING '❌ PROBLEM: No fighters in database!';
    ELSIF rls_count = 0 AND direct_count > 0 THEN
        RAISE WARNING '❌ PROBLEM: RLS is BLOCKING access!';
        RAISE NOTICE '   You have % fighters but RLS returns 0', direct_count;
        RAISE NOTICE '   SOLUTION: Run 🚨-FIX-FIGHTERS-NOW-DEFINITIVE.sql';
    ELSIF rls_count > 0 AND rls_count < direct_count THEN
        RAISE WARNING '⚠️  WARNING: RLS is filtering some fighters!';
        RAISE NOTICE '   Database has % but RLS shows %', direct_count, rls_count;
        RAISE NOTICE '   Some policies may have conditions blocking rows';
    ELSIF rls_count = direct_count THEN
        RAISE NOTICE '✅ SUCCESS: RLS policies are working correctly!';
        RAISE NOTICE '   All % fighters are accessible', rls_count;
    END IF;
    
    IF policy_count = 0 THEN
        RAISE WARNING '❌ PROBLEM: No RLS policies exist!';
        RAISE NOTICE '   Table is locked - need to create policies';
    ELSIF policy_count > 4 THEN
        RAISE WARNING '⚠️  WARNING: Too many policies (% policies)', policy_count;
        RAISE NOTICE '   May have conflicting policies';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- ✅ TEST COMPLETE
-- ============================================================================
-- Compare TEST 1 (direct) vs TEST 2 (RLS):
-- - If TEST 1 = 32 but TEST 2 = 0 → RLS is blocking (run the fix!)
-- - If TEST 1 = 32 and TEST 2 = 32 → RLS is working (check app code)
-- ============================================================================

