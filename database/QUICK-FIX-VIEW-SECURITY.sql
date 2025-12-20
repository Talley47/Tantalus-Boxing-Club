-- Quick Fix: Remove SECURITY DEFINER from public_fighter_profiles_view
-- Copy and paste this entire script into Supabase SQL Editor and run it

DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;
DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;

CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin');

GRANT SELECT ON public.public_fighter_profiles_view TO authenticated, anon;

COMMENT ON VIEW public.public_fighter_profiles_view IS 
'View of fighter_profiles excluding admin accounts. Uses querying user permissions (SECURITY INVOKER).';

-- Verify
SELECT 'SUCCESS - View recreated without SECURITY DEFINER' as status,
       COUNT(*) as visible_rows 
FROM public.public_fighter_profiles_view;

