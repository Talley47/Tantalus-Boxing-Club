-- Fix 409 Conflict Error for championship_belts table
-- This script fixes RLS policy conflicts that cause 409 errors on SELECT queries

-- Drop all existing policies to start fresh
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public can view all championship belts" ON public.championship_belts;
    DROP POLICY IF EXISTS "Admins can manage championship belts" ON public.championship_belts;
    DROP POLICY IF EXISTS "Fighters can view their own belts" ON public.championship_belts;
    DROP POLICY IF EXISTS "Admins can insert championship belts" ON public.championship_belts;
    DROP POLICY IF EXISTS "Admins can update championship belts" ON public.championship_belts;
    DROP POLICY IF EXISTS "Admins can delete championship belts" ON public.championship_belts;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- RLS Policies (recreated to avoid conflicts)

-- 1. Public SELECT policy - Everyone can view all championship belts
CREATE POLICY "Public can view all championship belts"
    ON public.championship_belts FOR SELECT
    USING (true);

-- 2. Admin policies - Separate policies for each operation to avoid conflicts
-- Admins can insert championship belts
CREATE POLICY "Admins can insert championship belts"
    ON public.championship_belts FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Admins can update championship belts
CREATE POLICY "Admins can update championship belts"
    ON public.championship_belts FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Admins can delete championship belts
CREATE POLICY "Admins can delete championship belts"
    ON public.championship_belts FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Note: The "Fighters can view their own belts" policy is removed because
-- the "Public can view all championship belts" policy already covers this
-- and having multiple SELECT policies can cause conflicts

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Championship belts RLS policies fixed!';
    RAISE NOTICE '   - Public SELECT: Enabled (everyone can view)';
    RAISE NOTICE '   - Admin INSERT: Enabled';
    RAISE NOTICE '   - Admin UPDATE: Enabled';
    RAISE NOTICE '   - Admin DELETE: Enabled';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  The 409 error should now be resolved.';
END $$;

