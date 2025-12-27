-- ============================================================================
-- DIAGNOSE: RLS Complexity and Policy Count
-- ============================================================================
-- This script helps you understand:
-- 1. How many RLS policies you have
-- 2. If you have duplicate policies
-- 3. If any tables have too many policies
-- 4. Which policies might be redundant
-- ============================================================================

-- ============================================================================
-- PART 1: Summary Statistics
-- ============================================================================

WITH table_counts AS (
    SELECT 
        tablename,
        COUNT(*) as policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    GROUP BY tablename
),
summary_stats AS (
    SELECT 
        COUNT(DISTINCT tablename) as total_tables,
        SUM(policy_count) as total_policies,
        MAX(policy_count) as max_policies_on_one_table
    FROM table_counts
)
SELECT 
    '📊 DATABASE SUMMARY' as section,
    total_tables,
    total_policies,
    ROUND(total_policies::numeric / NULLIF(total_tables, 0), 2) as avg_policies_per_table,
    max_policies_on_one_table
FROM summary_stats;

-- ============================================================================
-- PART 2: Tables with Most Policies (Potential Over-Complexity)
-- ============================================================================

SELECT 
    '🔍 TABLES WITH MOST POLICIES' as section,
    tablename,
    COUNT(*) as policy_count,
    CASE 
        WHEN COUNT(*) > 10 THEN '⚠️ TOO MANY - Consider consolidating'
        WHEN COUNT(*) > 5 THEN '⚠️ Many policies - Review if needed'
        WHEN COUNT(*) > 2 THEN '✅ Reasonable'
        ELSE '✅ Simple'
    END as complexity_assessment,
    STRING_AGG(DISTINCT cmd::text, ', ' ORDER BY cmd::text) as operations_covered
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY policy_count DESC
LIMIT 20;

-- ============================================================================
-- PART 3: Duplicate Policies (Same Name, Same Table)
-- ============================================================================

SELECT 
    '🔄 DUPLICATE POLICIES' as section,
    tablename,
    policyname,
    COUNT(*) as duplicate_count,
    STRING_AGG(DISTINCT cmd::text, ', ') as operations,
    '⚠️ These should be dropped - duplicates!' as recommendation
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename, policyname
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, tablename, policyname;

-- ============================================================================
-- PART 4: Similar Policies (Same Table, Same Operation, Different Names)
-- ============================================================================

SELECT 
    '🔀 SIMILAR POLICIES (Potential Redundancy)' as section,
    tablename,
    cmd as operation,
    COUNT(*) as similar_policy_count,
    STRING_AGG(policyname, ', ' ORDER BY policyname) as policy_names,
    CASE 
        WHEN COUNT(*) > 3 THEN '⚠️ Too many similar policies - likely redundant'
        WHEN COUNT(*) > 2 THEN '⚠️ Multiple similar policies - review if needed'
        ELSE '✅ OK'
    END as assessment
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename, cmd
HAVING COUNT(*) > 1
ORDER BY similar_policy_count DESC, tablename, cmd;

-- ============================================================================
-- PART 5: Permissive Policies (USING (true) - Allow All)
-- ============================================================================

SELECT 
    '🔓 PERMISSIVE POLICIES (Allow All)' as section,
    tablename,
    policyname,
    cmd as operation,
    roles,
    'These allow all rows - check if this is intentional' as note
FROM pg_policies
WHERE schemaname = 'public'
  AND (qual LIKE '%true%' OR qual IS NULL OR qual = '')
ORDER BY tablename, cmd;

-- ============================================================================
-- PART 6: Tables with RLS Enabled but NO Policies (Locked Tables)
-- ============================================================================

SELECT 
    '🔒 LOCKED TABLES (RLS Enabled, No Policies)' as section,
    t.tablename,
    '⚠️ RLS enabled but NO policies - table is completely locked!' as status,
    'You need to create policies or disable RLS' as recommendation
FROM pg_tables t
WHERE t.schemaname = 'public'
  AND t.rowsecurity = true
  AND NOT EXISTS (
      SELECT 1 
      FROM pg_policies p
      WHERE p.schemaname = 'public'
        AND p.tablename = t.tablename
  )
ORDER BY t.tablename;

-- ============================================================================
-- PART 7: All Policies by Table (Complete List)
-- ============================================================================

SELECT 
    '📋 ALL POLICIES BY TABLE' as section,
    tablename,
    policyname,
    cmd as operation,
    roles,
    CASE 
        WHEN qual LIKE '%true%' OR qual IS NULL OR qual = '' THEN 'Permissive (Allow All)'
        WHEN qual LIKE '%auth.uid()%' THEN 'User-Specific'
        WHEN qual LIKE '%role%' THEN 'Role-Based'
        ELSE 'Custom Condition'
    END as policy_type,
    LEFT(qual, 100) as condition_preview
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- PART 8: Recommendations Summary
-- ============================================================================

DO $$
DECLARE
    total_policies INTEGER;
    total_tables INTEGER;
    duplicate_count INTEGER;
    similar_count INTEGER;
    locked_tables INTEGER;
    avg_policies_per_table NUMERIC;
BEGIN
    -- Get counts
    SELECT COUNT(*) INTO total_policies
    FROM pg_policies
    WHERE schemaname = 'public';
    
    SELECT COUNT(DISTINCT tablename) INTO total_tables
    FROM pg_policies
    WHERE schemaname = 'public';
    
    SELECT COUNT(*) INTO duplicate_count
    FROM (
        SELECT tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
        GROUP BY tablename, policyname
        HAVING COUNT(*) > 1
    ) dupes;
    
    SELECT COUNT(*) INTO similar_count
    FROM (
        SELECT tablename, cmd
        FROM pg_policies
        WHERE schemaname = 'public'
        GROUP BY tablename, cmd
        HAVING COUNT(*) > 2
    ) similar_policies;
    
    SELECT COUNT(*) INTO locked_tables
    FROM pg_tables t
    WHERE t.schemaname = 'public'
      AND t.rowsecurity = true
      AND NOT EXISTS (
          SELECT 1 FROM pg_policies p
          WHERE p.schemaname = 'public' AND p.tablename = t.tablename
      );
    
    SELECT ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT tablename), 0), 2) 
    INTO avg_policies_per_table
    FROM pg_policies
    WHERE schemaname = 'public';
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '                    📊 RLS COMPLEXITY ANALYSIS SUMMARY';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE 'Total Tables with Policies: %', total_tables;
    RAISE NOTICE 'Total RLS Policies: %', total_policies;
    RAISE NOTICE 'Average Policies per Table: %', avg_policies_per_table;
    RAISE NOTICE '';
    RAISE NOTICE 'Duplicate Policies (same name): %', duplicate_count;
    RAISE NOTICE 'Tables with 3+ Similar Policies: %', similar_count;
    RAISE NOTICE 'Locked Tables (RLS enabled, no policies): %', locked_tables;
    RAISE NOTICE '';
    
    -- Recommendations
    IF total_policies > 200 THEN
        RAISE WARNING '⚠️  You have % policies - this is A LOT!', total_policies;
        RAISE NOTICE '   Consider consolidating policies or reviewing if all are needed.';
    ELSIF total_policies > 100 THEN
        RAISE NOTICE 'ℹ️  You have % policies - this is moderate complexity.', total_policies;
        RAISE NOTICE '   Review the tables with most policies above.';
    ELSE
        RAISE NOTICE '✅ You have % policies - this is reasonable.', total_policies;
    END IF;
    
    IF avg_policies_per_table > 5 THEN
        RAISE WARNING '⚠️  Average of % policies per table - consider simplifying.', avg_policies_per_table;
    END IF;
    
    IF duplicate_count > 0 THEN
        RAISE WARNING '⚠️  You have % duplicate policies - these should be removed!', duplicate_count;
        RAISE NOTICE '   Check PART 3 above for details.';
    END IF;
    
    IF similar_count > 0 THEN
        RAISE WARNING '⚠️  % tables have 3+ similar policies - review for redundancy.', similar_count;
        RAISE NOTICE '   Check PART 4 above for details.';
    END IF;
    
    IF locked_tables > 0 THEN
        RAISE WARNING '⚠️  % tables are locked (RLS enabled, no policies)!', locked_tables;
        RAISE NOTICE '   Check PART 6 above - these tables need policies or RLS disabled.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '';
    RAISE NOTICE '💡 RECOMMENDATIONS:';
    RAISE NOTICE '';
    
    IF duplicate_count > 0 THEN
        RAISE NOTICE '   1. Remove duplicate policies (see PART 3)';
    END IF;
    
    IF similar_count > 0 THEN
        RAISE NOTICE '   2. Review and consolidate similar policies (see PART 4)';
    END IF;
    
    IF locked_tables > 0 THEN
        RAISE NOTICE '   3. Fix locked tables - add policies or disable RLS (see PART 6)';
    END IF;
    
    IF avg_policies_per_table > 5 THEN
        RAISE NOTICE '   4. Consider simplifying policies on tables with 5+ policies';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '   Best Practice: 2-4 policies per table is ideal';
    RAISE NOTICE '   (SELECT for authenticated, SELECT for anon, INSERT/UPDATE for own data)';
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- ✅ DIAGNOSTIC COMPLETE
-- ============================================================================
-- Review the output above to understand your RLS complexity
-- ============================================================================

