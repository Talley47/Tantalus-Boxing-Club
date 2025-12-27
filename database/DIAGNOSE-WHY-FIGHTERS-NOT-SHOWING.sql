-- ============================================================================
-- DIAGNOSE: Why Fighters Are Not Showing
-- ============================================================================
-- Run this to see exactly what's blocking access
-- ============================================================================

-- ============================================================================
-- CHECK 1: Do fighters exist in the database?
-- ============================================================================

SELECT 
    'CHECK 1: Fighter Count' as check_name,
    COUNT(*) as total_fighters,
    COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Fighters exist in database'
        ELSE '❌ NO FIGHTERS IN DATABASE'
    END as result
FROM public.fighter_profiles;

-- ============================================================================
-- CHECK 2: What RLS policies exist on fighter_profiles?
-- ============================================================================

SELECT 
    'CHECK 2: RLS Policies' as check_name,
    policyname,
    cmd as operation,
    roles,
    qual as condition,
    CASE 
        WHEN qual LIKE '%true%' OR qual IS NULL OR qual = '' THEN '✅ Permissive (should work)'
        ELSE '⚠️ Has condition - may block rows'
    END as assessment
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY cmd, policyname;

-- ============================================================================
-- CHECK 3: Is RLS enabled?
-- ============================================================================

SELECT 
    'CHECK 3: RLS Status' as check_name,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Enabled'
        ELSE '❌ RLS Disabled'
    END as rls_status,
    CASE 
        WHEN rowsecurity AND (
            SELECT COUNT(*) FROM pg_policies 
            WHERE schemaname = 'public' AND tablename = 'fighter_profiles'
        ) = 0 THEN '⚠️ RLS enabled but NO POLICIES - table is locked!'
        WHEN rowsecurity THEN '✅ RLS enabled with policies'
        ELSE '⚠️ RLS disabled - security risk'
    END as assessment
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles';

-- ============================================================================
-- CHECK 4: What permissions exist?
-- ============================================================================

SELECT 
    'CHECK 4: Permissions' as check_name,
    grantee as role,
    privilege_type,
    CASE 
        WHEN privilege_type = 'SELECT' THEN '✅ Can read'
        ELSE privilege_type
    END as assessment
FROM information_schema.role_table_grants
WHERE table_schema = 'public' 
  AND table_name = 'fighter_profiles'
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee, privilege_type;

-- ============================================================================
-- CHECK 5: Test query as authenticated user (simulate what app does)
-- ============================================================================

-- This simulates what your app does when querying
SELECT 
    'CHECK 5: Test Query' as check_name,
    COUNT(*) as rows_returned,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Query returns fighters!'
        ELSE '❌ Query returns 0 rows - RLS is blocking!'
    END as result
FROM public.fighter_profiles
LIMIT 10;

-- ============================================================================
-- CHECK 6: Check if app is using a VIEW instead of table
-- ============================================================================

SELECT 
    'CHECK 6: Views' as check_name,
    viewname,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE schemaname = 'public' 
              AND tablename = viewname
        ) THEN 'Has RLS policies'
        ELSE 'No RLS policies'
    END as policy_status
FROM pg_views
WHERE schemaname = 'public' 
  AND viewname LIKE '%fighter%'
ORDER BY viewname;

-- ============================================================================
-- CHECK 7: Check view definition (if app uses public_fighter_profiles_view)
-- ============================================================================

SELECT 
    'CHECK 7: View Definition' as check_name,
    viewname,
    pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) as view_definition
FROM pg_views
WHERE schemaname = 'public' 
  AND viewname = 'public_fighter_profiles_view';

-- ============================================================================
-- CHECK 8: Test the view (if it exists)
-- ============================================================================

SELECT 
    'CHECK 8: View Test' as check_name,
    COUNT(*) as rows_from_view,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ View returns fighters!'
        ELSE '❌ View returns 0 rows'
    END as result
FROM public.public_fighter_profiles_view
LIMIT 10;

-- ============================================================================
-- SUMMARY: What's the problem?
-- ============================================================================

DO $$
DECLARE
    fighter_count INTEGER;
    policy_count INTEGER;
    rls_enabled BOOLEAN;
    has_permissive_policy BOOLEAN;
    view_exists BOOLEAN;
    view_count INTEGER;
BEGIN
    -- Get fighter count
    SELECT COUNT(*) INTO fighter_count FROM public.fighter_profiles;
    
    -- Get policy count
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'fighter_profiles';
    
    -- Check RLS status
    SELECT rowsecurity INTO rls_enabled
    FROM pg_tables
    WHERE schemaname = 'public' AND tablename = 'fighter_profiles';
    
    -- Check for permissive policy
    SELECT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public' 
          AND tablename = 'fighter_profiles'
          AND (qual LIKE '%true%' OR qual IS NULL OR qual = '')
    ) INTO has_permissive_policy;
    
    -- Check if view exists
    SELECT EXISTS (
        SELECT 1 FROM pg_views
        WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
    ) INTO view_exists;
    
    -- Get view count
    IF view_exists THEN
        SELECT COUNT(*) INTO view_count FROM public.public_fighter_profiles_view;
    ELSE
        view_count := 0;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '                    🔍 DIAGNOSIS SUMMARY';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE 'Fighters in database: %', fighter_count;
    RAISE NOTICE 'RLS enabled: %', CASE WHEN rls_enabled THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE 'RLS policies: %', policy_count;
    RAISE NOTICE 'Has permissive policy: %', CASE WHEN has_permissive_policy THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE 'View exists: %', CASE WHEN view_exists THEN 'YES' ELSE 'NO' END;
    IF view_exists THEN
        RAISE NOTICE 'View returns: % rows', view_count;
    END IF;
    RAISE NOTICE '';
    
    -- Diagnose the problem
    IF fighter_count = 0 THEN
        RAISE WARNING '❌ PROBLEM: No fighters in database!';
        RAISE NOTICE '   Solution: Add fighters to fighter_profiles table';
    ELSIF NOT rls_enabled THEN
        RAISE WARNING '⚠️  PROBLEM: RLS is disabled - security risk!';
        RAISE NOTICE '   Solution: Enable RLS and create policies';
    ELSIF policy_count = 0 THEN
        RAISE WARNING '❌ PROBLEM: RLS enabled but NO POLICIES - table is locked!';
        RAISE NOTICE '   Solution: Create SELECT policies (run 🚨-RUN-THIS-RIGHT-NOW.sql)';
    ELSIF NOT has_permissive_policy THEN
        RAISE WARNING '❌ PROBLEM: No permissive policies - all policies have conditions!';
        RAISE NOTICE '   Solution: Create a policy with USING (true)';
    ELSIF view_exists AND view_count = 0 THEN
        RAISE WARNING '⚠️  PROBLEM: App uses view but view returns 0 rows!';
        RAISE NOTICE '   Solution: Check view definition and underlying table policies';
    ELSE
        RAISE NOTICE '✅ Configuration looks correct!';
        RAISE NOTICE '';
        RAISE NOTICE 'If fighters still not showing, check:';
        RAISE NOTICE '  1. Hard refresh app (Ctrl+Shift+R)';
        RAISE NOTICE '  2. Check browser console for errors';
        RAISE NOTICE '  3. Verify app is querying correct table/view';
        RAISE NOTICE '  4. Check if app filters out rows (e.g., admin filtering)';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- ✅ DIAGNOSIS COMPLETE
-- ============================================================================
-- Review the output above to see what's blocking access
-- ============================================================================

