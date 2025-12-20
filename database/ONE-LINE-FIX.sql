-- =====================================================
-- ONE-LINE FIX - Copy this ENTIRE block and run it
-- =====================================================

-- This will drop all existing policies and create new ones
DO $$ DECLARE r RECORD; BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON fighter_profiles', r.policyname); END LOOP; END $$; CREATE POLICY "Authenticated users can view all fighter profiles" ON fighter_profiles FOR SELECT TO authenticated USING (true); CREATE POLICY "Anonymous users can view all fighter profiles" ON fighter_profiles FOR SELECT TO anon USING (true);

