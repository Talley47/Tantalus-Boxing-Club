-- Fix RLS Policies for tournaments table
-- This fixes the issue where admins cannot create tournaments due to incorrect RLS policy

-- Drop existing admin policy if it exists
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admin manage tournaments" ON tournaments;
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
        EXECUTE 'CREATE POLICY "Admin manage tournaments" ON tournaments
            FOR ALL USING (is_admin_user())';
        RAISE NOTICE 'Created Admin manage tournaments policy using is_admin_user() function';
    ELSE
        -- Fallback: check profiles table for admin role
        EXECUTE 'CREATE POLICY "Admin manage tournaments" ON tournaments
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = ' || quote_literal('admin') || '
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
        EXECUTE 'CREATE POLICY "Public read tournaments" ON tournaments
            FOR SELECT USING (true)';
        RAISE NOTICE 'Created Public read tournaments policy';
    ELSE
        RAISE NOTICE 'Public read tournaments policy already exists';
    END IF;
END $$;

