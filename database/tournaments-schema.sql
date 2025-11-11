-- Enhanced Tournament Schema with all required features
-- This includes deadline dates, check-in system, BYE logic, and eligibility requirements

-- Tournament eligibility requirements
CREATE TABLE IF NOT EXISTS tournament_eligibility (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    min_tier VARCHAR(20), -- Minimum tier required (e.g., 'Pro', 'Contender', 'Elite')
    min_points INTEGER, -- Minimum ranking points required
    min_rank INTEGER, -- Minimum rank required
    weight_class VARCHAR(30) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tournament participants with check-in status
CREATE TABLE IF NOT EXISTS tournament_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    seed INTEGER,
    status VARCHAR(20) DEFAULT 'Registered' CHECK (status IN ('Registered', 'Checked In', 'Active', 'Eliminated', 'Withdrawn', 'Bye')),
    check_in_time TIMESTAMP WITH TIME ZONE,
    registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, fighter_id)
);

-- Enhanced tournament brackets with fight deadline and check-in tracking
CREATE TABLE IF NOT EXISTS tournament_brackets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    round INTEGER NOT NULL,
    match_number INTEGER NOT NULL,
    fighter1_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    fighter2_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    winner_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    scheduled_fight_id UUID REFERENCES scheduled_fights(id) ON DELETE SET NULL,
    scheduled_date TIMESTAMP WITH TIME ZONE,
    deadline_date TIMESTAMP WITH TIME ZONE NOT NULL, -- Fight deadline (1 week from match creation)
    fighter1_check_in TIMESTAMP WITH TIME ZONE,
    fighter2_check_in TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Scheduled', 'In Progress', 'Completed', 'Bye', 'No Show')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, round, match_number)
);

-- Tournament results and champions
CREATE TABLE IF NOT EXISTS tournament_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    champion_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    runner_up_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    third_place_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    total_participants INTEGER,
    completion_date TIMESTAMP WITH TIME ZONE,
    final_fight_id UUID REFERENCES scheduled_fights(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tournament champions belt tracking
CREATE TABLE IF NOT EXISTS tournament_champions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    weight_class VARCHAR(30) NOT NULL,
    belt_name VARCHAR(100) NOT NULL,
    tournament_name VARCHAR(100) NOT NULL,
    won_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    defense_count INTEGER DEFAULT 0,
    UNIQUE(tournament_id, fighter_id)
);

-- Update tournaments table to include deadline dates
ALTER TABLE tournaments 
ADD COLUMN IF NOT EXISTS registration_deadline TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS check_in_deadline TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS min_tier VARCHAR(20),
ADD COLUMN IF NOT EXISTS min_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS min_rank INTEGER;

-- Update tournament_brackets table to include deadline_date if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tournament_brackets' AND column_name = 'deadline_date'
    ) THEN
        ALTER TABLE tournament_brackets 
        ADD COLUMN deadline_date TIMESTAMP WITH TIME ZONE;
        
        -- Set a default value for existing rows
        -- Check if created_at exists, if not use NOW()
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'tournament_brackets' AND column_name = 'created_at'
        ) THEN
            UPDATE tournament_brackets 
            SET deadline_date = created_at + INTERVAL '7 days' 
            WHERE deadline_date IS NULL;
        ELSE
            -- If created_at doesn't exist, set deadline to 1 week from now
            UPDATE tournament_brackets 
            SET deadline_date = NOW() + INTERVAL '7 days' 
            WHERE deadline_date IS NULL;
        END IF;
        
        -- Now make it NOT NULL if needed (after setting defaults)
        -- ALTER TABLE tournament_brackets ALTER COLUMN deadline_date SET NOT NULL;
    END IF;
END $$;

-- Update tournament_brackets to add check-in columns if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tournament_brackets' AND column_name = 'fighter1_check_in'
    ) THEN
        ALTER TABLE tournament_brackets 
        ADD COLUMN fighter1_check_in TIMESTAMP WITH TIME ZONE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tournament_brackets' AND column_name = 'fighter2_check_in'
    ) THEN
        ALTER TABLE tournament_brackets 
        ADD COLUMN fighter2_check_in TIMESTAMP WITH TIME ZONE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tournament_brackets' AND column_name = 'scheduled_fight_id'
    ) THEN
        ALTER TABLE tournament_brackets 
        ADD COLUMN scheduled_fight_id UUID REFERENCES scheduled_fights(id) ON DELETE SET NULL;
    END IF;
    
    -- Also ensure created_at exists for future use
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tournament_brackets' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE tournament_brackets 
        ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        
        -- Set default for existing rows
        UPDATE tournament_brackets 
        SET created_at = NOW() 
        WHERE created_at IS NULL;
    END IF;
END $$;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tournament_participants_tournament ON tournament_participants(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_participants_fighter ON tournament_participants(fighter_id);
CREATE INDEX IF NOT EXISTS idx_tournament_brackets_tournament ON tournament_brackets(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_brackets_deadline ON tournament_brackets(deadline_date);
CREATE INDEX IF NOT EXISTS idx_tournament_brackets_status ON tournament_brackets(status);
CREATE INDEX IF NOT EXISTS idx_tournament_champions_fighter ON tournament_champions(fighter_id);
CREATE INDEX IF NOT EXISTS idx_tournament_champions_weight_class ON tournament_champions(weight_class);

-- RLS Policies for tournaments
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_brackets ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_champions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running script)
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Public read tournaments" ON tournaments;
    DROP POLICY IF EXISTS "Admin manage tournaments" ON tournaments;
    DROP POLICY IF EXISTS "Fighters read own participations" ON tournament_participants;
    DROP POLICY IF EXISTS "Fighters join tournaments" ON tournament_participants;
    DROP POLICY IF EXISTS "Public read brackets" ON tournament_brackets;
    DROP POLICY IF EXISTS "Public read results" ON tournament_results;
    DROP POLICY IF EXISTS "Public read champions" ON tournament_champions;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Public read access for tournaments
CREATE POLICY "Public read tournaments" ON tournaments
    FOR SELECT USING (true);

-- Admin write access for tournaments
CREATE POLICY "Admin manage tournaments" ON tournaments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM fighter_profiles fp
            JOIN auth.users u ON fp.user_id = u.id
            WHERE fp.id = (SELECT id FROM fighter_profiles WHERE user_id = auth.uid() LIMIT 1)
            AND u.email LIKE '%@admin.tantalus%'
        )
    );

-- Fighters can read their own tournament participations
CREATE POLICY "Fighters read own participations" ON tournament_participants
    FOR SELECT USING (
        fighter_id = (SELECT id FROM fighter_profiles WHERE user_id = auth.uid() LIMIT 1)
        OR tournament_id IN (SELECT id FROM tournaments WHERE created_by = (SELECT id FROM fighter_profiles WHERE user_id = auth.uid() LIMIT 1))
    );

-- Fighters can insert their own participations (join tournaments)
CREATE POLICY "Fighters join tournaments" ON tournament_participants
    FOR INSERT WITH CHECK (
        fighter_id = (SELECT id FROM fighter_profiles WHERE user_id = auth.uid() LIMIT 1)
    );

-- Public read access for brackets
CREATE POLICY "Public read brackets" ON tournament_brackets
    FOR SELECT USING (true);

-- Public read access for results
CREATE POLICY "Public read results" ON tournament_results
    FOR SELECT USING (true);

-- Public read access for champions
CREATE POLICY "Public read champions" ON tournament_champions
    FOR SELECT USING (true);

