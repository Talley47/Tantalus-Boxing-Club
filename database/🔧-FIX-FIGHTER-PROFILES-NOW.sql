-- ============================================================================
-- 🔧 FIX: Fighter Profiles SELECT RLS - ONE COMMAND AT A TIME
-- ============================================================================
-- Run each command separately, wait for success before next
-- ============================================================================

-- COMMAND 1: Grant permissions
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- COMMAND 2: Drop old policies (safe to run even if they don't exist)
DROP POLICY IF EXISTS "anon_view_fighters" ON public.fighter_profiles;
DROP POLICY IF EXISTS "auth_view_fighters" ON public.fighter_profiles;

-- COMMAND 3: Create policy for anon
CREATE POLICY "anon_view_fighters"
ON public.fighter_profiles FOR SELECT TO anon USING (true);

-- COMMAND 4: Create policy for authenticated
CREATE POLICY "auth_view_fighters"
ON public.fighter_profiles FOR SELECT TO authenticated USING (true);

-- COMMAND 5: Verify fix worked
SELECT COUNT(*) as fighters FROM public.fighter_profiles;
