-- Create fight_url_submissions table for fighters to submit fight URLs to admins
-- This is for Live events and tournaments
-- Run this in Supabase SQL Editor

-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS fight_url_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fighter_id UUID NOT NULL REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    scheduled_fight_id UUID REFERENCES scheduled_fights(id) ON DELETE SET NULL,
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    fight_url TEXT NOT NULL,
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('Live Event', 'Tournament')),
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Reviewed', 'Rejected', 'Approved')),
    admin_notes TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_fight_url_submissions_fighter_id ON fight_url_submissions(fighter_id);
CREATE INDEX IF NOT EXISTS idx_fight_url_submissions_scheduled_fight_id ON fight_url_submissions(scheduled_fight_id);
CREATE INDEX IF NOT EXISTS idx_fight_url_submissions_tournament_id ON fight_url_submissions(tournament_id);
CREATE INDEX IF NOT EXISTS idx_fight_url_submissions_status ON fight_url_submissions(status);
CREATE INDEX IF NOT EXISTS idx_fight_url_submissions_submitted_at ON fight_url_submissions(submitted_at DESC);

-- Enable RLS
ALTER TABLE fight_url_submissions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Fighters can view their own submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Fighters can create their submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Fighters can update their own pending submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Admins can view all submissions" ON fight_url_submissions;
    DROP POLICY IF EXISTS "Admins can update all submissions" ON fight_url_submissions;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Fighters can view their own submissions
CREATE POLICY "Fighters can view their own submissions" ON fight_url_submissions
    FOR SELECT USING (
        fighter_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Fighters can create their own submissions
CREATE POLICY "Fighters can create their submissions" ON fight_url_submissions
    FOR INSERT WITH CHECK (
        fighter_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
    );

-- Fighters can update their own pending submissions (before admin review)
CREATE POLICY "Fighters can update their own pending submissions" ON fight_url_submissions
    FOR UPDATE USING (
        fighter_id IN (SELECT id FROM fighter_profiles WHERE user_id = auth.uid())
        AND status = 'Pending'
    );

-- Admins can view all submissions
DO $$
BEGIN
    -- Try to use is_admin_user function if it exists
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can view all submissions" ON fight_url_submissions
            FOR SELECT USING (is_admin_user())';
    ELSE
        -- Fallback: check profiles table
        EXECUTE 'CREATE POLICY "Admins can view all submissions" ON fight_url_submissions
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Admins can update all submissions (review, approve, reject)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        EXECUTE 'CREATE POLICY "Admins can update all submissions" ON fight_url_submissions
            FOR UPDATE USING (is_admin_user())';
    ELSE
        EXECUTE 'CREATE POLICY "Admins can update all submissions" ON fight_url_submissions
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() 
                    AND role = ''admin''
                )
            )';
    END IF;
END $$;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON fight_url_submissions TO authenticated;

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_fight_url_submissions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_fight_url_submissions_updated_at ON fight_url_submissions;
CREATE TRIGGER trigger_update_fight_url_submissions_updated_at
    BEFORE UPDATE ON fight_url_submissions
    FOR EACH ROW
    EXECUTE FUNCTION update_fight_url_submissions_updated_at();

-- Add helpful comments
COMMENT ON TABLE fight_url_submissions IS 'Allows fighters to submit fight URLs to admins for Live events and tournaments';
COMMENT ON COLUMN fight_url_submissions.event_type IS 'Type of event: Live Event or Tournament';
COMMENT ON COLUMN fight_url_submissions.status IS 'Submission status: Pending, Reviewed, Rejected, or Approved';

