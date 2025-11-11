-- Database schema for Smart Matchmaking, Training Camp, and Callout systems
-- Run this SQL in your Supabase SQL Editor

-- ============================================
-- 1. SMART MATCHMAKING SYSTEM
-- ============================================

-- Add column to scheduled_fights to mark auto-matched mandatory fights
ALTER TABLE scheduled_fights 
ADD COLUMN IF NOT EXISTS match_type VARCHAR(20) DEFAULT 'manual' CHECK (match_type IN ('manual', 'auto_mandatory', 'callout', 'training_camp')),
ADD COLUMN IF NOT EXISTS auto_matched_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS match_score INTEGER; -- Compatibility score for the match

-- Create index for auto-matched fights
CREATE INDEX IF NOT EXISTS idx_scheduled_fights_match_type ON scheduled_fights(match_type);
CREATE INDEX IF NOT EXISTS idx_scheduled_fights_auto_matched ON scheduled_fights(auto_matched_at) WHERE match_type = 'auto_mandatory';

-- ============================================
-- 2. TRAINING CAMP SYSTEM
-- ============================================

-- Training Camp Invitations table
CREATE TABLE IF NOT EXISTS training_camp_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inviter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    invitee_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired', 'completed')),
    started_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL, -- 72 hours from start
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    message TEXT
);

-- Create indexes for training camp invitations
CREATE INDEX IF NOT EXISTS idx_training_camp_inviter ON training_camp_invitations(inviter_id);
CREATE INDEX IF NOT EXISTS idx_training_camp_invitee ON training_camp_invitations(invitee_id);
CREATE INDEX IF NOT EXISTS idx_training_camp_status ON training_camp_invitations(status);
CREATE INDEX IF NOT EXISTS idx_training_camp_expires ON training_camp_invitations(expires_at);

-- Create partial unique index to prevent duplicate pending invitations
CREATE UNIQUE INDEX IF NOT EXISTS idx_training_camp_unique_pending 
ON training_camp_invitations(inviter_id, invitee_id) 
WHERE status = 'pending';

-- ============================================
-- 3. CALLOUT SYSTEM
-- ============================================

-- Callout Requests table
CREATE TABLE IF NOT EXISTS callout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caller_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    target_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired', 'scheduled')),
    match_score INTEGER, -- Fairness score for the match
    rank_difference INTEGER, -- Difference in rankings
    points_difference INTEGER, -- Difference in points
    weight_class VARCHAR(30) NOT NULL,
    tier_match BOOLEAN DEFAULT false, -- Whether fighters are in same tier
    message TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL, -- 7 days expiration
    scheduled_fight_id UUID REFERENCES scheduled_fights(id) ON DELETE SET NULL, -- Link to scheduled fight if accepted
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for callout requests
CREATE INDEX IF NOT EXISTS idx_callout_caller ON callout_requests(caller_id);
CREATE INDEX IF NOT EXISTS idx_callout_target ON callout_requests(target_id);
CREATE INDEX IF NOT EXISTS idx_callout_status ON callout_requests(status);
CREATE INDEX IF NOT EXISTS idx_callout_expires ON callout_requests(expires_at);

-- Create partial unique index to prevent duplicate pending callouts
CREATE UNIQUE INDEX IF NOT EXISTS idx_callout_unique_pending 
ON callout_requests(caller_id, target_id) 
WHERE status = 'pending';

-- ============================================
-- 4. RLS POLICIES
-- ============================================

-- Training Camp Invitations RLS
ALTER TABLE training_camp_invitations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Fighters can view own training camp invitations" ON training_camp_invitations;
DROP POLICY IF EXISTS "Fighters can create training camp invitations" ON training_camp_invitations;
DROP POLICY IF EXISTS "Invitees can update training camp invitations" ON training_camp_invitations;
DROP POLICY IF EXISTS "Admins can manage all training camp invitations" ON training_camp_invitations;

-- Fighters can view their own invitations (as inviter or invitee)
CREATE POLICY "Fighters can view own training camp invitations" ON training_camp_invitations
    FOR SELECT
    USING (
        inviter_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid()) OR
        invitee_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Fighters can create invitations
CREATE POLICY "Fighters can create training camp invitations" ON training_camp_invitations
    FOR INSERT
    WITH CHECK (
        inviter_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Invitees can update (accept/decline) their invitations
CREATE POLICY "Invitees can update training camp invitations" ON training_camp_invitations
    FOR UPDATE
    USING (
        invitee_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Admins can manage all invitations
CREATE POLICY "Admins can manage all training camp invitations" ON training_camp_invitations
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Callout Requests RLS
ALTER TABLE callout_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Fighters can view own callouts" ON callout_requests;
DROP POLICY IF EXISTS "Fighters can create callouts" ON callout_requests;
DROP POLICY IF EXISTS "Targets can update callouts" ON callout_requests;
DROP POLICY IF EXISTS "Admins can manage all callouts" ON callout_requests;

-- Fighters can view callouts where they are caller or target
CREATE POLICY "Fighters can view own callouts" ON callout_requests
    FOR SELECT
    USING (
        caller_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid()) OR
        target_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Fighters can create callouts
CREATE POLICY "Fighters can create callouts" ON callout_requests
    FOR INSERT
    WITH CHECK (
        caller_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Targets can update (accept/decline) callouts
CREATE POLICY "Targets can update callouts" ON callout_requests
    FOR UPDATE
    USING (
        target_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Admins can manage all callouts
CREATE POLICY "Admins can manage all callouts" ON callout_requests
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Update scheduled_fights RLS to allow viewing auto-matched fights
-- (Assuming existing policies already allow viewing, we just need to ensure they work)

-- ============================================
-- 5. FUNCTIONS & TRIGGERS
-- ============================================

-- Function to automatically expire old training camp invitations
CREATE OR REPLACE FUNCTION expire_training_camp_invitations()
RETURNS void AS $$
BEGIN
    UPDATE training_camp_invitations
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending' 
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to automatically expire old callout requests
CREATE OR REPLACE FUNCTION expire_callout_requests()
RETURNS void AS $$
BEGIN
    UPDATE callout_requests
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending' 
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to check if fighter can start training camp (not within 3 days of fight deadline)
CREATE OR REPLACE FUNCTION can_start_training_camp(fighter_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    days_until_fight INTEGER;
BEGIN
    -- Check if fighter has any scheduled fights within 4 days (3 days + 1 day buffer)
    SELECT COUNT(*) INTO days_until_fight
    FROM scheduled_fights sf
    JOIN fighter_profiles fp1 ON sf.fighter1_id = fp1.id
    JOIN fighter_profiles fp2 ON sf.fighter2_id = fp2.id
    WHERE (fp1.user_id = fighter_user_id OR fp2.user_id = fighter_user_id)
    AND sf.status = 'Scheduled'
    AND sf.scheduled_date BETWEEN NOW() AND NOW() + INTERVAL '4 days';
    
    -- If fighter has a fight within 4 days, they cannot start training camp
    RETURN days_until_fight = 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. GRANTS
-- ============================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON training_camp_invitations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON callout_requests TO authenticated;

