-- Database trigger to prevent fighters from inviting opponents as training camp sparring partners
-- This enforces the rule at the database level for additional security
-- Run this in Supabase SQL Editor

-- Function to check if two fighters are opponents
CREATE OR REPLACE FUNCTION are_fighters_opponents(fighter1_profile_id UUID, fighter2_profile_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    has_scheduled_fight BOOLEAN := FALSE;
    has_fight_record BOOLEAN := FALSE;
    fighter1_user_id UUID;
    fighter2_user_id UUID;
    fighter1_name TEXT;
    fighter2_name TEXT;
BEGIN
    -- Get user_ids for both fighters
    SELECT user_id INTO fighter1_user_id FROM fighter_profiles WHERE id = fighter1_profile_id;
    SELECT user_id INTO fighter2_user_id FROM fighter_profiles WHERE id = fighter2_profile_id;
    
    -- Get names for both fighters
    SELECT name INTO fighter1_name FROM fighter_profiles WHERE id = fighter1_profile_id;
    SELECT name INTO fighter2_name FROM fighter_profiles WHERE id = fighter2_profile_id;
    
    -- Check if they have a scheduled fight (Scheduled or Pending status)
    SELECT EXISTS(
        SELECT 1 FROM scheduled_fights
        WHERE (
            (fighter1_id = fighter1_profile_id AND fighter2_id = fighter2_profile_id)
            OR (fighter1_id = fighter2_profile_id AND fighter2_id = fighter1_profile_id)
        )
        AND status IN ('Scheduled', 'Pending')
    ) INTO has_scheduled_fight;
    
    IF has_scheduled_fight THEN
        RETURN TRUE;
    END IF;
    
    -- Check if they have fought each other (check fight_records)
    -- Check if fighter1 has fought fighter2 (by name)
    IF fighter2_name IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM fight_records
            WHERE (
                fighter_id = fighter1_profile_id OR fighter_id = fighter1_user_id
            )
            AND LOWER(TRIM(opponent_name)) = LOWER(TRIM(fighter2_name))
        ) INTO has_fight_record;
        
        IF has_fight_record THEN
            RETURN TRUE;
        END IF;
    END IF;
    
    -- Check if fighter2 has fought fighter1 (by name)
    IF fighter1_name IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM fight_records
            WHERE (
                fighter_id = fighter2_profile_id OR fighter_id = fighter2_user_id
            )
            AND LOWER(TRIM(opponent_name)) = LOWER(TRIM(fighter1_name))
        ) INTO has_fight_record;
        
        IF has_fight_record THEN
            RETURN TRUE;
        END IF;
    END IF;
    
    RETURN FALSE;
END;
$$;

-- Trigger function to prevent inserting training camp invitations between opponents
CREATE OR REPLACE FUNCTION prevent_opponents_training_camp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if inviter and invitee are opponents
    IF are_fighters_opponents(NEW.inviter_id, NEW.invitee_id) THEN
        RAISE EXCEPTION 'Cannot invite an opponent to a training camp. Training camps are for sparring partners, not opponents.';
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger before insert
DROP TRIGGER IF EXISTS check_opponents_before_training_camp_invitation ON training_camp_invitations;
CREATE TRIGGER check_opponents_before_training_camp_invitation
    BEFORE INSERT ON training_camp_invitations
    FOR EACH ROW
    EXECUTE FUNCTION prevent_opponents_training_camp();

-- Add comment
COMMENT ON FUNCTION are_fighters_opponents(UUID, UUID) IS 
    'Checks if two fighters are opponents by checking scheduled_fights and fight_records tables. Returns TRUE if they have a scheduled fight or have fought each other before.';

COMMENT ON FUNCTION prevent_opponents_training_camp() IS 
    'Trigger function that prevents fighters from inviting opponents as training camp sparring partners.';

COMMENT ON TRIGGER check_opponents_before_training_camp_invitation ON training_camp_invitations IS 
    'Prevents insertion of training camp invitations between opponents (fighters with scheduled fights or past fight records).';

