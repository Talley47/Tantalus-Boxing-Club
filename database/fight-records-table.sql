-- Fight Records Table for Fighter Profile
-- Run this SQL in your Supabase SQL Editor

-- Create fight_records table if it doesn't exist
CREATE TABLE IF NOT EXISTS fight_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fighter_id UUID NOT NULL REFERENCES fighter_profiles(user_id) ON DELETE CASCADE,
  opponent_name TEXT NOT NULL,
  result TEXT NOT NULL CHECK (result IN ('Win', 'Loss', 'Draw')),
  method TEXT NOT NULL,
  round INTEGER,
  date DATE NOT NULL,
  weight_class TEXT NOT NULL,
  points_earned INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add points_earned column if it doesn't exist
ALTER TABLE fight_records ADD COLUMN IF NOT EXISTS points_earned INTEGER NOT NULL DEFAULT 0;

-- Drop existing constraint if it has lowercase values and recreate with capitalized values
DO $$ 
BEGIN
  -- Try to drop the old constraint (it might not exist, so we ignore errors)
  BEGIN
    ALTER TABLE fight_records DROP CONSTRAINT IF EXISTS fight_records_result_check;
  EXCEPTION WHEN OTHERS THEN
    -- Ignore if constraint doesn't exist
  END;
  
  -- Add the new constraint with capitalized values
  ALTER TABLE fight_records ADD CONSTRAINT fight_records_result_check 
    CHECK (result IN ('Win', 'Loss', 'Draw'));
END $$;

-- Enable RLS
ALTER TABLE fight_records ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own fight records" ON fight_records;
DROP POLICY IF EXISTS "Users can insert own fight records" ON fight_records;
DROP POLICY IF EXISTS "Users can update own fight records" ON fight_records;
DROP POLICY IF EXISTS "Users can delete own fight records" ON fight_records;

-- Users can view their own fight records
CREATE POLICY "Users can view own fight records" ON fight_records
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM fighter_profiles
      WHERE fighter_profiles.user_id = auth.uid()
      AND fighter_profiles.user_id = fight_records.fighter_id
    )
  );

-- Users can insert their own fight records
CREATE POLICY "Users can insert own fight records" ON fight_records
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM fighter_profiles
      WHERE fighter_profiles.user_id = auth.uid()
      AND fighter_profiles.user_id = fight_records.fighter_id
    )
  );

-- Users can update their own fight records
CREATE POLICY "Users can update own fight records" ON fight_records
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM fighter_profiles
      WHERE fighter_profiles.user_id = auth.uid()
      AND fighter_profiles.user_id = fight_records.fighter_id
    )
  );

-- Users can delete their own fight records
CREATE POLICY "Users can delete own fight records" ON fight_records
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM fighter_profiles
      WHERE fighter_profiles.user_id = auth.uid()
      AND fighter_profiles.user_id = fight_records.fighter_id
    )
  );

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_fight_records_fighter_id ON fight_records(fighter_id);
CREATE INDEX IF NOT EXISTS idx_fight_records_date ON fight_records(date DESC);
CREATE INDEX IF NOT EXISTS idx_fight_records_result ON fight_records(result);

