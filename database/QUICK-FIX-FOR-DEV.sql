-- ============================================================================
-- ⚡ QUICK FIX FOR DEV - Makes it work NOW
-- ============================================================================
-- Copy this entire block into Supabase SQL Editor and run it
-- This is the "fastest make it work" approach for dev
-- ============================================================================

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
GRANT SELECT ON TABLE public.profiles TO anon, authenticated;

-- Enable RLS
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Remove ALL existing policies
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

-- Create permissive policies (allows all rows - dev only!)
CREATE POLICY "anon_read_all_fighter_profiles" ON public.fighter_profiles FOR SELECT TO anon USING (true);
CREATE POLICY "authenticated_read_all_fighter_profiles" ON public.fighter_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "anon_read_all_profiles" ON public.profiles FOR SELECT TO anon USING (true);
CREATE POLICY "authenticated_read_all_profiles" ON public.profiles FOR SELECT TO authenticated USING (true);

-- Verify
SELECT 
  '✅ QUICK FIX APPLIED' as status,
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id
FROM public.fighter_profiles;

