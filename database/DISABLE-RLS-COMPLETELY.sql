-- =====================================================
-- QUICK FIX: Disable RLS Completely (Removes ALL Blocking)
-- This will immediately allow access to fighter_profiles
-- Copy ALL lines below and paste into Supabase SQL Editor
-- =====================================================

-- Step 1: Grant permissions (CRITICAL!)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Step 2: Drop ALL existing policies (undo all blocking)
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname);
  END LOOP;
END $$;

-- Step 3: DISABLE RLS completely (removes all security restrictions)
ALTER TABLE public.fighter_profiles DISABLE ROW LEVEL SECURITY;

-- Step 4: Verify RLS is disabled (should show rls_enabled = false)
SELECT 
    'RLS_STATUS' as check_type,
    relname AS table_name,
    relrowsecurity AS rls_enabled
FROM pg_class
WHERE relname = 'fighter_profiles';

-- Step 5: Test that data is visible (should show all rows)
SELECT COUNT(*) as total_visible_rows FROM public.fighter_profiles;

-- ✅ DONE! RLS is now completely disabled - no policies can block access.
-- Refresh your app (Ctrl+Shift+R) and fighters should appear immediately.

