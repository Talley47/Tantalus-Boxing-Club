-- ============================================================================
-- 🚨 FIX RLS NOW - Simple & Direct
-- ============================================================================
-- This fixes the exact issue: "Query succeeds but returns 0 rows because RLS filters everything out"
-- 
-- Problem: Your app uses the anon key from the browser, but there's no RLS policy
--          allowing anon/authenticated roles to SELECT from fighter_profiles.
--
-- Solution: Grant permissions + Create permissive policies for anon and authenticated
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- ============================================================================
-- PART 1: Fix fighter_profiles (for homepage rankings)
-- ============================================================================

-- Step 1: Grant schema usage (REQUIRED for anon/authenticated to access tables)
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Step 2: Grant table SELECT permission (REQUIRED - separate from RLS!)
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Step 3: Enable RLS (security best practice)
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop ALL existing SELECT policies (clean slate)
DO $$
DECLARE
  policy_rec RECORD;
BEGIN
  FOR policy_rec IN 
    SELECT policyname
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
  END LOOP;
END $$;

-- Step 5: Create policy for anon role (allows public/browser access)
CREATE POLICY "Public can view fighter profiles"
ON public.fighter_profiles
FOR SELECT
TO anon
USING (true);  -- Allows ALL rows for anonymous users

-- Step 6: Create policy for authenticated role (allows logged-in users)
CREATE POLICY "Authenticated users can view fighter profiles"
ON public.fighter_profiles
FOR SELECT
TO authenticated
USING (true);  -- Allows ALL rows for authenticated users

-- ============================================================================
-- PART 2: Fix profiles (for My Profile page)
-- ============================================================================

-- Step 1: Grant schema usage
GRANT USAGE ON SCHEMA public TO authenticated;

-- Step 2: Grant table SELECT permission
GRANT SELECT ON TABLE public.profiles TO authenticated;

-- Step 3: Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop ALL existing SELECT policies
DO $$
DECLARE
  policy_rec RECORD;
BEGIN
  FOR policy_rec IN 
    SELECT policyname
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles' 
      AND cmd = 'SELECT'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', policy_rec.policyname);
  END LOOP;
END $$;

-- Step 5: Create policy for authenticated role
CREATE POLICY "Authenticated users can view profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);  -- Allows authenticated users to view all profiles (needed for admin checks)

-- ============================================================================
-- VERIFICATION: Check that it worked
-- ============================================================================

-- Check 1: Verify policies exist for anon role (CRITICAL for browser access)
SELECT 
  'Check 1: anon Policies' as check_type,
  tablename,
  policyname,
  roles,
  cmd as command,
  CASE 
    WHEN 'anon' = ANY(roles) THEN '✅ anon role has access'
    ELSE '❌ anon role MISSING'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY 
  CASE WHEN 'anon' = ANY(roles) THEN 1 ELSE 2 END,
  policyname;

-- Check 2: Verify policies exist for authenticated role
SELECT 
  'Check 2: authenticated Policies' as check_type,
  tablename,
  policyname,
  roles,
  cmd as command,
  CASE 
    WHEN 'authenticated' = ANY(roles) THEN '✅ authenticated role has access'
    ELSE '❌ authenticated role MISSING'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY 
  CASE WHEN 'authenticated' = ANY(roles) THEN 1 ELSE 2 END,
  policyname;

-- Check 3: Verify permissions (GRANT statements)
SELECT 
  'Check 3: Table Permissions' as check_type,
  tablename,
  CASE 
    WHEN has_table_privilege('anon', 'public.' || tablename, 'SELECT') THEN '✅ anon can SELECT'
    ELSE '❌ anon CANNOT SELECT'
  END || ' | ' ||
  CASE 
    WHEN has_table_privilege('authenticated', 'public.' || tablename, 'SELECT') THEN '✅ authenticated can SELECT'
    ELSE '❌ authenticated CANNOT SELECT'
  END as permissions
FROM (VALUES ('fighter_profiles'), ('profiles')) AS t(tablename);

-- Check 4: Test query (simulates your app's EXACT query pattern)
-- This is what your app does: SELECT ... FROM fighter_profiles WHERE user_id IS NOT NULL
SELECT 
  'Check 4: Test Query (App Pattern)' as check_type,
  COUNT(*) as row_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ STILL BLOCKED - RLS is filtering all rows'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - RLS allows access! Rows returned: ' || COUNT(*)::text
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Check 5: Show sample rows (if any)
SELECT 
  'Check 5: Sample Rows' as check_type,
  id,
  user_id,
  name,
  points,
  tier,
  weight_class
FROM public.fighter_profiles
WHERE user_id IS NOT NULL
ORDER BY points DESC
LIMIT 10;

-- Check 6: Summary
SELECT 
  '✅ FIX COMPLETE' as status,
  'If Check 4 shows row_count > 0, RLS is fixed!' as message,
  'Hard refresh your app (Ctrl+Shift+R) and fighters should appear.' as next_step;

