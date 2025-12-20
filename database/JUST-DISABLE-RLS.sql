-- =====================================================
-- ABSOLUTE MINIMUM: Just disable RLS (removes ALL blocking)
-- Copy ALL lines below and paste into Supabase SQL Editor
-- =====================================================

-- Drop all policies (undo blocking)
DO $$ DECLARE r RECORD; BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); END LOOP; END $$;

-- Disable RLS completely
ALTER TABLE public.fighter_profiles DISABLE ROW LEVEL SECURITY;

-- Grant access
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Verify (should show rows)
SELECT 'SUCCESS' as status, COUNT(*) as visible_rows FROM public.fighter_profiles;

