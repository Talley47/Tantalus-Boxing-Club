-- ============================================================================
-- FIX: callout_requests Duplicate SELECT Policies - SIMPLE VERSION
-- ============================================================================
-- Consolidates: "Admins can view all callouts" + "Authenticated users can view callouts"
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Drop duplicate SELECT policies
DROP POLICY IF EXISTS "Admins can view all callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Fighters can view own callouts" ON public.callout_requests;

-- Step 2: Create single consolidated SELECT policy
DO $$
BEGIN
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
      caller_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
      OR
      target_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
      OR
      is_admin_user()
      OR
      status = 'scheduled'
    );
  ELSE
    CREATE POLICY "Authenticated users can view callouts" 
    ON public.callout_requests 
    FOR SELECT 
    TO authenticated 
    USING (
      caller_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
      OR
      target_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
      OR
      EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      OR
      status = 'scheduled'
    );
  END IF;
END $$;

-- Step 3: Verify - should show only 1 SELECT policy for authenticated
SELECT 
  'Verification' as status,
  policyname,
  cmd,
  roles,
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY cmd, roles) = 1 THEN '✅ No duplicates'
    ELSE '❌ Still has duplicates'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'SELECT'
  AND ('authenticated' = ANY(roles) OR roles IS NULL);

