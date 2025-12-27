-- ============================================================================
-- SIMPLE RLS FIX - Copy ALL of this into Supabase SQL Editor
-- ============================================================================

-- Step 1: Grant permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon;
GRANT SELECT ON TABLE public.fighter_profiles TO authenticated;
GRANT SELECT ON TABLE public.profiles TO anon;
GRANT SELECT ON TABLE public.profiles TO authenticated;

-- Step 2: Enable RLS
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Remove ALL existing policies
DO $$ 
DECLARE r RECORD; 
BEGIN 
  FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); 
  END LOOP; 
  FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles' LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname); 
  END LOOP; 
END $$;

-- Step 4: Create new permissive policies
CREATE POLICY "anon_read_fighter_profiles" ON public.fighter_profiles FOR SELECT TO anon USING (true);
CREATE POLICY "authenticated_read_fighter_profiles" ON public.fighter_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "anon_read_profiles" ON public.profiles FOR SELECT TO anon USING (true);
CREATE POLICY "authenticated_read_profiles" ON public.profiles FOR SELECT TO authenticated USING (true);

-- Step 5: Verify it worked
SELECT 
  'SUCCESS' as status,
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id
FROM public.fighter_profiles;

