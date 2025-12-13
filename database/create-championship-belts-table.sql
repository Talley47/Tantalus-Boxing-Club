-- Create championship_belts table
-- This table stores championship belt information for fighters
-- Admin can assign belts to fighters from different governing bodies

CREATE TABLE IF NOT EXISTS public.championship_belts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fighter_id UUID NOT NULL REFERENCES public.fighter_profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    governing_body TEXT NOT NULL CHECK (governing_body IN (
        'TBA_AMATEUR',
        'TBA_ASSOCIATION',
        'TBC_COUNCIL',
        'TBF_FEDERATION',
        'TBO_WORLD',
        'RING_MAGAZINE'
    )),
    belt_image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    
    -- Ensure a fighter can only have one belt per governing body
    UNIQUE(fighter_id, governing_body)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_championship_belts_fighter_id ON public.championship_belts(fighter_id);
CREATE INDEX IF NOT EXISTS idx_championship_belts_user_id ON public.championship_belts(user_id);
CREATE INDEX IF NOT EXISTS idx_championship_belts_governing_body ON public.championship_belts(governing_body);

-- Enable Row Level Security
ALTER TABLE public.championship_belts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
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

-- RLS Policies
-- Public can view all championship belts (for display on fighter profiles)
CREATE POLICY "Public can view all championship belts"
    ON public.championship_belts FOR SELECT
    USING (true);

-- Admin policies - Separate policies for each operation to avoid conflicts
-- Admins can insert championship belts
CREATE POLICY "Admins can insert championship belts"
    ON public.championship_belts FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (select auth.uid())
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

-- Admins can delete championship belts
CREATE POLICY "Admins can delete championship belts"
    ON public.championship_belts FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = (select auth.uid())
            AND profiles.role = 'admin'
        )
    );

-- Add updated_at trigger
-- Drop trigger if it exists
DROP TRIGGER IF EXISTS update_championship_belts_updated_at ON public.championship_belts;

-- Create or replace the function
CREATE OR REPLACE FUNCTION update_championship_belts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER update_championship_belts_updated_at
    BEFORE UPDATE ON public.championship_belts
    FOR EACH ROW
    EXECUTE FUNCTION update_championship_belts_updated_at();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Championship belts table created successfully!';
    RAISE NOTICE '   - Table: championship_belts';
    RAISE NOTICE '   - RLS Policies: Enabled';
    RAISE NOTICE '   - Governing Bodies: TBA_AMATEUR, TBA_ASSOCIATION, TBC_COUNCIL, TBF_FEDERATION, TBO_WORLD, RING_MAGAZINE';
END $$;

