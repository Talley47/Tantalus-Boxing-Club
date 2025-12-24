-- ============================================================================
-- FIX: RLS Performance Issues - All Tables
-- ============================================================================
-- This script optimizes RLS policies on multiple tables by replacing
-- auth.uid() with (select auth.uid()) for better performance.
-- 
-- Tables fixed:
-- - profiles: "Users can update own profile"
-- - fight_records: "Users can insert their own fight records"
-- - notifications: "Users can view their own notifications"
-- - training_logs: "Users can view their own training logs"
-- - callout_requests: "Fighters can view own callouts" + "Admins can manage all callouts"
-- - training_camps: "Users can create training camps"
-- - social_links: "Users can insert their own social links"
-- - scouting_reports: "Users can view their own scouting reports"
-- - rivalries: "Users can view rivalries they are part of"
-- - push_tokens: "Users can view their own push tokens"
-- - notification_preferences: "Users can view their own notification preferences"
-- - media_likes: "Users can insert their own media likes"
-- ============================================================================

-- ============================================================================
-- PART 1: Fix profiles table
-- ============================================================================

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;

-- Recreate with optimized syntax
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (id = (select auth.uid()));

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = (select auth.uid()))
  WITH CHECK (id = (select auth.uid()));

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = (select auth.uid()));

-- ============================================================================
-- PART 2: Fix fight_records table
-- ============================================================================

DROP POLICY IF EXISTS "Users can insert their own fight records" ON public.fight_records;
DROP POLICY IF EXISTS "Users can insert own fight records" ON public.fight_records;

-- Recreate with optimized syntax
CREATE POLICY "Users can insert their own fight records" ON public.fight_records
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id));

-- ============================================================================
-- PART 3: Fix notifications table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;

-- Recreate with optimized syntax
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can update their own notifications" ON public.notifications
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "Users can delete their own notifications" ON public.notifications
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- ============================================================================
-- PART 4: Fix training_logs table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own training logs" ON public.training_logs;
DROP POLICY IF EXISTS "Users can insert their own training logs" ON public.training_logs;
DROP POLICY IF EXISTS "Users can update their own training logs" ON public.training_logs;
DROP POLICY IF EXISTS "Users can delete their own training logs" ON public.training_logs;

-- Recreate with optimized syntax
CREATE POLICY "Users can view their own training logs" ON public.training_logs
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_logs.fighter_id));

CREATE POLICY "Users can insert their own training logs" ON public.training_logs
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_logs.fighter_id));

CREATE POLICY "Users can update their own training logs" ON public.training_logs
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_logs.fighter_id))
  WITH CHECK ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_logs.fighter_id));

CREATE POLICY "Users can delete their own training logs" ON public.training_logs
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_logs.fighter_id));

-- ============================================================================
-- PART 5: Fix callout_requests table
-- ============================================================================

DROP POLICY IF EXISTS "Fighters can view own callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Fighters can create callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Targets can update callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can manage all callouts" ON public.callout_requests;

-- Recreate with optimized syntax
CREATE POLICY "Fighters can view own callouts" ON public.callout_requests
  FOR SELECT
  TO authenticated
  USING (
    caller_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid())) OR
    target_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
  );

CREATE POLICY "Fighters can create callouts" ON public.callout_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (
    caller_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
  );

CREATE POLICY "Targets can update callouts" ON public.callout_requests
  FOR UPDATE
  TO authenticated
  USING (
    target_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
  )
  WITH CHECK (
    target_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
  );

CREATE POLICY "Admins can manage all callouts" ON public.callout_requests
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- ============================================================================
-- PART 6: Fix training_camps table
-- ============================================================================

DROP POLICY IF EXISTS "Users can create training camps" ON public.training_camps;
DROP POLICY IF EXISTS "Users can update their own training camps" ON public.training_camps;
DROP POLICY IF EXISTS "Users can delete their own training camps" ON public.training_camps;

-- Recreate with optimized syntax
CREATE POLICY "Users can create training camps" ON public.training_camps
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_camps.created_by));

CREATE POLICY "Users can update their own training camps" ON public.training_camps
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_camps.created_by))
  WITH CHECK ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_camps.created_by));

CREATE POLICY "Users can delete their own training camps" ON public.training_camps
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = training_camps.created_by));

-- ============================================================================
-- PART 7: Fix social_links table
-- ============================================================================

DROP POLICY IF EXISTS "Users can insert their own social links" ON public.social_links;
DROP POLICY IF EXISTS "Users can update their own social links" ON public.social_links;
DROP POLICY IF EXISTS "Users can delete their own social links" ON public.social_links;

-- Recreate with optimized syntax
CREATE POLICY "Users can insert their own social links" ON public.social_links
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = social_links.fighter_id)
  );

CREATE POLICY "Users can update their own social links" ON public.social_links
  FOR UPDATE
  TO authenticated
  USING (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = social_links.fighter_id)
  )
  WITH CHECK (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = social_links.fighter_id)
  );

CREATE POLICY "Users can delete their own social links" ON public.social_links
  FOR DELETE
  TO authenticated
  USING (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = social_links.fighter_id)
  );

-- ============================================================================
-- PART 8: Fix scouting_reports table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own scouting reports" ON public.scouting_reports;
DROP POLICY IF EXISTS "Users can insert their own scouting reports" ON public.scouting_reports;
DROP POLICY IF EXISTS "Users can update their own scouting reports" ON public.scouting_reports;
DROP POLICY IF EXISTS "Users can delete their own scouting reports" ON public.scouting_reports;

-- Recreate with optimized syntax
CREATE POLICY "Users can view their own scouting reports" ON public.scouting_reports
  FOR SELECT
  TO authenticated
  USING (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = scouting_reports.scout_id)
  );

CREATE POLICY "Users can insert their own scouting reports" ON public.scouting_reports
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = scouting_reports.scout_id)
  );

CREATE POLICY "Users can update their own scouting reports" ON public.scouting_reports
  FOR UPDATE
  TO authenticated
  USING (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = scouting_reports.scout_id)
  )
  WITH CHECK (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = scouting_reports.scout_id)
  );

CREATE POLICY "Users can delete their own scouting reports" ON public.scouting_reports
  FOR DELETE
  TO authenticated
  USING (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = scouting_reports.scout_id)
  );

-- ============================================================================
-- PART 9: Fix rivalries table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view rivalries they are part of" ON public.rivalries;
DROP POLICY IF EXISTS "Users can create rivalries they are part of" ON public.rivalries;
DROP POLICY IF EXISTS "Users can update rivalries they are part of" ON public.rivalries;
DROP POLICY IF EXISTS "Users can delete rivalries they are part of" ON public.rivalries;

-- Recreate with optimized syntax
CREATE POLICY "Users can view rivalries they are part of" ON public.rivalries
  FOR SELECT
  TO authenticated
  USING (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter1_id) OR
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter2_id)
  );

CREATE POLICY "Users can create rivalries they are part of" ON public.rivalries
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter1_id) OR
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter2_id)
  );

CREATE POLICY "Users can update rivalries they are part of" ON public.rivalries
  FOR UPDATE
  TO authenticated
  USING (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter1_id) OR
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter2_id)
  )
  WITH CHECK (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter1_id) OR
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter2_id)
  );

CREATE POLICY "Users can delete rivalries they are part of" ON public.rivalries
  FOR DELETE
  TO authenticated
  USING (
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter1_id) OR
    (select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = rivalries.fighter2_id)
  );

-- ============================================================================
-- PART 10: Fix push_tokens table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own push tokens" ON public.push_tokens;
DROP POLICY IF EXISTS "Users can insert their own push tokens" ON public.push_tokens;
DROP POLICY IF EXISTS "Users can update their own push tokens" ON public.push_tokens;
DROP POLICY IF EXISTS "Users can delete their own push tokens" ON public.push_tokens;

-- Recreate with optimized syntax
CREATE POLICY "Users can view their own push tokens" ON public.push_tokens
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = push_tokens.user_id);

CREATE POLICY "Users can insert their own push tokens" ON public.push_tokens
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = push_tokens.user_id);

CREATE POLICY "Users can update their own push tokens" ON public.push_tokens
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = push_tokens.user_id)
  WITH CHECK ((select auth.uid()) = push_tokens.user_id);

CREATE POLICY "Users can delete their own push tokens" ON public.push_tokens
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = push_tokens.user_id);

-- ============================================================================
-- PART 11: Fix notification_preferences table
-- ============================================================================

DROP POLICY IF EXISTS "Users can view their own notification preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can insert their own notification preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can update their own notification preferences" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can delete their own notification preferences" ON public.notification_preferences;

-- Recreate with optimized syntax
CREATE POLICY "Users can view their own notification preferences" ON public.notification_preferences
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = notification_preferences.user_id);

CREATE POLICY "Users can insert their own notification preferences" ON public.notification_preferences
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = notification_preferences.user_id);

CREATE POLICY "Users can update their own notification preferences" ON public.notification_preferences
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = notification_preferences.user_id)
  WITH CHECK ((select auth.uid()) = notification_preferences.user_id);

CREATE POLICY "Users can delete their own notification preferences" ON public.notification_preferences
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = notification_preferences.user_id);

-- ============================================================================
-- PART 12: Fix media_likes table
-- ============================================================================

DROP POLICY IF EXISTS "Users can insert their own media likes" ON public.media_likes;
DROP POLICY IF EXISTS "Users can delete their own media likes" ON public.media_likes;

-- Note: "Users can view all media likes" uses (true) and doesn't need optimization

-- Recreate with optimized syntax
CREATE POLICY "Users can insert their own media likes" ON public.media_likes
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = media_likes.user_id);

CREATE POLICY "Users can delete their own media likes" ON public.media_likes
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = media_likes.user_id);

-- ============================================================================
-- PART 13: Verification
-- ============================================================================

SELECT 
  'VERIFICATION' as check_type,
  tablename,
  policyname,
  cmd as command_type,
  CASE 
    WHEN (qual LIKE '%(select auth.uid())%' OR qual IS NULL)
         AND (with_check LIKE '%(select auth.uid())%' OR with_check IS NULL) THEN '✅ Optimized'
    WHEN qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%' THEN '❌ Needs optimization'
    ELSE '✅ No auth functions'
  END as status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename IN ('profiles', 'fight_records', 'notifications', 'training_logs', 'callout_requests', 'training_camps', 'social_links', 'scouting_reports', 'rivalries', 'push_tokens', 'notification_preferences', 'media_likes')
  AND (
    policyname LIKE '%update own profile%'
    OR policyname LIKE '%insert own profile%'
    OR policyname LIKE '%view own profile%'
    OR policyname LIKE '%insert their own fight records%'
    OR policyname LIKE '%insert own fight records%'
    OR policyname LIKE '%view their own notifications%'
    OR policyname LIKE '%update their own notifications%'
    OR policyname LIKE '%delete their own notifications%'
    OR policyname LIKE '%view their own training logs%'
    OR policyname LIKE '%insert their own training logs%'
    OR policyname LIKE '%update their own training logs%'
    OR policyname LIKE '%delete their own training logs%'
    OR policyname LIKE '%view own callouts%'
    OR policyname LIKE '%create callouts%'
    OR policyname LIKE '%update callouts%'
    OR policyname LIKE '%manage all callouts%'
    OR policyname LIKE '%create training camps%'
    OR policyname LIKE '%update their own training camps%'
    OR policyname LIKE '%delete their own training camps%'
    OR policyname LIKE '%insert their own social links%'
    OR policyname LIKE '%update their own social links%'
    OR policyname LIKE '%delete their own social links%'
    OR policyname LIKE '%view their own scouting reports%'
    OR policyname LIKE '%insert their own scouting reports%'
    OR policyname LIKE '%update their own scouting reports%'
    OR policyname LIKE '%delete their own scouting reports%'
    OR policyname LIKE '%view rivalries they are part of%'
    OR policyname LIKE '%create rivalries they are part of%'
    OR policyname LIKE '%update rivalries they are part of%'
    OR policyname LIKE '%delete rivalries they are part of%'
    OR policyname LIKE '%view their own push tokens%'
    OR policyname LIKE '%insert their own push tokens%'
    OR policyname LIKE '%update their own push tokens%'
    OR policyname LIKE '%delete their own push tokens%'
    OR policyname LIKE '%view their own notification preferences%'
    OR policyname LIKE '%insert their own notification preferences%'
    OR policyname LIKE '%update their own notification preferences%'
    OR policyname LIKE '%delete their own notification preferences%'
    OR policyname LIKE '%insert their own media likes%'
    OR policyname LIKE '%delete their own media likes%'
  )
ORDER BY tablename, policyname;

-- ============================================================================
-- FINAL STATUS
-- ============================================================================

DO $$
DECLARE
  unoptimized_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO unoptimized_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename IN ('profiles', 'fight_records', 'notifications', 'training_logs', 'callout_requests', 'training_camps', 'social_links', 'scouting_reports', 'rivalries', 'push_tokens', 'notification_preferences', 'media_likes')
    AND (
      (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
      OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
    );
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF unoptimized_count = 0 THEN
    RAISE NOTICE '✅ SUCCESS: All RLS performance issues fixed!';
    RAISE NOTICE '   - profiles table: optimized';
    RAISE NOTICE '   - fight_records table: optimized';
    RAISE NOTICE '   - notifications table: optimized';
    RAISE NOTICE '   - training_logs table: optimized';
    RAISE NOTICE '   - callout_requests table: optimized';
    RAISE NOTICE '   - training_camps table: optimized';
    RAISE NOTICE '   - social_links table: optimized';
    RAISE NOTICE '   - scouting_reports table: optimized';
    RAISE NOTICE '   - rivalries table: optimized';
    RAISE NOTICE '   - push_tokens table: optimized';
    RAISE NOTICE '   - notification_preferences table: optimized';
    RAISE NOTICE '   - media_likes table: optimized';
    RAISE NOTICE '   Performance warnings should be resolved.';
  ELSE
    RAISE WARNING '⚠️  Found % policy/policies that still need optimization', unoptimized_count;
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- DONE!
-- ============================================================================
-- Next steps:
-- 1. Re-run your security scanner
-- 2. All RLS performance warnings should be resolved ✅
-- ============================================================================

