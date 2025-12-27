-- ============================================================================
-- 🚨 COMPREHENSIVE FIX: RLS + Fighter Sync
-- ============================================================================
-- This script does TWO critical things:
-- 1. Fixes RLS for fighter_profiles and profiles (so fighters show up)
-- 2. Syncs all fighters to profiles table (ensures data consistency)
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- ============================================================================
-- PART 1: Fix fighter_profiles table RLS (for homepage rankings)
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
  v_count INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 PART 1: Fixing fighter_profiles RLS...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Grant schema usage (CRITICAL - often missing!)
  GRANT USAGE ON SCHEMA public TO anon, authenticated;
  RAISE NOTICE '  ✅ Granted USAGE on public schema to anon, authenticated';
  
  -- Step 2: Grant table SELECT permission (CRITICAL - separate from RLS!)
  GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
  RAISE NOTICE '  ✅ Granted SELECT on public.fighter_profiles to anon, authenticated';
  
  -- Step 3: Ensure RLS is enabled (recommended security practice)
  ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
  RAISE NOTICE '  ✅ Enabled RLS on public.fighter_profiles';
  
  -- Step 4: Drop ALL existing SELECT policies to ensure a clean slate and prevent duplicates
  RAISE NOTICE '  🗑️  Dropping ALL existing SELECT policies on fighter_profiles...';
  FOR policy_rec IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'fighter_profiles'
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
      RAISE NOTICE '    ✅ Dropped policy: %', policy_rec.policyname;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '    ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Also explicitly drop known policy names (in case they weren't caught above or for idempotency)
  DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_all_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Anonymous users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Public can view all fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view all fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Read own fighter profile" ON public.fighter_profiles;
  RAISE NOTICE '  ✅ Ensured known policies are dropped.';
  
  -- Step 5: Create NEW permissive policies for fighter_profiles
  RAISE NOTICE '  📝 Creating NEW permissive policies for fighter_profiles...';
  
  -- Policy for anon role (public access - CRITICAL for homepage)
  CREATE POLICY "Public can view fighter profiles"
  ON public.fighter_profiles
  FOR SELECT
  TO anon
  USING (true); -- Allows ALL rows for anonymous users
  RAISE NOTICE '  ✅ Created policy: "Public can view fighter profiles" for anon role';
  
  -- Policy for authenticated role (logged-in users)
  CREATE POLICY "Authenticated users can view fighter profiles"
  ON public.fighter_profiles
  FOR SELECT
  TO authenticated
  USING (true); -- Allows ALL rows for authenticated users
  RAISE NOTICE '  ✅ Created policy: "Authenticated users can view fighter profiles" for authenticated role';
  
  RAISE NOTICE '✅ Finished fixing public.fighter_profiles RLS.';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ CRITICAL ERROR during fighter_profiles RLS fix: %', SQLERRM;
  RAISE;
END $$;

-- ============================================================================
-- PART 2: Fix profiles table RLS (for My Profile page and admin checks)
-- ============================================================================

DO $$
DECLARE
  policy_rec RECORD;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 PART 2: Fixing profiles RLS...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Grant schema usage (if not already granted)
  GRANT USAGE ON SCHEMA public TO authenticated;
  RAISE NOTICE '  ✅ Granted USAGE on public schema to authenticated';
  
  -- Step 2: Grant table SELECT permission
  GRANT SELECT ON TABLE public.profiles TO authenticated;
  RAISE NOTICE '  ✅ Granted SELECT on public.profiles to authenticated';
  
  -- Step 3: Ensure RLS is enabled
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  RAISE NOTICE '  ✅ Enabled RLS on public.profiles';
  
  -- Step 4: Drop ALL existing SELECT policies to ensure a clean slate and prevent duplicates
  RAISE NOTICE '  🗑️  Dropping ALL existing SELECT policies on profiles...';
  FOR policy_rec IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', policy_rec.policyname);
      RAISE NOTICE '    ✅ Dropped policy: %', policy_rec.policyname;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '    ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Also explicitly drop known policy names
  DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Authenticated users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;
  RAISE NOTICE '  ✅ Ensured known policies are dropped.';
  
  -- Step 5: Create NEW permissive policy for profiles
  CREATE POLICY "Authenticated users can view profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true); -- Allows authenticated users to view all profiles (needed for admin checks)
  RAISE NOTICE '  ✅ Created policy: "Authenticated users can view profiles" for authenticated role';
  
  RAISE NOTICE '✅ Finished fixing public.profiles RLS.';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ CRITICAL ERROR during profiles RLS fix: %', SQLERRM;
  RAISE;
END $$;

-- ============================================================================
-- PART 3: Sync all fighters to profiles table
-- ============================================================================

DO $$
DECLARE
  fighter_rec RECORD;
  created_count INTEGER := 0;
  updated_count INTEGER := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔄 PART 3: Syncing fighters to profiles table...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Iterate through all fighter_profiles
  FOR fighter_rec IN
    SELECT fp.id as fighter_profile_id, fp.user_id, fp.name, au.email
    FROM public.fighter_profiles fp
    JOIN auth.users au ON fp.user_id = au.id
  LOOP
    -- Check if a corresponding profile exists
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = fighter_rec.user_id) THEN
      -- Create a new profile entry
      INSERT INTO public.profiles (id, email, full_name, role)
      VALUES (fighter_rec.user_id, fighter_rec.email, fighter_rec.name, 'fighter');
      RAISE NOTICE '  ✅ Created profile for fighter: % (User ID: %)', fighter_rec.name, fighter_rec.user_id;
      created_count := created_count + 1;
    ELSE
      -- Update existing profile to ensure consistency
      UPDATE public.profiles
      SET
        email = fighter_rec.email,
        full_name = fighter_rec.name,
        updated_at = NOW()
      WHERE id = fighter_rec.user_id
        AND (email IS DISTINCT FROM fighter_rec.email OR full_name IS DISTINCT FROM fighter_rec.name);
      
      IF FOUND THEN
        RAISE NOTICE '  🔄 Updated profile for fighter: % (User ID: %)', fighter_rec.name, fighter_rec.user_id;
        updated_count := updated_count + 1;
      END IF;
    END IF;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '📊 SYNC SUMMARY:';
  RAISE NOTICE '  Total fighters processed: %', (SELECT COUNT(*) FROM public.fighter_profiles);
  RAISE NOTICE '  New profiles created: %', created_count;
  RAISE NOTICE '  Existing profiles updated: %', updated_count;
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ CRITICAL ERROR during fighter to profile sync: %', SQLERRM;
  RAISE;
END $$;

-- ============================================================================
-- PART 4: Verification - Check that everything worked
-- ============================================================================

DO $$
DECLARE
  v_count INTEGER;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔍 PART 4: Verification...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Verify fighter_profiles has both anon and authenticated policies (CRITICAL for homepage)
  SELECT COUNT(*) INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND 'anon' = ANY(roles);
  IF v_count = 1 THEN
    RAISE NOTICE '  ✅ SUCCESS: Exactly 1 anon SELECT policy exists for fighter_profiles';
  ELSIF v_count = 0 THEN
    RAISE WARNING '  ❌ ERROR: No anon SELECT policy exists for fighter_profiles!';
  ELSE
    RAISE WARNING '  ⚠️ WARNING: % anon SELECT policies exist for fighter_profiles (should be 1)', v_count;
  END IF;
  
  SELECT COUNT(*) INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND 'authenticated' = ANY(roles);
  IF v_count = 1 THEN
    RAISE NOTICE '  ✅ SUCCESS: Exactly 1 authenticated SELECT policy exists for fighter_profiles';
  ELSIF v_count = 0 THEN
    RAISE WARNING '  ❌ ERROR: No authenticated SELECT policy exists for fighter_profiles!';
  ELSE
    RAISE WARNING '  ⚠️ WARNING: % authenticated SELECT policies exist for fighter_profiles (should be 1)', v_count;
  END IF;
  
  -- Check permissions
  IF has_table_privilege('anon', 'public.fighter_profiles', 'SELECT') THEN
    RAISE NOTICE '  ✅ anon has SELECT permission on fighter_profiles';
  ELSE
    RAISE WARNING '  ❌ anon MISSING SELECT permission on fighter_profiles';
  END IF;
  
  IF has_table_privilege('authenticated', 'public.fighter_profiles', 'SELECT') THEN
    RAISE NOTICE '  ✅ authenticated has SELECT permission on fighter_profiles';
  ELSE
    RAISE WARNING '  ❌ authenticated MISSING SELECT permission on fighter_profiles';
  END IF;
  
  -- Test query as anon (simulates browser)
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Test Query as anon Role (simulates app homepage)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  SET ROLE anon;
  SELECT COUNT(*) INTO v_count
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL;
  RESET ROLE;
  
  IF v_count = 0 THEN
    RAISE WARNING '❌ RLS STILL BLOCKING: anon role sees 0 rows for fighter_profiles!';
    RAISE WARNING '   Your homepage will likely still show "NO FIGHTERS RETURNED FROM QUERY".';
  ELSE
    RAISE NOTICE '✅ SUCCESS: anon role sees % rows for fighter_profiles!', v_count;
    RAISE NOTICE '   Your homepage should now display fighters.';
  END IF;
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Check sync status
  SELECT COUNT(*) INTO v_count
  FROM public.fighter_profiles fp
  LEFT JOIN public.profiles p ON fp.user_id = p.id
  WHERE p.id IS NULL;
  
  IF v_count = 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '  ✅ SUCCESS: All fighters have corresponding profiles entries';
  ELSE
    RAISE WARNING '';
    RAISE WARNING '  ⚠️ WARNING: % fighters are missing profiles entries', v_count;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ COMPREHENSIVE FIX COMPLETE';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '  Please hard refresh your application (Ctrl+Shift+R or Cmd+Shift+R) and check if the issues are resolved.';
  RAISE NOTICE '  If problems persist, please provide any new console errors or unexpected behavior.';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ CRITICAL ERROR during verification: %', SQLERRM;
  RAISE;
END $$;

-- Final verification queries (run as current user, usually postgres or anon/authenticated)
SELECT
  'Final Verification: Policies' as check_type,
  tablename,
  policyname,
  roles,
  cmd as command
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
  AND cmd = 'SELECT'
ORDER BY tablename,
  CASE WHEN 'anon' = ANY(roles) THEN 1 ELSE 2 END,
  policyname;

SELECT
  'Final Verification: Permissions' as check_type,
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

-- Test query (simulates your app's EXACT query pattern)
SELECT
  'Final Verification: App Query Test' as check_type,
  COUNT(*) as row_count,
  CASE
    WHEN COUNT(*) = 0 THEN '❌ STILL BLOCKED - RLS is filtering all rows'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - RLS allows access! Rows returned: ' || COUNT(*)::text
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Show sample rows (if any)
SELECT
  'Final Verification: Sample Rows' as check_type,
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

-- Check sync status
SELECT
  'Final Verification: Sync Status' as check_type,
  COUNT(fp.user_id) as total_fighters,
  COUNT(p.id) as fighters_with_profiles,
  COUNT(fp.user_id) - COUNT(p.id) as fighters_missing_profiles,
  CASE
    WHEN COUNT(fp.user_id) = COUNT(p.id) THEN '✅ All fighters have profiles'
    ELSE '❌ Some fighters are missing profiles'
  END as sync_status
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id;

