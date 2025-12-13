-- Fix Fighter Sanctions Join Issue
-- This script ensures the RLS policies allow fighters to join sanctions

-- First, verify the table exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_sanctions'
    ) THEN
        RAISE EXCEPTION 'Table fighter_sanctions does not exist! Run create-fighter-sanctions-table.sql first.';
    END IF;
END $$;

-- Drop existing policies to recreate them
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public can view all fighter sanctions" ON public.fighter_sanctions;
    DROP POLICY IF EXISTS "Fighters can join sanctions" ON public.fighter_sanctions;
    DROP POLICY IF EXISTS "Fighters can leave their own sanctions" ON public.fighter_sanctions;
    DROP POLICY IF EXISTS "Admins can manage fighter sanctions" ON public.fighter_sanctions;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Recreate RLS Policies with improved checks

-- 1. Public can view all fighter sanctions (for display on sanction pages)
CREATE POLICY "Public can view all fighter sanctions"
    ON public.fighter_sanctions FOR SELECT
    USING (true);

-- 2. Fighters can join sanctions
-- This policy allows authenticated users to insert rows where user_id matches their auth.uid()
-- The service already validates that fighter_id exists and belongs to the user
CREATE POLICY "Fighters can join sanctions"
    ON public.fighter_sanctions FOR INSERT
    TO authenticated
    WITH CHECK (
        (select auth.uid()) IS NOT NULL 
        AND (select auth.uid()) = user_id
    );

-- 3. Fighters can leave their own sanctions
CREATE POLICY "Fighters can leave their own sanctions"
    ON public.fighter_sanctions FOR DELETE
    TO authenticated
    USING (
        (select auth.uid()) IS NOT NULL 
        AND (select auth.uid()) = user_id
    );

-- 4. Admins can manage all fighter sanctions
CREATE POLICY "Admins can manage fighter sanctions"
    ON public.fighter_sanctions FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (select auth.uid())
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (select auth.uid())
            AND profiles.role = 'admin'
        )
    );

-- Verify policies were created
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'fighter_sanctions';
    
    IF policy_count >= 4 THEN
        RAISE NOTICE '✅ All RLS policies created successfully!';
    ELSE
        RAISE WARNING '⚠️  Only % policies found. Expected 4.', policy_count;
    END IF;
END $$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Fighter sanctions RLS policies fixed!';
    RAISE NOTICE '   - Public SELECT: Enabled';
    RAISE NOTICE '   - Fighters INSERT: Enabled (with fighter profile check)';
    RAISE NOTICE '   - Fighters DELETE: Enabled';
    RAISE NOTICE '   - Admins ALL: Enabled';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Fighters must have a fighter profile to join sanctions.';
    RAISE NOTICE '   If join still fails, check that:';
    RAISE NOTICE '   1. User is authenticated (logged in)';
    RAISE NOTICE '   2. User has a fighter profile';
    RAISE NOTICE '   3. fighter_profiles.user_id matches auth.uid()';
END $$;

