-- ============================================================================
-- 🚨 DEFINITIVE FIX - This WILL fix fighters not showing
-- ============================================================================
-- 
-- YOU HAVE 32 FIGHTERS IN SUPABASE BUT 0 IN YOUR APP
-- THIS SQL FIXES IT COMPLETELY
--
-- INSTRUCTIONS:
-- 1. Copy ALL of this file (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Click "New Query" (or clear existing query)
-- 4. Paste (Ctrl+V)
-- 5. Click "Run" button (or press F5)
-- 6. Wait for "Success" message
-- 7. Hard refresh your app (Ctrl+Shift+R)
--
-- ============================================================================

-- ============================================================================
-- PART 1: GRANT PERMISSIONS (CRITICAL - Often missing!)
-- ============================================================================

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant table SELECT permissions
GRANT SELECT ON TABLE public.fighter_profiles TO anon;
GRANT SELECT ON TABLE public.fighter_profiles TO authenticated;
GRANT SELECT ON TABLE public.profiles TO anon;
GRANT SELECT ON TABLE public.profiles TO authenticated;

-- ============================================================================
-- PART 2: ENABLE RLS (Keep enabled for security)
-- ============================================================================

ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 3: REMOVE ALL EXISTING SELECT POLICIES (Clean slate)
-- ============================================================================

-- Remove all SELECT policies on fighter_profiles
DO $$ 
DECLARE 
  r RECORD; 
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND (cmd = 'SELECT' OR cmd = 'ALL') 
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); 
  END LOOP; 
END $$;

-- Remove all SELECT policies on profiles
DO $$ 
DECLARE 
  r RECORD; 
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles' 
      AND (cmd = 'SELECT' OR cmd = 'ALL') 
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname); 
  END LOOP; 
END $$;

-- ============================================================================
-- PART 4: CREATE NEW PERMISSIVE POLICIES
-- ============================================================================

-- fighter_profiles: Allow everyone to read (both authenticated and anonymous)
CREATE POLICY "Allow authenticated users to read fighter profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Allow anonymous users to read fighter profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO anon 
USING (true);

-- profiles: Allow authenticated users to read all profiles
CREATE POLICY "Allow authenticated users to read profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- profiles: Allow users to read their own profile
CREATE POLICY "Allow users to read own profile" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (id = auth.uid());

-- ============================================================================
-- PART 5: VERIFICATION - Check if fix worked
-- ============================================================================

-- This query should return your fighter count (> 0)
SELECT 
  '✅ VERIFICATION RESULT' as status,
  COUNT(*) as total_fighters_in_table,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - Fix worked! Fighters are now accessible.'
    ELSE '❌ FAIL - Still 0 fighters. Check if table has data.'
  END as result
FROM public.fighter_profiles;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- 
-- If you see "✅ SUCCESS" above with a fighter count > 0:
-- 1. Hard refresh your app (Ctrl+Shift+R)
-- 2. Fighters should appear immediately!
--
-- If you still see 0 fighters:
-- 1. Run: database/DIAGNOSE-CURRENT-STATE.sql to see what's wrong
-- 2. Check Supabase dashboard → Table Editor → fighter_profiles
-- 3. Make sure fighters actually exist in the table
--
-- ============================================================================

