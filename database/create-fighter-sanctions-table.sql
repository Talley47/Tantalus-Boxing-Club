-- Create fighter_sanctions table
-- This table tracks which fighters have joined which boxing sanctions

CREATE TABLE IF NOT EXISTS public.fighter_sanctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fighter_id UUID NOT NULL REFERENCES public.fighter_profiles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sanction_acronym TEXT NOT NULL CHECK (sanction_acronym IN (
        'TBCA',
        'TBA',
        'TBO',
        'TBF',
        'TBC',
        'TRM'
    )),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure a fighter can only join each sanction once
    UNIQUE(fighter_id, sanction_acronym)
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_fighter_sanctions_fighter_id ON public.fighter_sanctions(fighter_id);
CREATE INDEX IF NOT EXISTS idx_fighter_sanctions_user_id ON public.fighter_sanctions(user_id);
CREATE INDEX IF NOT EXISTS idx_fighter_sanctions_sanction_acronym ON public.fighter_sanctions(sanction_acronym);

-- Enable Row Level Security
ALTER TABLE public.fighter_sanctions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Public can view all fighter sanctions" ON public.fighter_sanctions;
    DROP POLICY IF EXISTS "Fighters can join sanctions" ON public.fighter_sanctions;
    DROP POLICY IF EXISTS "Fighters can leave their own sanctions" ON public.fighter_sanctions;
    DROP POLICY IF EXISTS "Admins can manage fighter sanctions" ON public.fighter_sanctions;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- RLS Policies

-- Public can view all fighter sanctions (for display on sanction pages)
CREATE POLICY "Public can view all fighter sanctions"
    ON public.fighter_sanctions FOR SELECT
    USING (true);

-- Fighters can join sanctions
CREATE POLICY "Fighters can join sanctions"
    ON public.fighter_sanctions FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Fighters can leave their own sanctions
CREATE POLICY "Fighters can leave their own sanctions"
    ON public.fighter_sanctions FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Admins can manage all fighter sanctions
CREATE POLICY "Admins can manage fighter sanctions"
    ON public.fighter_sanctions FOR ALL
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

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Fighter sanctions table created successfully!';
    RAISE NOTICE '   - Table: fighter_sanctions';
    RAISE NOTICE '   - RLS Policies: Enabled';
    RAISE NOTICE '   - Sanctions: TBCA, TBA, TBO, TBF, TBC, TRM';
END $$;

