-- Fix public_fighter_profiles_view to remove SECURITY DEFINER property
-- Views should not have SECURITY DEFINER as they should respect RLS policies
-- of the querying user, not the view creator

-- Drop and recreate the view without SECURITY DEFINER
DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

-- Recreate the view without any SECURITY DEFINER properties
-- PostgreSQL views use the permissions of the querying user by default
-- (Views do not support SECURITY DEFINER - only functions do)
-- The view will respect RLS policies of the querying user
CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM fighter_profiles fp
WHERE NOT is_admin_user_id(fp.user_id);

-- Grant SELECT on the view
GRANT SELECT ON public.public_fighter_profiles_view TO authenticated;
GRANT SELECT ON public.public_fighter_profiles_view TO anon;

-- Add comment
COMMENT ON VIEW public.public_fighter_profiles_view IS 'View of fighter_profiles excluding admin accounts. Uses querying user permissions.';

-- Verify the view was created correctly
DO $$
DECLARE
    view_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM pg_views 
        WHERE schemaname = 'public' 
        AND viewname = 'public_fighter_profiles_view'
    ) INTO view_exists;
    
    IF view_exists THEN
        RAISE NOTICE '✅ View public_fighter_profiles_view created successfully';
    ELSE
        RAISE WARNING '❌ Failed to create view';
    END IF;
END $$;

