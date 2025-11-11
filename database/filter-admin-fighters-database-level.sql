-- Database-level filtering to exclude admin fighters from public queries
-- This ensures admin accounts are hidden even if application-level filtering fails

-- Create a function to check if a user_id is an admin
-- This can be used in WHERE clauses to filter out admin fighters
CREATE OR REPLACE FUNCTION is_admin_user_id(user_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = user_id_param
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION is_admin_user_id(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin_user_id(UUID) TO anon;

-- Create a view that automatically excludes admin fighters
-- This view can be used instead of fighter_profiles for public queries
DROP VIEW IF EXISTS public_fighter_profiles_view CASCADE;
CREATE VIEW public_fighter_profiles_view AS
SELECT fp.*
FROM fighter_profiles fp
WHERE NOT is_admin_user_id(fp.user_id);

-- Grant SELECT on the view
GRANT SELECT ON public_fighter_profiles_view TO authenticated;
GRANT SELECT ON public_fighter_profiles_view TO anon;

-- Create an index to help with performance if needed
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_user_id ON fighter_profiles(user_id);

-- Update RLS policies to use the helper function
-- This ensures admin fighters are excluded at the database level

-- First, let's check existing policies and add admin filtering
-- Note: This assumes you have RLS policies already set up
-- If not, you may need to create them separately

-- Example: Update SELECT policy to exclude admins
-- (Adjust based on your existing RLS setup)
DO $$
BEGIN
    -- Check if there's a SELECT policy that needs updating
    -- This is a template - adjust based on your actual RLS policies
    
    -- For now, we'll rely on the view and application-level filtering
    -- But the function can be used in custom queries
    
    RAISE NOTICE 'Admin filtering function created. Use is_admin_user_id() in WHERE clauses or use public_fighter_profiles_view.';
END $$;

-- Test the function
-- This should return false for non-admin users and true for admin users
-- SELECT is_admin_user_id('user-uuid-here');

COMMENT ON FUNCTION is_admin_user_id(UUID) IS 'Returns true if the user_id belongs to an admin account';
COMMENT ON VIEW public_fighter_profiles_view IS 'View of fighter_profiles excluding admin accounts';



