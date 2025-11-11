-- Add is_tournament_win field to fight_records table
-- This allows fighters to mark if a win came from a tournament

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'fight_records' AND column_name = 'is_tournament_win'
  ) THEN
    ALTER TABLE fight_records ADD COLUMN is_tournament_win BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add index for tournament win queries
CREATE INDEX IF NOT EXISTS idx_fight_records_tournament_win ON fight_records(is_tournament_win) WHERE is_tournament_win = true;

