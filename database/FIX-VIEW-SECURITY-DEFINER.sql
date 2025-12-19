-- ============================================================================
-- FIX: public_fighter_profiles_view SECURITY DEFINER Issue
-- ============================================================================
-- This script fixes the security scanner warning about the view having
-- SECURITY DEFINER properties by removing the dependency on the 
-- is_admin_user_id() SECURITY DEFINER function.
--
-- The issue: The view uses is_admin_user_id() which is a SECURITY DEFINER
-- function. Security scanners flag views that depend on SECURITY DEFINER
-- functions because they can bypass RLS policies.
--
-- The solution: Replace the function call with a direct JOIN to the profiles
-- table, filtering out admin accounts directly in the WHERE clause.
--
-- RUN THIS SCRIPT IN YOUR DATABASE TO FIX THE ISSUE
-- ============================================================================

-- Step 1: Drop the existing view (this removes the SECURITY DEFINER dependency)
DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

-- Step 2: Recreate the view using direct JOIN (no SECURITY DEFINER function)
-- This approach filters out admin fighters without using a SECURITY DEFINER function
-- Note: PostgreSQL views always use the permissions of the querying user by default
-- (Views do not support SECURITY DEFINER - only functions do)
CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM fighter_profiles fp
LEFT JOIN profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin');

-- Step 3: Grant permissions
GRANT SELECT ON public.public_fighter_profiles_view TO authenticated;
GRANT SELECT ON public.public_fighter_profiles_view TO anon;

-- Step 4: Add documentation
COMMENT ON VIEW public.public_fighter_profiles_view IS 
'View of fighter_profiles excluding admin accounts. Uses direct JOIN to avoid SECURITY DEFINER function dependency.';

-- Step 5: Verify the fix
DO $$
DECLARE
    view_exists BOOLEAN;
    view_def TEXT;
BEGIN
    -- Check view exists
    SELECT EXISTS (
        SELECT 1 FROM pg_views 
        WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
    ) INTO view_exists;
    
    IF NOT view_exists THEN
        RAISE EXCEPTION 'View was not created!';
    END IF;
    
    -- Get view definition
    SELECT pg_get_viewdef('public.public_fighter_profiles_view', true) INTO view_def;
    
    -- Verify it does NOT use the SECURITY DEFINER function
    IF view_def LIKE '%is_admin_user_id%' THEN
        RAISE WARNING '❌ FAILED: View still uses is_admin_user_id() function';
        RAISE NOTICE 'View definition: %', view_def;
    ELSE
        RAISE NOTICE '✅ SUCCESS: View created without SECURITY DEFINER function';
        RAISE NOTICE '✅ The security scanner warning should now be resolved';
        RAISE NOTICE '';
        RAISE NOTICE 'View definition:';
        RAISE NOTICE '%', view_def;
    END IF;
END $$;

-- ============================================================================
-- END OF FIX SCRIPT
-- ============================================================================

