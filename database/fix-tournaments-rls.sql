-- Fix RLS Policies for tournaments table
-- This fixes the issue where admins cannot create tournaments due to incorrect RLS policy

-- Drop existing admin policy if it exists
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admin manage tournaments" ON tournaments;
    DROP POLICY IF EXISTS "Admin can view tournaments" ON tournaments;
    DROP POLICY IF EXISTS "Admin can insert tournaments" ON tournaments;
    DROP POLICY IF EXISTS "Admin can update tournaments" ON tournaments;
    DROP POLICY IF EXISTS "Admin can delete tournaments" ON tournaments;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Ensure RLS is enabled
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;

-- Admin manage tournaments policy using profiles table role check
-- Use is_admin_user() function if available, otherwise check profiles table
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Use is_admin_user function
        -- Split FOR ALL into separate policies, all restricted to authenticated
        -- Note: SELECT is handled by "Authenticated can view tournaments" which allows all authenticated users (including admins)
        EXECUTE 'CREATE POLICY "Admin can insert tournaments" ON tournaments
            FOR INSERT TO authenticated
            WITH CHECK (is_admin_user())';
        
        EXECUTE 'CREATE POLICY "Admin can update tournaments" ON tournaments
            FOR UPDATE TO authenticated
            USING (is_admin_user())';
        
        EXECUTE 'CREATE POLICY "Admin can delete tournaments" ON tournaments
            FOR DELETE TO authenticated
            USING (is_admin_user())';
        RAISE NOTICE 'Created Admin manage tournaments policy using is_admin_user() function';
    ELSE
        -- Fallback: check profiles table for admin role
        -- Split FOR ALL into separate policies, all restricted to authenticated
        -- Note: SELECT is handled by "Authenticated can view tournaments" which allows all authenticated users (including admins)
        EXECUTE 'CREATE POLICY "Admin can insert tournaments" ON tournaments
            FOR INSERT TO authenticated
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) AND role = ' || quote_literal('admin') || '
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admin can update tournaments" ON tournaments
            FOR UPDATE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) AND role = ' || quote_literal('admin') || '
                )
            )';
        
        EXECUTE 'CREATE POLICY "Admin can delete tournaments" ON tournaments
            FOR DELETE TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = (select auth.uid()) AND role = ' || quote_literal('admin') || '
                )
            )';
        RAISE NOTICE 'Created Admin manage tournaments policy using profiles table check';
    END IF;
END $$;

-- Ensure public read access exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'tournaments' 
        AND policyname = 'Public read tournaments'
    ) THEN
        -- Restricted to anon only to avoid multiple permissive policies for authenticated role
        EXECUTE 'CREATE POLICY "Public read tournaments" ON tournaments
            FOR SELECT TO anon USING (true)';
        RAISE NOTICE 'Created Public read tournaments policy';
    ELSE
        RAISE NOTICE 'Public read tournaments policy already exists';
    END IF;
END $$;

