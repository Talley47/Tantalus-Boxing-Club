-- ============================================================================
-- COMPREHENSIVE FIX: All RLS Performance and Duplicate Policy Warnings
-- ============================================================================
-- This script fixes:
-- 1. Auth RLS Initialization Plan warnings (auth.uid() re-evaluation)
-- 2. Multiple Permissive Policies warnings (duplicate policies)
--
-- CRITICAL FIX: fighter_profiles will have BOTH anon and authenticated policies
-- This ensures the homepage works BEFORE login (anon role) and AFTER login (authenticated role)
-- Without the anon policy, you'll get HTTP 200 but 0 rows when not logged in!
--
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- ============================================================================
-- PART 1: Fix Auth RLS Initialization Plan Warnings
-- Replace auth.uid() with (select auth.uid()) for better performance
-- ============================================================================

-- 1.1: Fix fighter_profiles RLS Performance
-- Note: This is handled in Part 2.3 where we consolidate duplicate SELECT policies
-- The consolidated policy uses USING (true) which is more efficient than auth.uid() checks

-- 1.2: Fix news_announcements "Authenticated read all news" policy
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated read all news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Authenticated users can view news announcements" ON public.news_announcements;
  
  -- Recreate with optimized policy (no auth.uid() needed since it's just true)
  CREATE POLICY "Authenticated read all news" 
  ON public.news_announcements 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Fixed news_announcements SELECT policy performance';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing news_announcements SELECT: %', SQLERRM;
END $$;

-- 1.3: Fix news_announcements "Authenticated insert news" policy
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated insert news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Authenticated and admins can insert news" ON public.news_announcements;
  
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Authenticated insert news" 
    ON public.news_announcements 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      is_admin_user() 
      OR type = 'fight_result'
    );
  ELSE
    CREATE POLICY "Authenticated insert news" 
    ON public.news_announcements 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
      OR type = 'fight_result'
    );
  END IF;
  
  RAISE NOTICE '✅ Fixed news_announcements INSERT policy performance';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing news_announcements INSERT: %', SQLERRM;
END $$;

-- ============================================================================
-- PART 2: Fix Multiple Permissive Policies Warnings
-- Consolidate duplicate policies for each table and action
-- ============================================================================

-- 2.1: Fix callout_requests duplicate policies
DO $$
BEGIN
  -- DELETE
  DROP POLICY IF EXISTS "Admins can delete callouts" ON public.callout_requests;
  DROP POLICY IF EXISTS "Admins can delete all callouts" ON public.callout_requests;
  
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Admins can delete callouts" 
    ON public.callout_requests 
    FOR DELETE 
    TO authenticated 
    USING (is_admin_user());
  ELSE
    CREATE POLICY "Admins can delete callouts" 
    ON public.callout_requests 
    FOR DELETE 
    TO authenticated 
    USING (
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
  END IF;
  
  -- INSERT
  DROP POLICY IF EXISTS "Admins can insert callouts" ON public.callout_requests;
  DROP POLICY IF EXISTS "Fighters and admins can create callouts" ON public.callout_requests;
  
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Fighters and admins can create callouts" 
    ON public.callout_requests 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      caller_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR is_admin_user()
    );
  ELSE
    CREATE POLICY "Fighters and admins can create callouts" 
    ON public.callout_requests 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      caller_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
  END IF;
  
  -- SELECT
  DROP POLICY IF EXISTS "Admins can view all callouts" ON public.callout_requests;
  DROP POLICY IF EXISTS "Authenticated users can view callouts" ON public.callout_requests;
  
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Authenticated users can view callouts" 
    ON public.callout_requests 
    FOR SELECT 
    TO authenticated 
    USING (
      caller_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR is_admin_user()
      OR status = 'scheduled'
    );
  ELSE
    CREATE POLICY "Authenticated users can view callouts" 
    ON public.callout_requests 
    FOR SELECT 
    TO authenticated 
    USING (
      caller_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
      OR status = 'scheduled'
    );
  END IF;
  
  -- UPDATE
  DROP POLICY IF EXISTS "Admins can update all callouts" ON public.callout_requests;
  DROP POLICY IF EXISTS "Admins can update callouts" ON public.callout_requests;
  DROP POLICY IF EXISTS "Targets can update callouts" ON public.callout_requests;
  
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Targets and admins can update callouts" 
    ON public.callout_requests 
    FOR UPDATE 
    TO authenticated 
    USING (
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR is_admin_user()
    )
    WITH CHECK (
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR is_admin_user()
    );
  ELSE
    CREATE POLICY "Targets and admins can update callouts" 
    ON public.callout_requests 
    FOR UPDATE 
    TO authenticated 
    USING (
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    )
    WITH CHECK (
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
  END IF;
  
  RAISE NOTICE '✅ Fixed callout_requests duplicate policies';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing callout_requests: %', SQLERRM;
END $$;

-- 2.2: Fix fight_records duplicate SELECT policies
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated can view fight records" ON public.fight_records;
  DROP POLICY IF EXISTS "Authenticated users can view fight records" ON public.fight_records;
  
  CREATE POLICY "Authenticated users can view fight records" 
  ON public.fight_records 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Fixed fight_records duplicate SELECT policies';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing fight_records: %', SQLERRM;
END $$;

-- 2.3: Fix fighter_profiles duplicate SELECT policies
-- CRITICAL: Homepage needs public access (anon role) for fighters to show before login
DO $$
DECLARE
  policy_rec RECORD;
  anon_policy_count INTEGER;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 Fixing fighter_profiles duplicate SELECT policies...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Step 1: Dynamically drop ALL existing SELECT policies to ensure no duplicates
  -- This catches any policy names we might not know about
  FOR policy_rec IN 
    SELECT policyname, roles
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND cmd = 'SELECT'
  LOOP
    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', policy_rec.policyname);
      RAISE NOTICE '  ✅ Dropped policy: % (roles: %)', policy_rec.policyname, policy_rec.roles;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '  ⚠️ Could not drop policy %: %', policy_rec.policyname, SQLERRM;
    END;
  END LOOP;
  
  -- Step 2: Also explicitly drop common policy names (in case dynamic drop missed any)
  -- This is a safety net for edge cases
  DROP POLICY IF EXISTS "Users can view own fighter profile" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "authenticated_read_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "authenticated_read_all_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Authenticated users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Anonymous users can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Public can view all fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_fighter_profiles" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "anon_read_all_fighter_profiles" ON public.fighter_profiles;
  
  -- Step 3: Verify all policies are dropped
  SELECT COUNT(*) INTO anon_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT';
  
  IF anon_policy_count > 0 THEN
    RAISE WARNING '⚠️ Warning: % SELECT policies still exist after drop. Attempting force drop...', anon_policy_count;
    -- Force drop any remaining policies
    FOR policy_rec IN 
      SELECT policyname
      FROM pg_policies 
      WHERE schemaname = 'public' 
        AND tablename = 'fighter_profiles' 
        AND cmd = 'SELECT'
    LOOP
      BEGIN
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles CASCADE', policy_rec.policyname);
        RAISE NOTICE '  ✅ Force dropped policy: %', policy_rec.policyname;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '  ⚠️ Could not force drop policy %: %', policy_rec.policyname, SQLERRM;
      END;
    END LOOP;
  END IF;
  
  -- Step 4: Create policy for anon role (public access - needed for homepage before login)
  -- IMPORTANT: Only ONE policy for anon role to avoid "Multiple Permissive Policies" warning
  CREATE POLICY "Public can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO anon 
  USING (true);
  
  RAISE NOTICE '  ✅ Created single anon policy: "Public can view fighter profiles"';
  
  -- Step 5: Create policy for authenticated role (logged-in users)
  CREATE POLICY "Authenticated users can view fighter profiles" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '  ✅ Created authenticated policy: "Authenticated users can view fighter profiles"';
  
  -- Step 6: Verify only ONE anon policy exists
  SELECT COUNT(*) INTO anon_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT'
    AND ('anon' = ANY(roles) OR roles IS NULL OR roles = '{}');
  
  IF anon_policy_count = 1 THEN
    RAISE NOTICE '  ✅ Verification passed: Exactly one anon policy exists';
  ELSIF anon_policy_count = 0 THEN
    RAISE WARNING '  ❌ ERROR: No anon policy exists! Homepage will not work!';
  ELSE
    RAISE WARNING '  ❌ ERROR: % anon policies still exist! Duplicates not fully resolved!', anon_policy_count;
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ Fixed fighter_profiles duplicate SELECT policies (both anon and authenticated)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing fighter_profiles: %', SQLERRM;
  RAISE;
END $$;

-- 2.4: Fix news_announcements duplicate SELECT policies
DO $$
BEGIN
  DROP POLICY IF EXISTS "Admin read all news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Authenticated users can view news" ON public.news_announcements;
  DROP POLICY IF EXISTS "Authenticated and admins can read news" ON public.news_announcements;
  -- Keep "Public read published news" for anon role (separate, no duplicate)
  
  -- The "Authenticated read all news" policy was already created in Part 1.2
  -- Just ensure "Public read published news" is for anon only
  DROP POLICY IF EXISTS "Public read published news" ON public.news_announcements;
  
  CREATE POLICY "Public read published news" 
  ON public.news_announcements 
  FOR SELECT 
  TO anon 
  USING (is_published = TRUE);
  
  RAISE NOTICE '✅ Fixed news_announcements duplicate SELECT policies';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing news_announcements: %', SQLERRM;
END $$;

-- 2.5: Fix scheduled_fights duplicate SELECT policies
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated can view scheduled fights" ON public.scheduled_fights;
  DROP POLICY IF EXISTS "Authenticated users can view scheduled fights" ON public.scheduled_fights;
  
  CREATE POLICY "Authenticated users can view scheduled fights" 
  ON public.scheduled_fights 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Fixed scheduled_fights duplicate SELECT policies';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing scheduled_fights: %', SQLERRM;
END $$;

-- 2.6: Fix tournaments duplicate SELECT policies
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated can view tournaments" ON public.tournaments;
  DROP POLICY IF EXISTS "Authenticated users can view tournaments" ON public.tournaments;
  
  CREATE POLICY "Authenticated users can view tournaments" 
  ON public.tournaments 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Fixed tournaments duplicate SELECT policies';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing tournaments: %', SQLERRM;
END $$;

-- 2.7: Fix training_camp_invitations duplicate policies
DO $$
BEGIN
  -- DELETE
  DROP POLICY IF EXISTS "Admins can delete all training camp invitation" ON public.training_camp_invitations;
  DROP POLICY IF EXISTS "Admins can delete all training camp invitations" ON public.training_camp_invitations;
  DROP POLICY IF EXISTS "Users can delete invitations" ON public.training_camp_invitations;
  
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Users and admins can delete invitations" 
    ON public.training_camp_invitations 
    FOR DELETE 
    TO authenticated 
    USING (
      user_id = (select auth.uid())
      OR is_admin_user()
    );
  ELSE
    CREATE POLICY "Users and admins can delete invitations" 
    ON public.training_camp_invitations 
    FOR DELETE 
    TO authenticated 
    USING (
      user_id = (select auth.uid())
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
  END IF;
  
  -- SELECT
  DROP POLICY IF EXISTS "Admins can view all training camp invitations" ON public.training_camp_invitations;
  DROP POLICY IF EXISTS "Authenticated can view active training camps" ON public.training_camp_invitations;
  DROP POLICY IF EXISTS "Authenticated users can view training camp invitations" ON public.training_camp_invitations;
  DROP POLICY IF EXISTS "Fighters can view own training camp invitations" ON public.training_camp_invitations;
  DROP POLICY IF EXISTS "Users read own invitations" ON public.training_camp_invitations;
  
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Authenticated users can view training camp invitations" 
    ON public.training_camp_invitations 
    FOR SELECT 
    TO authenticated 
    USING (
      inviter_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR is_admin_user()
    );
  ELSE
    CREATE POLICY "Authenticated users can view training camp invitations" 
    ON public.training_camp_invitations 
    FOR SELECT 
    TO authenticated 
    USING (
      inviter_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
  END IF;
  
  -- UPDATE
  DROP POLICY IF EXISTS "Admins can update all training camp invitations" ON public.training_camp_invitations;
  DROP POLICY IF EXISTS "Invitees can update training camp invitations" ON public.training_camp_invitations;
  DROP POLICY IF EXISTS "Users can update invitations" ON public.training_camp_invitations;
  
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    CREATE POLICY "Invitees and admins can update invitations" 
    ON public.training_camp_invitations 
    FOR UPDATE 
    TO authenticated 
    USING (
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR is_admin_user()
    )
    WITH CHECK (
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR is_admin_user()
    );
  ELSE
    CREATE POLICY "Invitees and admins can update invitations" 
    ON public.training_camp_invitations 
    FOR UPDATE 
    TO authenticated 
    USING (
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    )
    WITH CHECK (
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
  END IF;
  
  RAISE NOTICE '✅ Fixed training_camp_invitations duplicate policies';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing training_camp_invitations: %', SQLERRM;
END $$;

-- 2.8: Fix training_camps duplicate SELECT policies
DO $$
BEGIN
  DROP POLICY IF EXISTS "Authenticated can view training camps" ON public.training_camps;
  DROP POLICY IF EXISTS "Authenticated users can view training camps" ON public.training_camps;
  
  CREATE POLICY "Authenticated users can view training camps" 
  ON public.training_camps 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Fixed training_camps duplicate SELECT policies';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error fixing training_camps: %', SQLERRM;
END $$;

-- ============================================================================
-- PART 3: Verification - Check for remaining issues
-- ============================================================================

-- Check for remaining duplicate policies
SELECT 
  'Remaining Duplicates' as check_type,
  tablename,
  cmd as command,
  roles,
  COUNT(*) as policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'callout_requests',
    'fight_records',
    'fighter_profiles',
    'news_announcements',
    'scheduled_fights',
    'tournaments',
    'training_camp_invitations',
    'training_camps'
  )
GROUP BY tablename, cmd, roles
HAVING COUNT(*) > 1
ORDER BY tablename, cmd, roles;

-- Check for unoptimized auth.uid() calls
SELECT 
  'Unoptimized auth.uid()' as check_type,
  tablename,
  policyname,
  cmd,
  CASE 
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN '❌ Needs optimization'
    WHEN with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%' THEN '❌ Needs optimization'
    ELSE '✅ Optimized'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'callout_requests',
    'fight_records',
    'fighter_profiles',
    'news_announcements',
    'scheduled_fights',
    'tournaments',
    'training_camp_invitations',
    'training_camps'
  )
  AND (
    qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%'
    OR with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%'
  )
ORDER BY tablename, policyname;

-- Verify fighter_profiles has both anon and authenticated policies (CRITICAL for homepage)
SELECT 
  'fighter_profiles Access Check' as check_type,
  policyname,
  roles,
  cmd,
  CASE 
    WHEN 'anon' = ANY(roles) THEN '✅ Anon role has access (homepage will work before login)'
    WHEN 'authenticated' = ANY(roles) THEN '✅ Authenticated role has access (homepage will work after login)'
    ELSE '⚠️ Check role assignment'
  END as access_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY roles;

-- Check for duplicate anon policies on fighter_profiles (should be exactly 1)
SELECT 
  'fighter_profiles Duplicate Check' as check_type,
  COUNT(*) as anon_policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names,
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ No duplicates - exactly one anon policy'
    WHEN COUNT(*) = 0 THEN '❌ ERROR: No anon policy exists!'
    WHEN COUNT(*) > 1 THEN '❌ DUPLICATES DETECTED: Multiple anon policies exist'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL);

-- Final summary
SELECT 
  '✅ FIX COMPLETE' as status,
  'All RLS performance and duplicate policy warnings should now be resolved.' as message,
  'fighter_profiles should now be accessible to both anon (public) and authenticated users.' as note;

