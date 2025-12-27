-- ============================================================================
-- SHOW RLS POLICIES TO REMOVE
-- ============================================================================
-- This script shows policies that should be reviewed and potentially removed
-- ============================================================================

-- ============================================================================
-- PART 1: Policies with Same Name (if any exist - PostgreSQL usually prevents this)
-- ============================================================================

SELECT 
    '🔄 EXACT DUPLICATES (Same Name, Same Table)' as category,
    tablename,
    policyname,
    COUNT(*) as occurrence_count,
    'DROP POLICY "' || policyname || '" ON ' || tablename || ';' as drop_statement
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename, policyname
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC, tablename, policyname;

-- ============================================================================
-- PART 2: Tables with Multiple Policies for Same Operation
-- ============================================================================
-- These are likely redundant - you usually only need 1-2 policies per operation

WITH policy_counts AS (
    SELECT 
        tablename,
        cmd as operation,
        COUNT(*) as policy_count,
        STRING_AGG(policyname, ', ' ORDER BY policyname) as all_policy_names
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename, cmd
    HAVING COUNT(*) > 2  -- More than 2 policies for same operation
)
SELECT 
    '🔀 MULTIPLE POLICIES (Same Operation)' as category,
    pc.tablename,
    pc.operation,
    pc.policy_count,
    pc.all_policy_names,
    -- Generate DROP statements (keep the first alphabetically)
    STRING_AGG(
        'DROP POLICY "' || p.policyname || '" ON ' || p.tablename || ';',
        E'\n'
        ORDER BY p.policyname
    ) FILTER (
        WHERE p.policyname != (
            SELECT MIN(p2.policyname)
            FROM pg_policies p2
            WHERE p2.tablename = pc.tablename
              AND p2.cmd::text = pc.operation
              AND p2.schemaname = 'public'
        )
    ) as drop_statements,
    '⚠️ Review these - keep ONE policy per operation, remove the rest' as recommendation
FROM policy_counts pc
JOIN pg_policies p ON p.tablename = pc.tablename 
    AND p.cmd::text = pc.operation 
    AND p.schemaname = 'public'
GROUP BY pc.tablename, pc.operation, pc.policy_count, pc.all_policy_names
ORDER BY pc.policy_count DESC, pc.tablename, pc.operation;

-- ============================================================================
-- PART 3: All Permissive Policies (USING true) - May Be Redundant
-- ============================================================================

SELECT 
    '🔓 PERMISSIVE POLICIES (Allow All)' as category,
    tablename,
    policyname,
    cmd as operation,
    roles,
    CASE 
        WHEN COUNT(*) OVER (PARTITION BY tablename, cmd) > 1 
        THEN '⚠️ Multiple permissive policies - consider keeping only one'
        ELSE '✅ Only one permissive policy'
    END as assessment
FROM pg_policies
WHERE schemaname = 'public'
  AND (qual LIKE '%true%' OR qual IS NULL OR qual = '')
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- PART 4: Generate Simple DROP Statements
-- ============================================================================

SELECT 
    '📝 DROP STATEMENTS TO REVIEW' as section,
    STRING_AGG(
        '-- ' || tablename || '.' || policyname || ' (' || cmd || ')' || E'\n' ||
        'DROP POLICY IF EXISTS "' || policyname || '" ON ' || tablename || ';',
        E'\n\n'
        ORDER BY tablename, policyname
    ) as drop_statements
FROM pg_policies
WHERE schemaname = 'public'
  AND (tablename, policyname) IN (
      -- Include duplicates
      SELECT tablename, policyname
      FROM pg_policies
      WHERE schemaname = 'public'
      GROUP BY tablename, policyname
      HAVING COUNT(*) > 1
      
      UNION
      
      -- Include policies from tables with 3+ similar policies
      SELECT p.tablename, p.policyname
      FROM pg_policies p
      WHERE p.schemaname = 'public'
        AND (p.tablename, p.cmd) IN (
            SELECT tablename, cmd
            FROM pg_policies
            WHERE schemaname = 'public'
            GROUP BY tablename, cmd
            HAVING COUNT(*) > 2
        )
        AND p.policyname != (
            SELECT MIN(p2.policyname)
            FROM pg_policies p2
            WHERE p2.tablename = p.tablename
              AND p2.cmd = p.cmd
              AND p2.schemaname = 'public'
        )
  );

-- ============================================================================
-- PART 5: Summary Count
-- ============================================================================

SELECT 
    '📊 SUMMARY' as section,
    'Total Policies' as metric,
    COUNT(*) as count
FROM pg_policies
WHERE schemaname = 'public'

UNION ALL

SELECT 
    '📊 SUMMARY' as section,
    'Duplicate Policy Groups' as metric,
    COUNT(*) as count
FROM (
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename, policyname
    HAVING COUNT(*) > 1
) dupes

UNION ALL

SELECT 
    '📊 SUMMARY' as section,
    'Tables with 3+ Similar Policies' as metric,
    COUNT(DISTINCT tablename || '.' || cmd::text) as count
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
-- 1. PART 1: Exact duplicates (if any)
-- 2. PART 2: Tables with multiple similar policies (most important!)
-- 3. PART 3: Permissive policies that might be redundant
-- 4. PART 4: Ready-to-use DROP statements
-- 5. PART 5: Summary statistics
-- ============================================================================

