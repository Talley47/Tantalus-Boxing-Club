-- Fix RLS policies to allow checking profiles.role for admin filtering
-- This ensures the filterAdminFighters function can query profiles table

-- Check if profiles table exists and has role column
DO $$
BEGIN
    -- Ensure profiles table has a role column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'role'
    ) THEN
        ALTER TABLE profiles ADD COLUMN role TEXT;
        RAISE NOTICE 'Added role column to profiles table';
    END IF;
END $$;

-- Grant SELECT on profiles table for role checking
-- This allows authenticated users to check if other users are admins
-- (for filtering purposes only)
GRANT SELECT(id, role) ON profiles TO authenticated;

-- Create or update RLS policy to allow reading role for filtering
-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can check roles for filtering" ON profiles;

-- Create policy that allows authenticated users to read id and role
-- This is needed for admin filtering
CREATE POLICY "Users can check roles for filtering" ON profiles
    FOR SELECT
    TO authenticated
    USING (true);

-- Also ensure the admin account has role='admin' set
UPDATE profiles
SET role = 'admin'
WHERE email = 'tantalusboxingclub@gmail.com'
   OR id IN (
       SELECT id FROM auth.users 
       WHERE email = 'tantalusboxingclub@gmail.com'
   );

-- Verify admin accounts are marked
DO $$
DECLARE
    admin_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO admin_count
    FROM profiles
    WHERE role = 'admin';
    
    RAISE NOTICE 'Found % admin account(s) in profiles table', admin_count;
    
    IF admin_count = 0 THEN
        RAISE WARNING 'No admin accounts found! Please manually set role=''admin'' for admin accounts in profiles table';
    END IF;
END $$;

COMMENT ON POLICY "Users can check roles for filtering" ON profiles IS 
'Allows authenticated users to read role column for filtering admin accounts from public views';

