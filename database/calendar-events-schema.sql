-- Calendar Events Schema for TBC Promotions Fight Calendar
-- Run this in your Supabase SQL Editor

-- Add event_type column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'events' AND column_name = 'event_type'
  ) THEN
    ALTER TABLE events ADD COLUMN event_type VARCHAR(50) NOT NULL DEFAULT 'Fight Card'
      CHECK (event_type IN ('Fight Card', 'Tournament', 'Interview', 'Press Conference', 'Podcast'));
  END IF;
END $$;

-- Add description column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'events' AND column_name = 'description'
  ) THEN
    ALTER TABLE events ADD COLUMN description TEXT;
  END IF;
END $$;

-- Add location column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'events' AND column_name = 'location'
  ) THEN
    ALTER TABLE events ADD COLUMN location VARCHAR(255);
  END IF;
END $$;

-- Add featured_fighter_ids column for interviews (auto-selected based on performance)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'events' AND column_name = 'featured_fighter_ids'
  ) THEN
    ALTER TABLE events ADD COLUMN featured_fighter_ids JSONB DEFAULT '[]';
  END IF;
END $$;

-- Add main_card_fight_id for Fight Cards
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'events' AND column_name = 'main_card_fight_id'
  ) THEN
    ALTER TABLE events ADD COLUMN main_card_fight_id UUID REFERENCES scheduled_fights(id);
  END IF;
END $$;

-- Add tournament_id for Tournament events
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'events' AND column_name = 'tournament_id'
  ) THEN
    ALTER TABLE events ADD COLUMN tournament_id UUID REFERENCES tournaments(id);
  END IF;
END $$;

-- Add is_auto_scheduled flag for interviews
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'events' AND column_name = 'is_auto_scheduled'
  ) THEN
    ALTER TABLE events ADD COLUMN is_auto_scheduled BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Update created_by to reference user_id instead of id
-- (keeping backward compatibility)
DO $$ 
BEGIN
  -- This is just documentation - actual foreign key may vary
  NULL;
END $$;

-- Index for faster date queries
CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);


                                                                                        -- Run this in your Supabase SQL Editor

                                                                                        -- Add event_type column if it doesn't exist
                                                                                        DO $$ 
                                                                                        BEGIN
                                                                                        IF NOT EXISTS (
                                                                                            SELECT 1 FROM information_schema.columns 
                                                                                            WHERE table_name = 'events' AND column_name = 'event_type'
                                                                                        ) THEN
                                                                                            ALTER TABLE events ADD COLUMN event_type VARCHAR(50) NOT NULL DEFAULT 'Fight Card'
                                                                                            CHECK (event_type IN ('Fight Card', 'Tournament', 'Interview', 'Press Conference', 'Podcast'));
                                                                                        END IF;
                                                                                        END $$;

                                                                                        -- Add description column if it doesn't exist
                                                                                        DO $$ 
                                                                                        BEGIN
                                                                                        IF NOT EXISTS (
                                                                                            SELECT 1 FROM information_schema.columns 
                                                                                            WHERE table_name = 'events' AND column_name = 'description'
                                                                                        ) THEN
                                                                                            ALTER TABLE events ADD COLUMN description TEXT;
                                                                                        END IF;
                                                                                        END $$;

                                                                                        -- Add location column if it doesn't exist
                                                                                        DO $$ 
                                                                                        BEGIN
                                                                                        IF NOT EXISTS (
                                                                                            SELECT 1 FROM information_schema.columns 
                                                                                            WHERE table_name = 'events' AND column_name = 'location'
                                                                                        ) THEN
                                                                                            ALTER TABLE events ADD COLUMN location VARCHAR(255);
                                                                                        END IF;
                                                                                        END $$;

                                                                                        -- Add featured_fighter_ids column for interviews (auto-selected based on performance)
                                                                                        DO $$ 
                                                                                        BEGIN
                                                                                        IF NOT EXISTS (
                                                                                            SELECT 1 FROM information_schema.columns 
                                                                                            WHERE table_name = 'events' AND column_name = 'featured_fighter_ids'
                                                                                        ) THEN
                                                                                            ALTER TABLE events ADD COLUMN featured_fighter_ids JSONB DEFAULT '[]';
                                                                                        END IF;
                                                                                        END $$;

                                                                                        -- Add main_card_fight_id for Fight Cards
                                                                                        DO $$ 
                                                                                        BEGIN
                                                                                        IF NOT EXISTS (
                                                                                            SELECT 1 FROM information_schema.columns 
                                                                                            WHERE table_name = 'events' AND column_name = 'main_card_fight_id'
                                                                                        ) THEN
                                                                                            ALTER TABLE events ADD COLUMN main_card_fight_id UUID REFERENCES scheduled_fights(id);
                                                                                        END IF;
                                                                                        END $$;

                                                                                        -- Add tournament_id for Tournament events
                                                                                        DO $$ 
                                                                                        BEGIN
                                                                                        IF NOT EXISTS (
                                                                                            SELECT 1 FROM information_schema.columns 
                                                                                            WHERE table_name = 'events' AND column_name = 'tournament_id'
                                                                                        ) THEN
                                                                                            ALTER TABLE events ADD COLUMN tournament_id UUID REFERENCES tournaments(id);
                                                                                        END IF;
                                                                                        END $$;

                                                                                        -- Add is_auto_scheduled flag for interviews
                                                                                        DO $$ 
                                                                                        BEGIN
                                                                                        IF NOT EXISTS (
                                                                                            SELECT 1 FROM information_schema.columns 
                                                                                            WHERE table_name = 'events' AND column_name = 'is_auto_scheduled'
                                                                                        ) THEN
                                                                                            ALTER TABLE events ADD COLUMN is_auto_scheduled BOOLEAN DEFAULT FALSE;
                                                                                        END IF;
                                                                                        END $$;

                                                                                        -- Update created_by to reference user_id instead of id
                                                                                        -- (keeping backward compatibility)
                                                                                        DO $$ 
                                                                                        BEGIN
                                                                                        -- This is just documentation - actual foreign key may vary
                                                                                        NULL;
                                                                                        END $$;

                                                                                        -- Index for faster date queries
                                                                                        CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);
                                                                                        CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
                                                                                        CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);

