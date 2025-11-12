-- ============================================
-- IDENTIFY POLICIES TO DELETE
-- This script finds duplicate, conflicting, or unnecessary RLS policies
-- ============================================

-- ============================================
-- 1. FIND DUPLICATE POLICIES (same name, multiple commands)
-- ============================================
SELECT 
    'DUPLICATE POLICIES TO DELETE' as action,
    tablename,
    policyname,
    cmd as command,
    'Keep only one of these duplicates' as recommendation
FROM pg_policies
WHERE schemaname = 'public'
AND (tablename, policyname) IN (
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename, policyname
    HAVING COUNT(*) > 1
)
ORDER BY tablename, policyname, cmd;

-- ============================================
-- 2. FIND CONFLICTING POLICIES (same table, same command, different names)
-- ============================================
SELECT 
    'CONFLICTING POLICIES' as action,
    tablename,
    cmd as command,
    STRING_AGG(policyname, ', ') as policy_names,
    'Consider consolidating into one policy' as recommendation
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename, cmd
HAVING COUNT(DISTINCT policyname) > 1
AND cmd IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
ORDER BY tablename, cmd;

-- ============================================
-- 3. FIND FIGHTER_PROFILES POLICIES (check for conflicts)
-- ============================================
SELECT 
    'FIGHTER_PROFILES POLICIES' as action,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%true%' OR qual IS NULL THEN 'Public/Open'
        WHEN qual LIKE '%auth.uid()%' THEN 'User-specific'
        WHEN qual LIKE '%admin%' THEN 'Admin-only'
        ELSE 'Other'
    END as policy_type,
    CASE 
        WHEN cmd = 'SELECT' AND qual LIKE '%true%' AND EXISTS (
            SELECT 1 FROM pg_policies p2 
            WHERE p2.tablename = 'fighter_profiles' 
            AND p2.cmd = 'SELECT' 
            AND p2.policyname != pg_policies.policyname
        ) THEN '⚠️ Multiple SELECT policies - may conflict'
        ELSE 'OK'
    END as status
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'fighter_profiles'
ORDER BY cmd, policyname;

-- ============================================
-- 4. FIND NOTIFICATIONS POLICIES (check for conflicts)
-- ============================================
SELECT 
    'NOTIFICATIONS POLICIES' as action,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN 'User-specific'
        WHEN qual LIKE '%true%' OR qual IS NULL THEN 'Public/Open'
        WHEN qual LIKE '%admin%' THEN 'Admin-only'
        ELSE 'Other'
    END as policy_type,
    CASE 
        WHEN cmd = 'INSERT' AND qual LIKE '%authenticated%' AND EXISTS (
            SELECT 1 FROM pg_policies p2 
            WHERE p2.tablename = 'notifications' 
            AND p2.cmd = 'INSERT' 
            AND p2.policyname != pg_policies.policyname
        ) THEN '⚠️ Multiple INSERT policies - may conflict'
        ELSE 'OK'
    END as status
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'notifications'
ORDER BY cmd, policyname;

-- ============================================
-- 5. FIND POLICIES THAT ALWAYS BLOCK (qual = false)
-- ============================================
SELECT 
    'BLOCKING POLICIES TO DELETE' as action,
    tablename,
    policyname,
    cmd,
    'This policy always blocks access - should be deleted' as recommendation
FROM pg_policies
WHERE schemaname = 'public'
AND qual LIKE '%false%';

-- ============================================
-- 6. FIND OLD/LEGACY POLICY NAMES (common patterns)
-- ============================================
SELECT 
    'POTENTIALLY OLD POLICIES' as action,
    tablename,
    policyname,
    cmd,
    'May be legacy - verify if still needed' as recommendation
FROM pg_policies
WHERE schemaname = 'public'
AND (
    policyname LIKE '%old%'
    OR policyname LIKE '%legacy%'
    OR policyname LIKE '%backup%'
    OR policyname LIKE '%temp%'
    OR policyname LIKE '%test%'
)
ORDER BY tablename, policyname;

-- ============================================
-- 7. RECOMMENDED POLICIES FOR FIGHTER_PROFILES
-- ============================================
SELECT 
    'RECOMMENDED POLICIES' as action,
    'fighter_profiles' as tablename,
    'Public can view all fighter profiles' as recommended_policy,
    'SELECT' as command,
    'USING (true)' as using_expression,
    'Allows public read access for rankings, matchmaking, etc.' as reason
UNION ALL
SELECT 
    'RECOMMENDED POLICIES',
    'fighter_profiles',
    'Users can update own fighter profile',
    'UPDATE',
    'USING (auth.uid() = user_id)',
    'Allows users to update their own profile'
UNION ALL
SELECT 
    'RECOMMENDED POLICIES',
    'fighter_profiles',
    'Users can insert own fighter profile',
    'INSERT',
    'WITH CHECK (auth.uid() = user_id)',
    'Allows users to create their own profile'
UNION ALL
SELECT 
    'RECOMMENDED POLICIES',
    'fighter_profiles',
    'Admins can manage fighter profiles',
    'ALL',
    'USING (is_admin_user() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = ''admin''))',
    'Allows admins full access';

-- ============================================
-- 8. GENERATE DELETE STATEMENTS FOR DUPLICATES
-- ============================================
SELECT 
    'DELETE STATEMENT' as action,
    format('DROP POLICY IF EXISTS %L ON %I;', policyname, tablename) as sql_statement,
    'Run this to delete duplicate policy' as note
FROM pg_policies
WHERE schemaname = 'public'
AND (tablename, policyname) IN (
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename, policyname
    HAVING COUNT(*) > 1
)
ORDER BY tablename, policyname, cmd;

-- ============================================
-- 9. SUMMARY
-- ============================================
DO $$
DECLARE
    duplicate_count INTEGER;
    blocking_count INTEGER;
    conflicting_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO duplicate_count
    FROM (
        SELECT tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
        GROUP BY tablename, policyname
        HAVING COUNT(*) > 1
    ) duplicates;
    
    SELECT COUNT(*) INTO blocking_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND qual LIKE '%false%';
    
    SELECT COUNT(*) INTO conflicting_count
    FROM (
        SELECT tablename, cmd
        FROM pg_policies
        WHERE schemaname = 'public'
        GROUP BY tablename, cmd
        HAVING COUNT(DISTINCT policyname) > 1
    ) conflicts;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'POLICY CLEANUP SUMMARY';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Duplicate policies found: %', duplicate_count;
    RAISE NOTICE 'Blocking policies found: %', blocking_count;
    RAISE NOTICE 'Conflicting policies found: %', conflicting_count;
    RAISE NOTICE '';
    
    IF duplicate_count > 0 OR blocking_count > 0 OR conflicting_count > 0 THEN
        RAISE WARNING '⚠️ You have policies that should be reviewed/deleted.';
        RAISE NOTICE '   Check the queries above for specific recommendations.';
    ELSE
        RAISE NOTICE '✅ No obvious duplicate or problematic policies found.';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;





