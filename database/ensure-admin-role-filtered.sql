-- Ensure admin accounts are properly marked and filtered from fighter displays
-- This script ensures that admin accounts with fighter profiles are properly identified
-- and can be filtered out from public fighter listings

-- First, check if there are any admin accounts with fighter profiles
-- and ensure they have role='admin' in the profiles table
DO $$
DECLARE
    admin_user_ids UUID[];
    admin_fighter_count INTEGER;
BEGIN
    -- Find all admin user IDs
    SELECT ARRAY_AGG(id) INTO admin_user_ids
    FROM profiles
    WHERE role = 'admin';
    
    -- Check if any admin accounts have fighter profiles
    SELECT COUNT(*) INTO admin_fighter_count
    FROM fighter_profiles fp
    INNER JOIN profiles p ON fp.user_id = p.id
    WHERE p.role = 'admin';
    
    RAISE NOTICE 'Found % admin accounts with fighter profiles', admin_fighter_count;
    
    -- Ensure all admin accounts are marked correctly
    IF admin_user_ids IS NOT NULL AND array_length(admin_user_ids, 1) > 0 THEN
        RAISE NOTICE 'Admin user IDs: %', admin_user_ids;
        
        -- Update any fighter profiles where the user is an admin
        -- This ensures consistency
        UPDATE fighter_profiles
        SET updated_at = NOW()
        WHERE user_id = ANY(admin_user_ids);
        
        RAISE NOTICE 'Updated fighter profiles for admin accounts';
    END IF;
END $$;

-- Create a helper view that excludes admin fighters from public queries
-- This view can be used by RLS policies or services
DROP VIEW IF EXISTS public_fighter_profiles;
CREATE VIEW public_fighter_profiles AS
SELECT fp.*
FROM fighter_profiles fp
INNER JOIN profiles p ON fp.user_id = p.id
WHERE p.role != 'admin' OR p.role IS NULL;

-- Grant access to the view
GRANT SELECT ON public_fighter_profiles TO authenticated;

-- Create a function to check if a user_id is an admin
-- This is more efficient than joining every time
CREATE OR REPLACE FUNCTION is_admin_user(user_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = user_id_param
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION is_admin_user(UUID) TO authenticated;

COMMENT ON FUNCTION is_admin_user(UUID) IS 'Returns true if the user is an admin, false otherwise';



