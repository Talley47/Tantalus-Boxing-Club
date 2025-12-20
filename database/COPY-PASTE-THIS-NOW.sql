-- =====================================================
-- MINIMAL FIX: Copy ALL lines below and paste into Supabase SQL Editor
-- =====================================================

-- Step 1: Grant permissions (CRITICAL - often missing!)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Step 2: Enable RLS
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Remove old policies
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' AND (cmd = 'SELECT' OR cmd = 'ALL') LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname);
  END LOOP;
END $$;

-- Step 4: Create new policies (BOTH required!)
CREATE POLICY "Authenticated users can view fighter profiles" ON public.fighter_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Anonymous users can view fighter profiles" ON public.fighter_profiles FOR SELECT TO anon USING (true);

-- Step 5: Verify (should show 2 policies)
SELECT policyname, roles, cmd FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles';

