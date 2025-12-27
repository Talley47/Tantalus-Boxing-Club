-- ============================================================================
-- LIST RLS POLICIES TO REMOVE
-- ============================================================================
-- This script identifies policies that should be removed:
-- 1. Duplicate policies (same name, same table)
-- 2. Redundant policies (same table, same operation, multiple names)
-- 3. Policies that can be consolidated
-- ============================================================================

-- ============================================================================
-- PART 1: DUPLICATE POLICIES (Safe to Remove - Keep Only One)
-- ============================================================================

SELECT 
    '🔄 DUPLICATE POLICIES TO REMOVE' as section,
    tablename,
    policyname,
    cmd as operation,
    COUNT(*) as duplicate_count,
    'DROP POLICY "' || policyname || '" ON ' || tablename || ';' as drop_statement,
    '⚠️ Remove all but one - these are exact duplicates!' as recommendation
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename, policyname, cmd
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, tablename, policyname;

-- ============================================================================
-- PART 2: MULTIPLE SIMILAR POLICIES (Same Table, Same Operation)
-- ============================================================================
-- These have the same operation (SELECT, INSERT, etc.) on the same table
-- but different names - likely redundant

WITH similar_policies AS (
    SELECT 
        tablename,
        cmd as operation,
        COUNT(*) as policy_count,
        STRING_AGG(policyname, ', ' ORDER BY policyname) as policy_names,
        ARRAY_AGG(policyname ORDER BY policyname) as policy_name_array
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename, cmd
    HAVING COUNT(*) > 2  -- More than 2 policies for same operation
)
SELECT 
    '🔀 MULTIPLE SIMILAR POLICIES (Review & Consolidate)' as section,
    sp.tablename,
    sp.operation,
    sp.policy_count,
    sp.policy_names,
    -- Show the DROP statements (keep the first one, remove the rest)
    STRING_AGG(
        'DROP POLICY "' || p.policyname || '" ON ' || p.tablename || ';',
        E'\n'
        ORDER BY p.policyname
    ) as drop_statements,
    '⚠️ Keep ONE policy, remove the others. Review conditions first!' as recommendation
FROM similar_policies sp
JOIN pg_policies p ON p.tablename = sp.tablename 
    AND p.cmd::text = sp.operation 
    AND p.schemaname = 'public'
WHERE p.policyname != (
    -- Keep the first alphabetically, remove the rest
    SELECT MIN(p2.policyname)
    FROM pg_policies p2
    WHERE p2.tablename = sp.tablename
      AND p2.cmd::text = sp.operation
      AND p2.schemaname = 'public'
)
GROUP BY sp.tablename, sp.operation, sp.policy_count, sp.policy_names
ORDER BY sp.policy_count DESC, sp.tablename, sp.operation;

-- ============================================================================
-- PART 3: GENERATE DROP STATEMENTS FOR DUPLICATES
-- ============================================================================

SELECT 
    '📝 DROP STATEMENTS FOR DUPLICATES' as section,
    '-- Remove duplicate policies (keep only one of each)' as comment,
    STRING_AGG(
        'DROP POLICY IF EXISTS "' || policyname || '" ON ' || tablename || ';',
        E'\n'
        ORDER BY tablename, policyname
    ) as drop_statements
FROM (
    SELECT DISTINCT
        tablename,
        policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (tablename, policyname) IN (
          SELECT tablename, policyname
          FROM pg_policies
          WHERE schemaname = 'public'
          GROUP BY tablename, policyname
          HAVING COUNT(*) > 1
      )
) duplicates;

-- ============================================================================
-- PART 4: POLICIES WITH PERMISSIVE CONDITIONS (USING true)
-- ============================================================================
-- These allow all rows - check if you have multiple permissive policies
-- that can be consolidated

SELECT 
    '🔓 PERMISSIVE POLICIES (May Be Redundant)' as section,
    tablename,
    policyname,
    cmd as operation,
    roles,
    qual as condition,
    CASE 
        WHEN COUNT(*) OVER (PARTITION BY tablename, cmd) > 1 
        THEN '⚠️ Multiple permissive policies - consider consolidating'
        ELSE '✅ Only one permissive policy - OK'
    END as assessment
FROM pg_policies
WHERE schemaname = 'public'
  AND (qual LIKE '%true%' OR qual IS NULL OR qual = '')
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- PART 5: COMPLETE LIST OF ALL POLICIES (For Reference)
-- ============================================================================

SELECT 
    '📋 ALL POLICIES (For Reference)' as section,
    tablename,
    policyname,
    cmd as operation,
    roles,
    CASE 
        WHEN qual LIKE '%true%' OR qual IS NULL OR qual = '' THEN 'Permissive (Allow All)'
        WHEN qual LIKE '%auth.uid()%' THEN 'User-Specific'
        WHEN qual LIKE '%role%' THEN 'Role-Based'
        ELSE 'Custom Condition'
    END as policy_type
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- PART 6: SAFE REMOVAL SCRIPT (Only Duplicates)
-- ============================================================================
-- This generates a script to safely remove ONLY duplicate policies

DO $$
DECLARE
    duplicate_record RECORD;
    drop_count INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '                    🗑️  GENERATING DROP STATEMENTS FOR DUPLICATES';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    
    -- Find duplicates and generate drop statements
    FOR duplicate_record IN
        SELECT DISTINCT
            tablename,
            policyname,
            COUNT(*) as duplicate_count
        FROM pg_policies
        WHERE schemaname = 'public'
        GROUP BY tablename, policyname
        HAVING COUNT(*) > 1
        ORDER BY tablename, policyname
    LOOP
        -- Keep one, drop the rest
        -- We'll drop all but keep the first one we encounter
        RAISE NOTICE 'DROP POLICY IF EXISTS "%" ON %; -- (duplicate, keeping one)', 
            duplicate_record.policyname, 
            duplicate_record.tablename;
        drop_count := drop_count + 1;
    END LOOP;
    
    IF drop_count = 0 THEN
        RAISE NOTICE '✅ No duplicate policies found!';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
        RAISE NOTICE 'Found % duplicate policy group(s) to remove', drop_count;
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  IMPORTANT: Review the DROP statements above before executing!';
        RAISE NOTICE '   Each duplicate group will keep ONE policy and remove the rest.';
        RAISE NOTICE '';
        RAISE NOTICE 'To execute, copy the DROP statements and run them separately.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- PART 7: SUMMARY OF WHAT TO REMOVE
-- ============================================================================

SELECT 
    '📊 REMOVAL SUMMARY' as section,
    'Duplicate Policies' as category,
    COUNT(DISTINCT tablename || '.' || policyname) as count_to_remove,
    'Safe to remove - exact duplicates' as safety_level
FROM pg_policies
WHERE schemaname = 'public'
  AND (tablename, policyname) IN (
      SELECT tablename, policyname
      FROM pg_policies
      WHERE schemaname = 'public'
      GROUP BY tablename, policyname
      HAVING COUNT(*) > 1
  )

UNION ALL

SELECT 
    '📊 REMOVAL SUMMARY' as section,
    'Tables with 3+ Similar Policies' as category,
    COUNT(DISTINCT tablename || '.' || cmd::text) as count_to_review,
    'Review needed - may be redundant' as safety_level
FROM pg_policies
WHERE schemaname = 'public'
  AND (tablename, cmd) IN (
      SELECT tablename, cmd
      FROM pg_policies
      WHERE schemaname = 'public'
      GROUP BY tablename, cmd
      HAVING COUNT(*) > 2
  );

-- ============================================================================
-- ✅ ANALYSIS COMPLETE
-- ============================================================================
-- Review the output above:
-- 1. PART 1: Shows duplicate policies (safe to remove)
-- 2. PART 2: Shows similar policies (review before removing)
-- 3. PART 3: Generates DROP statements for duplicates
-- 4. PART 6: Prints DROP statements in the output
-- 5. PART 7: Summary of what can be removed
-- ============================================================================

