-- ============================================================================
-- 🔍 ANALYZE YOUR EXACT QUERY AND POLICY MATCH
-- ============================================================================
-- This shows which policy matches your app's query
-- ============================================================================

-- YOUR APP'S EXACT QUERY:
-- supabase
--   .from('fighter_profiles')
--   .select('user_id, name, handle, tier, points, weight_class, wins, losses, draws, height_feet, height_inches, weight, reach, stance, hometown, birthday, trainer, gym')
--   .not('user_id', 'is', null)
--   .order('points', { ascending: false })
--   .limit(30)
--
-- TRANSLATES TO SQL:
-- SELECT user_id, name, handle, tier, points, weight_class, wins, losses, draws, 
--        height_feet, height_inches, weight, reach, stance, hometown, birthday, trainer, gym
-- FROM public.fighter_profiles
-- WHERE user_id IS NOT NULL
-- ORDER BY points DESC
-- LIMIT 30

-- ============================================================================
-- CHECK 1: What role is your app using?
-- ============================================================================
-- If user is NOT logged in → role = 'anon'
-- If user IS logged in → role = 'authenticated'
SELECT 
  'CHECK 1: Current session role' as check_name,
  current_user as current_role,
  session_user as session_role;

-- ============================================================================
-- CHECK 2: Which policies exist for fighter_profiles?
-- ============================================================================
SELECT 
  'CHECK 2: Existing policies' as check_name,
  policyname,
  roles,
  cmd as command,
  qual as using_expression,
  CASE 
    WHEN qual = 'true' THEN '✅ Matches your query (allows all rows)'
    WHEN qual LIKE '%user_id%' THEN '⚠️ May filter rows based on user_id'
    ELSE '❓ Unknown filter'
  END as policy_analysis
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
  AND (cmd = 'SELECT' OR cmd = 'ALL')
ORDER BY policyname;

-- ============================================================================
-- CHECK 3: Test your EXACT query as 'anon' role
-- ============================================================================
-- This simulates what happens when user is NOT logged in
SET ROLE anon;

SELECT 
  'CHECK 3: Test query as ANON role' as check_name,
  COUNT(*) as visible_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - RLS blocking anon role'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - ' || COUNT(*) || ' fighters visible to anon'
    ELSE '⚠️ Unknown'
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

RESET ROLE;

-- ============================================================================
-- CHECK 4: Test your EXACT query as 'authenticated' role
-- ============================================================================
-- This simulates what happens when user IS logged in
SET ROLE authenticated;

SELECT 
  'CHECK 4: Test query as AUTHENTICATED role' as check_name,
  COUNT(*) as visible_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - RLS blocking authenticated role'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - ' || COUNT(*) || ' fighters visible to authenticated'
    ELSE '⚠️ Unknown'
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

RESET ROLE;

-- ============================================================================
-- CHECK 5: Test the EXACT query with ORDER BY and LIMIT
-- ============================================================================
SELECT 
  'CHECK 5: Test EXACT app query (with ORDER BY and LIMIT)' as check_name,
  COUNT(*) as visible_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - App will see 0 fighters!'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - App will see ' || COUNT(*) || ' fighters'
    ELSE '⚠️ Unknown'
  END as result
FROM (
  SELECT user_id, name, handle, tier, points, weight_class, wins, losses, draws, 
         height_feet, height_inches, weight, reach, stance, hometown, birthday, trainer, gym
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL
  ORDER BY points DESC
  LIMIT 30
) sub;

-- ============================================================================
-- POLICY ANALYSIS
-- ============================================================================
-- Your query needs a policy that:
-- 1. Applies to 'anon' OR 'authenticated' role (depending on login status)
-- 2. Allows SELECT operation
-- 3. Has USING expression that evaluates to TRUE for rows where user_id IS NOT NULL
--
-- CURRENT POLICY (if you ran the fix):
-- CREATE POLICY "anon_read_all_fighter_profiles" 
--   ON public.fighter_profiles 
--   FOR SELECT 
--   TO anon 
--   USING (true);
--
-- CREATE POLICY "authenticated_read_all_fighter_profiles" 
--   ON public.fighter_profiles 
--   FOR SELECT 
--   TO authenticated 
--   USING (true);
--
-- ✅ These policies SHOULD match your query because:
--    - They apply to both 'anon' and 'authenticated' roles
--    - They allow SELECT
--    - USING (true) means ALL rows pass the check
--    - Your WHERE user_id IS NOT NULL filter happens AFTER RLS check
--
-- ============================================================================

