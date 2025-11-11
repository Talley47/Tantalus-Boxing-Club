-- Fix RLS policies for scheduled_fights to allow fighters to create scheduled fights
-- This is needed for the Smart Matchmaking, Training Camp, and Callout systems

-- Enable RLS if not already enabled
ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;

-- Drop existing restrictive INSERT policies
DROP POLICY IF EXISTS "Only admins can manage scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Only admins can insert scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Fighters can create scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Fighters can update their scheduled fights" ON scheduled_fights;

-- Allow fighters to insert scheduled fights where they are one of the fighters
CREATE POLICY "Fighters can create scheduled fights" ON scheduled_fights
    FOR INSERT
    WITH CHECK (
        -- Fighter must be one of the fighters in the scheduled fight
        fighter1_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid()) OR
        fighter2_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Allow fighters to update scheduled fights where they are one of the fighters
CREATE POLICY "Fighters can update their scheduled fights" ON scheduled_fights
    FOR UPDATE
    USING (
        fighter1_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid()) OR
        fighter2_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Ensure public can view scheduled fights (for home page, etc.)
DROP POLICY IF EXISTS "Public can view scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Anyone can view scheduled fights" ON scheduled_fights;

CREATE POLICY "Anyone can view scheduled fights" ON scheduled_fights
    FOR SELECT
    USING (true);

-- Admins can manage all scheduled fights
DROP POLICY IF EXISTS "Admins can manage all scheduled fights" ON scheduled_fights;

CREATE POLICY "Admins can manage all scheduled fights" ON scheduled_fights
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

