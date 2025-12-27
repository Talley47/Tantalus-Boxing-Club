GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE r RECORD; BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' AND (cmd = 'SELECT' OR cmd = 'ALL') LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); END LOOP; END $$;
CREATE POLICY "Authenticated users can view fighter profiles" ON public.fighter_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Anonymous users can view fighter profiles" ON public.fighter_profiles FOR SELECT TO anon USING (true);
SELECT '✅ SUCCESS - RLS FIXED!' as status, COUNT(*) as total_fighters FROM public.fighter_profiles;

