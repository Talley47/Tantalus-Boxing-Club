-- =====================================================
-- Migration: Fix RLS Policies for fighter_profiles
-- This migration grants permissions and creates RLS policies
-- so that both authenticated and anonymous users can view fighter profiles
-- =====================================================

-- Step 1: Grant schema usage permissions (CRITICAL - often missing!)
-- This allows roles to access the public schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Step 2: Grant table SELECT permissions (CRITICAL - separate from RLS!)
-- This allows roles to query the table (RLS will still filter rows)
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Step 3: Ensure RLS is enabled (recommended security practice)
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop any existing SELECT policies to avoid conflicts
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles' 
      AND (cmd = 'SELECT' OR cmd = 'ALL')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname);
    RAISE NOTICE 'Dropped existing policy: %', r.policyname;
  END LOOP;
END $$;

-- Step 5: Create policy for authenticated users (logged in)
CREATE POLICY "Authenticated users can view fighter profiles"
ON public.fighter_profiles
FOR SELECT
TO authenticated
USING (true);

-- Step 6: Create policy for anonymous users (not logged in)
-- REQUIRED because homepage loads before login
CREATE POLICY "Anonymous users can view fighter profiles"
ON public.fighter_profiles
FOR SELECT
TO anon
USING (true);

-- Step 7: Verify the policies were created
-- This query will show the policies in the results
SELECT 
    'VERIFICATION' as status,
    policyname,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY policyname;

