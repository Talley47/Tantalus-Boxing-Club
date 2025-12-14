-- Fix RLS policies for scheduled_fights to allow fighters to create scheduled fights
-- This is needed for the Smart Matchmaking, Training Camp, and Callout systems

-- Drop the "Anyone can view scheduled fights" policy if it exists (to avoid conflicts)
-- This policy may be created by other scripts, so we drop it here to ensure clean execution
DROP POLICY IF EXISTS "Anyone can view scheduled fights" ON scheduled_fights;
-- Consolidated policy name to avoid multiple permissive policies
DROP POLICY IF EXISTS "Public can view scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Public read scheduled fights" ON scheduled_fights;

-- Enable RLS if not already enabled
ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;

-- Drop existing restrictive INSERT policies
DROP POLICY IF EXISTS "Only admins can manage scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Only admins can insert scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Fighters can create scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Fighters and admins can create scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Fighters can update their scheduled fights" ON scheduled_fights;

-- Combined INSERT policy: Fighters can create scheduled fights OR admins can create any
-- This avoids multiple permissive policies for the same role and action
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Fighters and admins can create scheduled fights" ON scheduled_fights;
DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Fighters and admins can create scheduled fights" ON scheduled_fights
            FOR INSERT
            TO authenticated
            WITH CHECK (
                -- Fighter must be one of the fighters in the scheduled fight OR user is admin
                fighter1_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid())) OR
                fighter2_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid())) OR
                is_admin_user()
            )';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Fighters and admins can create scheduled fights" ON scheduled_fights
            FOR INSERT
            TO authenticated
            WITH CHECK (
                -- Fighter must be one of the fighters in the scheduled fight OR user is admin
                fighter1_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid())) OR
                fighter2_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid())) OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE profiles.id = (select auth.uid()) 
                    AND profiles.role = ''admin''
                )
            )';
    END IF;
END $$;

-- Allow fighters to update scheduled fights where they are one of the fighters
CREATE POLICY "Fighters can update their scheduled fights" ON scheduled_fights
    FOR UPDATE
    USING (
        fighter1_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid())) OR
        fighter2_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
    );

-- NOTE: The "Anyone can view scheduled fights" policy is not created in this script to avoid conflicts.
-- If you need to create/update it, run this separately AFTER running this script:
-- DROP POLICY IF EXISTS "Anyone can view scheduled fights" ON scheduled_fights;
-- CREATE POLICY "Anyone can view scheduled fights" ON scheduled_fights FOR SELECT USING (true);

-- Admins can manage scheduled fights (SELECT, UPDATE, DELETE only - INSERT is handled by combined policy above)
-- PostgreSQL doesn't support FOR SELECT, UPDATE, DELETE, so we create separate policies
-- Restricted to authenticated only to avoid multiple permissive policies for anon role
DROP POLICY IF EXISTS "Admins can manage all scheduled fights" ON scheduled_fights;
-- Note: "Admins can view scheduled fights" SELECT policy removed - handled by "Authenticated can view scheduled fights"
DROP POLICY IF EXISTS "Admins can view scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Admins can update scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Admins can delete scheduled fights" ON scheduled_fights;

DO $$
BEGIN
    -- Check if is_admin_user function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Create separate admin policies for UPDATE, DELETE (INSERT and SELECT are handled by other policies)
        -- Note: SELECT is handled by "Authenticated can view scheduled fights" which allows all authenticated users
        EXECUTE 'CREATE POLICY "Admins can update scheduled fights" ON scheduled_fights
            FOR UPDATE TO authenticated
            USING (is_admin_user())';
        
        EXECUTE 'CREATE POLICY "Admins can delete scheduled fights" ON scheduled_fights
            FOR DELETE TO authenticated
            USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table for admin role
        -- Note: SELECT is handled by "Authenticated can view scheduled fights" which allows all authenticated users
        EXECUTE 'CREATE POLICY "Admins can update scheduled fights" ON scheduled_fights
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE profiles.id = (select auth.uid()) 
                    AND profiles.role = ''admin''
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admins can delete scheduled fights" ON scheduled_fights
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE profiles.id = (select auth.uid()) 
                    AND profiles.role = ''admin''
                )
            )';
    END IF;
END $$;

