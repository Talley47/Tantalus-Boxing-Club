-- Fix RLS for auto-matchmaking: Allow system to create scheduled fights for any fighters
-- This function uses SECURITY DEFINER to bypass RLS for auto-matchmaking operations

-- Create a function to insert scheduled fights for auto-matchmaking
-- This bypasses RLS because it runs with the privileges of the function creator
CREATE OR REPLACE FUNCTION create_auto_matched_fight(
    p_fighter1_id UUID,
    p_fighter2_id UUID,
    p_weight_class VARCHAR,
    p_scheduled_date TIMESTAMP WITH TIME ZONE,
    p_timezone VARCHAR,
    p_platform VARCHAR,
    p_connection_notes TEXT,
    p_house_rules TEXT,
    p_match_type VARCHAR DEFAULT 'auto_mandatory',
    p_match_score INTEGER DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_fight_id UUID;
BEGIN
    -- Insert the scheduled fight (bypasses RLS because of SECURITY DEFINER)
    INSERT INTO scheduled_fights (
        fighter1_id,
        fighter2_id,
        weight_class,
        scheduled_date,
        timezone,
        platform,
        connection_notes,
        house_rules,
        status,
        match_type,
        auto_matched_at,
        match_score
    )
    VALUES (
        p_fighter1_id,
        p_fighter2_id,
        p_weight_class,
        p_scheduled_date,
        p_timezone,
        p_platform,
        p_connection_notes,
        p_house_rules,
        'Scheduled',
        p_match_type,
        NOW(),
        p_match_score
    )
    RETURNING id INTO v_fight_id;
    
    RETURN v_fight_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_auto_matched_fight TO authenticated;
GRANT EXECUTE ON FUNCTION create_auto_matched_fight TO anon;

-- Update the existing policy to be more permissive for auto-matching
-- Drop the old restrictive policy if it exists
DROP POLICY IF EXISTS "Fighters can create scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Allow auto-matched fights" ON scheduled_fights;

-- Create a new policy that allows both manual and auto-matched fights
-- Note: The SECURITY DEFINER function bypasses RLS, but we still need a policy
-- for direct inserts (manual fights)
CREATE POLICY "Fighters can create scheduled fights" ON scheduled_fights
    FOR INSERT
    WITH CHECK (
        -- Allow if the user is one of the fighters (for manual fights)
        fighter1_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid()) OR
        fighter2_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Verify the function was created
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'create_auto_matched_fight';

