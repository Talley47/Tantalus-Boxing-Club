-- Dispute Messaging and Enhanced Dispute Resolution Schema
-- This adds messaging between fighters and admin, and enhances dispute functionality

-- Add columns to disputes table for enhanced functionality
ALTER TABLE disputes 
    ADD COLUMN IF NOT EXISTS fighter1_name TEXT,
    ADD COLUMN IF NOT EXISTS fighter2_name TEXT,
    ADD COLUMN IF NOT EXISTS fight_link TEXT, -- Web link to the fight uploaded by fighter
    ADD COLUMN IF NOT EXISTS dispute_category VARCHAR(50), -- Category: cheating, spamming, exploits, excessive_punches, stamina_draining, power_punches, other
    ADD COLUMN IF NOT EXISTS opponent_id UUID REFERENCES fighter_profiles(id); -- The opponent being disputed against

-- Create dispute_messages table for messaging between fighters and admin
CREATE TABLE IF NOT EXISTS dispute_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dispute_id UUID REFERENCES disputes(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('fighter', 'admin')),
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_dispute_messages_dispute_id ON dispute_messages(dispute_id);
CREATE INDEX IF NOT EXISTS idx_dispute_messages_created_at ON dispute_messages(created_at DESC);

-- Create fight_record_submissions table to track pending fight records
-- This implements the consensus mechanism where both fighters must agree
CREATE TABLE IF NOT EXISTS fight_record_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheduled_fight_id UUID REFERENCES scheduled_fights(id) ON DELETE CASCADE,
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    opponent_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    result VARCHAR(10) NOT NULL CHECK (result IN ('Win', 'Loss', 'Draw')),
    method VARCHAR(20) NOT NULL,
    round INTEGER,
    date DATE NOT NULL,
    weight_class VARCHAR(30) NOT NULL,
    proof_url TEXT,
    notes TEXT,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Confirmed', 'Disputed', 'Cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(scheduled_fight_id, fighter_id) -- One submission per fighter per fight
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_fight_record_submissions_fight_id ON fight_record_submissions(scheduled_fight_id);
CREATE INDEX IF NOT EXISTS idx_fight_record_submissions_fighter_id ON fight_record_submissions(fighter_id);
CREATE INDEX IF NOT EXISTS idx_fight_record_submissions_status ON fight_record_submissions(status);

-- RLS Policies for dispute_messages
ALTER TABLE dispute_messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admin can view all dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Fighters can view their dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Admin can insert dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Fighters can insert their dispute messages" ON dispute_messages;
    DROP POLICY IF EXISTS "Admin can update dispute messages" ON dispute_messages;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Admin can view all messages
CREATE POLICY "Admin can view all dispute messages" ON dispute_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Fighters can view messages for their disputes
CREATE POLICY "Fighters can view their dispute messages" ON dispute_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM disputes d
            WHERE d.id = dispute_messages.dispute_id
            AND (
                d.disputer_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
                OR d.opponent_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
            )
        )
    );

-- Admin can insert messages
CREATE POLICY "Admin can insert dispute messages" ON dispute_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Fighters can insert messages for their disputes
CREATE POLICY "Fighters can insert their dispute messages" ON dispute_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM disputes d
            WHERE d.id = dispute_messages.dispute_id
            AND (
                d.disputer_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
                OR d.opponent_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
            )
        )
        AND sender_type = 'fighter'
        AND sender_id = auth.uid()
    );

-- Admin can update messages (mark as read, etc.)
CREATE POLICY "Admin can update dispute messages" ON dispute_messages
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- RLS Policies for fight_record_submissions
ALTER TABLE fight_record_submissions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters can view their submissions" ON fight_record_submissions;
    DROP POLICY IF EXISTS "Admin can view all submissions" ON fight_record_submissions;
    DROP POLICY IF EXISTS "Fighters can insert their submissions" ON fight_record_submissions;
    DROP POLICY IF EXISTS "Fighters can update their submissions" ON fight_record_submissions;
    DROP POLICY IF EXISTS "Admin can update all submissions" ON fight_record_submissions;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Fighters can view their own submissions
CREATE POLICY "Fighters can view their submissions" ON fight_record_submissions
    FOR SELECT USING (
        fighter_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
        OR opponent_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Admins can view all submissions
CREATE POLICY "Admin can view all submissions" ON fight_record_submissions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Fighters can insert their own submissions
CREATE POLICY "Fighters can insert their submissions" ON fight_record_submissions
    FOR INSERT WITH CHECK (
        fighter_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Fighters can update their own submissions (before confirmation)
CREATE POLICY "Fighters can update their submissions" ON fight_record_submissions
    FOR UPDATE USING (
        fighter_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
        AND status = 'Pending'
    );

-- Admin can update all submissions
CREATE POLICY "Admin can update all submissions" ON fight_record_submissions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Function to check if both fighters agree and create fight record
CREATE OR REPLACE FUNCTION check_fight_record_consensus()
RETURNS TRIGGER AS $$
DECLARE
    v_fighter1_submission RECORD;
    v_fighter2_submission RECORD;
    v_scheduled_fight RECORD;
    v_fighter1_name TEXT;
    v_fighter2_name TEXT;
    v_fighter1_record_id UUID;
    v_fighter2_record_id UUID;
BEGIN
    -- Get the scheduled fight details
    SELECT * INTO v_scheduled_fight
    FROM scheduled_fights
    WHERE id = NEW.scheduled_fight_id;

    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    -- Get both fighter submissions
    SELECT * INTO v_fighter1_submission
    FROM fight_record_submissions
    WHERE scheduled_fight_id = NEW.scheduled_fight_id
    AND fighter_id = v_scheduled_fight.fighter1_id
    AND status = 'Pending';

    SELECT * INTO v_fighter2_submission
    FROM fight_record_submissions
    WHERE scheduled_fight_id = NEW.scheduled_fight_id
    AND fighter_id = v_scheduled_fight.fighter2_id
    AND status = 'Pending';

    -- If both submissions exist, check if they agree
    IF v_fighter1_submission IS NOT NULL AND v_fighter2_submission IS NOT NULL THEN
        -- Check if results match (fighter1's result should be opposite of fighter2's result)
        IF (v_fighter1_submission.result = 'Win' AND v_fighter2_submission.result = 'Loss') OR
           (v_fighter1_submission.result = 'Loss' AND v_fighter2_submission.result = 'Win') OR
           (v_fighter1_submission.result = 'Draw' AND v_fighter2_submission.result = 'Draw') THEN
            
            -- Get fighter names
            SELECT name INTO v_fighter1_name FROM fighter_profiles WHERE id = v_scheduled_fight.fighter1_id;
            SELECT name INTO v_fighter2_name FROM fighter_profiles WHERE id = v_scheduled_fight.fighter2_id;

            -- Create fight records for both fighters
            INSERT INTO fight_records (
                fighter_id,
                opponent_name,
                result,
                method,
                round,
                date,
                weight_class,
                points_earned,
                proof_url,
                notes,
                is_tournament_win
            )
            VALUES (
                v_scheduled_fight.fighter1_id,
                v_fighter2_name,
                v_fighter1_submission.result,
                v_fighter1_submission.method,
                v_fighter1_submission.round,
                v_fighter1_submission.date,
                v_fighter1_submission.weight_class,
                CASE 
                    WHEN v_fighter1_submission.result = 'Win' THEN 5 + CASE WHEN v_fighter1_submission.method IN ('KO', 'TKO') THEN 3 ELSE 0 END
                    WHEN v_fighter1_submission.result = 'Loss' THEN -2
                    ELSE 0
                END,
                v_fighter1_submission.proof_url,
                v_fighter1_submission.notes,
                false
            )
            RETURNING id INTO v_fighter1_record_id;

            INSERT INTO fight_records (
                fighter_id,
                opponent_name,
                result,
                method,
                round,
                date,
                weight_class,
                points_earned,
                proof_url,
                notes,
                is_tournament_win
            )
            VALUES (
                v_scheduled_fight.fighter2_id,
                v_fighter1_name,
                v_fighter2_submission.result,
                v_fighter2_submission.method,
                v_fighter2_submission.round,
                v_fighter2_submission.date,
                v_fighter2_submission.weight_class,
                CASE 
                    WHEN v_fighter2_submission.result = 'Win' THEN 5 + CASE WHEN v_fighter2_submission.method IN ('KO', 'TKO') THEN 3 ELSE 0 END
                    WHEN v_fighter2_submission.result = 'Loss' THEN -2
                    ELSE 0
                END,
                v_fighter2_submission.proof_url,
                v_fighter2_submission.notes,
                false
            )
            RETURNING id INTO v_fighter2_record_id;

            -- Update submissions to confirmed
            UPDATE fight_record_submissions
            SET status = 'Confirmed', updated_at = NOW()
            WHERE id IN (v_fighter1_submission.id, v_fighter2_submission.id);

            -- Update scheduled fight to completed
            UPDATE scheduled_fights
            SET status = 'Completed',
                result1_id = v_fighter1_record_id,
                result2_id = v_fighter2_record_id
            WHERE id = NEW.scheduled_fight_id;

        ELSE
            -- Results don't match - mark both as disputed
            UPDATE fight_record_submissions
            SET status = 'Disputed', updated_at = NOW()
            WHERE id IN (v_fighter1_submission.id, v_fighter2_submission.id);

            -- Update scheduled fight to disputed
            UPDATE scheduled_fights
            SET status = 'Disputed'
            WHERE id = NEW.scheduled_fight_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to check consensus when a submission is created or updated
DROP TRIGGER IF EXISTS trigger_check_fight_record_consensus ON fight_record_submissions;
CREATE TRIGGER trigger_check_fight_record_consensus
    AFTER INSERT OR UPDATE ON fight_record_submissions
    FOR EACH ROW
    WHEN (NEW.status = 'Pending')
    EXECUTE FUNCTION check_fight_record_consensus();

