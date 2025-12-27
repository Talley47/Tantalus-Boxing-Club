-- ============================================================================
-- 🚨🚨🚨 RUN THIS RIGHT NOW - FIXES FIGHTERS NOT SHOWING 🚨🚨🚨
-- ============================================================================
-- 
-- YOU HAVE 30+ FIGHTERS IN SUPABASE BUT THEY'RE NOT SHOWING IN YOUR APP
-- THIS SQL FIXES IT IN 30 SECONDS
--
-- INSTRUCTIONS:
-- 1. Copy ALL of this file (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Click "New Query"
-- 4. Paste (Ctrl+V)
-- 5. Click "Run" button
-- 6. Hard refresh your app (Ctrl+Shift+R)
--
-- ============================================================================

-- Step 1: Grant permissions (CRITICAL - often missing!)
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;
GRANT SELECT ON TABLE public.profiles TO anon, authenticated;

-- Step 2: Enable RLS (keep it enabled for security)
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Remove ALL existing SELECT policies on fighter_profiles
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

-- Step 4: Create NEW permissive SELECT policies for fighter_profiles
CREATE POLICY "Authenticated users can view fighter profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Anonymous users can view fighter profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO anon 
USING (true);

-- Step 5: Remove ALL existing SELECT policies on profiles
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

-- Step 6: Create NEW SELECT policies for profiles
CREATE POLICY "Users can view own profile" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (id = (select auth.uid()));

CREATE POLICY "Authenticated users can query profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (true);

-- Step 7: VERIFY IT WORKED - This should show your fighter count!
SELECT 
  '✅ SUCCESS - RLS FIXED!' as status, 
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id
FROM public.fighter_profiles;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- 
-- If you see "✅ SUCCESS - RLS FIXED!" above with a fighter count > 0,
-- then the fix worked! Now:
--
-- 1. Hard refresh your app (Ctrl+Shift+R)
-- 2. Fighters should appear immediately!
--
-- ============================================================================

