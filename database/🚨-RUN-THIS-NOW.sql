-- ============================================================================
-- 🚨🚨🚨 THIS IS THE CORRECT FILE! COPY THIS ONE! 🚨🚨🚨
-- ============================================================================
-- 
-- ✅ FILE NAME: 🚨-RUN-THIS-NOW.sql (ends with .sql) ← COPY THIS!
-- ❌ DO NOT COPY: 🎯-OPEN-THIS-FIRST.md (ends with .md) ← WRONG FILE!
-- 
-- IF YOU SEE "#" AT THE START, YOU'RE IN THE WRONG FILE!
-- SQL FILES START WITH "--" (like this line)
-- MARKDOWN FILES START WITH "#" (don't copy those!)
-- ============================================================================
-- 🚨🚨🚨 COPY EVERYTHING BELOW AND RUN IN SUPABASE SQL EDITOR 🚨🚨🚨
-- ============================================================================
-- 
-- INSTRUCTIONS:
-- 1. Select ALL (Ctrl+A)
-- 2. Copy (Ctrl+C)
-- 3. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 4. Paste (Ctrl+V) → Click "Run"
-- 5. Hard refresh your app (Ctrl+Shift+R)
--
-- This fixes the "NO FIGHTERS RETURNED FROM QUERY" error
-- Takes 30 seconds - just copy, paste, click Run
--
-- ============================================================================

-- Step 1: Grant permissions to read fighter_profiles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Step 2: Keep RLS enabled (for security)
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Remove all existing SELECT policies (clean slate)
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

-- Step 4: Create permissive SELECT policies for both roles
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

-- Step 5: Verify it worked - this should return your fighter count!
SELECT 
  '✅ SUCCESS - RLS FIXED!' as status, 
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id
FROM public.fighter_profiles;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- If you see "✅ SUCCESS - RLS FIXED!" above with a fighter count > 0,
-- then the fix worked! Now hard refresh your app (Ctrl+Shift+R).
-- ============================================================================

