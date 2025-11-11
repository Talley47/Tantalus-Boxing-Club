-- Tantalus Boxing Club Database Schema - CLEAN VERSION
-- PostgreSQL with Supabase
-- This file removes all duplicate table definitions

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table (handled by Supabase Auth)
-- This table will be automatically created by Supabase Auth

-- Tiers table
CREATE TABLE tiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(20) NOT NULL UNIQUE,
    min_points INTEGER NOT NULL,
    max_points INTEGER,
    color VARCHAR(7) NOT NULL, -- hex color
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tier History
CREATE TABLE tier_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    from_tier VARCHAR(20) NOT NULL,
    to_tier VARCHAR(20) NOT NULL,
    reason VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fighter Profiles
CREATE TABLE fighter_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    handle VARCHAR(50) UNIQUE NOT NULL,
    platform VARCHAR(10) NOT NULL CHECK (platform IN ('PSN', 'Xbox', 'PC')),
    platform_id VARCHAR(50) NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    
    -- Physical attributes
    height INTEGER NOT NULL, -- inches
    weight INTEGER NOT NULL, -- pounds
    reach INTEGER NOT NULL, -- inches
    age INTEGER NOT NULL,
    stance VARCHAR(10) NOT NULL CHECK (stance IN ('Orthodox', 'Southpaw', 'Switch')),
    nationality VARCHAR(50) NOT NULL,
    fighting_style VARCHAR(50) NOT NULL,
    hometown VARCHAR(100) NOT NULL,
    birthday DATE NOT NULL,
    trainer VARCHAR(100),
    gym VARCHAR(100),
    
    -- Record and stats
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    draws INTEGER DEFAULT 0,
    knockouts INTEGER DEFAULT 0,
    points INTEGER DEFAULT 0,
    tier VARCHAR(20) DEFAULT 'Amateur' CHECK (tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite')),
    rank INTEGER DEFAULT 0,
    weight_class VARCHAR(30) NOT NULL,
    
    -- Advanced stats
    win_percentage DECIMAL(5,2) DEFAULT 0.00,
    ko_percentage DECIMAL(5,2) DEFAULT 0.00,
    current_streak INTEGER DEFAULT 0,
    longest_win_streak INTEGER DEFAULT 0,
    longest_loss_streak INTEGER DEFAULT 0,
    average_fight_duration DECIMAL(5,2) DEFAULT 0.00,
    
    -- Recent performance (stored as JSON)
    last_20_results JSONB DEFAULT '[]',
    recent_form JSONB DEFAULT '[]',
    
    -- Social and media
    profile_photo_url TEXT,
    social_links JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fight Records
CREATE TABLE fight_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    opponent_name VARCHAR(100) NOT NULL,
    result VARCHAR(10) NOT NULL CHECK (result IN ('Win', 'Loss', 'Draw')),
    method VARCHAR(20) NOT NULL CHECK (method IN ('UD', 'SD', 'MD', 'KO', 'TKO', 'Submission', 'DQ', 'No Contest')),
    round INTEGER NOT NULL,
    date DATE NOT NULL,
    weight_class VARCHAR(30) NOT NULL,
    points_earned INTEGER NOT NULL,
    proof_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Rankings (cached for performance)
CREATE TABLE rankings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    weight_class VARCHAR(30) NOT NULL,
    rank INTEGER NOT NULL,
    points INTEGER NOT NULL,
    tier VARCHAR(20) NOT NULL,
    win_percentage DECIMAL(5,2) NOT NULL,
    ko_percentage DECIMAL(5,2) NOT NULL,
    recent_form VARCHAR(5) NOT NULL, -- Last 5 results as W/L/D
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Matchmaking Requests
CREATE TABLE matchmaking_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requester_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    target_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    weight_class VARCHAR(30) NOT NULL,
    preferred_time TIMESTAMP WITH TIME ZONE,
    timezone VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Accepted', 'Declined', 'Expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Scheduled Fights
CREATE TABLE scheduled_fights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter1_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    fighter2_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    weight_class VARCHAR(30) NOT NULL,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    platform VARCHAR(10) NOT NULL,
    connection_notes TEXT,
    house_rules TEXT,
    status VARCHAR(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'Disputed')),
    result1_id UUID REFERENCES fight_records(id),
    result2_id UUID REFERENCES fight_records(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Disputes
CREATE TABLE disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fight_id UUID REFERENCES scheduled_fights(id) ON DELETE CASCADE,
    disputer_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    evidence_urls JSONB DEFAULT '[]',
    status VARCHAR(20) DEFAULT 'Open' CHECK (status IN ('Open', 'Under Review', 'Resolved')),
    admin_notes TEXT,
    resolution TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Tournaments
CREATE TABLE tournaments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    format VARCHAR(30) NOT NULL CHECK (format IN ('Single Elimination', 'Double Elimination', 'Group Stage', 'Swiss', 'Round Robin')),
    weight_class VARCHAR(30) NOT NULL,
    max_participants INTEGER NOT NULL,
    entry_fee DECIMAL(10,2) DEFAULT 0.00,
    prize_pool DECIMAL(10,2) DEFAULT 0.00,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Completed', 'Cancelled')),
    created_by UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tournament Participants
CREATE TABLE tournament_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    seed INTEGER,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Eliminated', 'Withdrawn')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tournament_id, fighter_id)
);

-- Tournament Brackets
CREATE TABLE tournament_brackets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
    round INTEGER NOT NULL,
    match_number INTEGER NOT NULL,
    fighter1_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    fighter2_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    winner_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    scheduled_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Scheduled', 'Completed', 'Bye'))
);

-- Title Belts
CREATE TABLE title_belts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    weight_class VARCHAR(30) NOT NULL,
    current_champion_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    belt_name VARCHAR(100) NOT NULL,
    defense_requirement INTEGER DEFAULT 3, -- fights before mandatory defense
    last_defense TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Title History
CREATE TABLE title_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    belt_id UUID REFERENCES title_belts(id) ON DELETE CASCADE,
    champion_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    won_date TIMESTAMP WITH TIME ZONE NOT NULL,
    lost_date TIMESTAMP WITH TIME ZONE,
    defense_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Events (Fight Cards)
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    poster_url TEXT,
    theme VARCHAR(100),
    broadcast_url TEXT,
    status VARCHAR(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Live', 'Completed', 'Cancelled')),
    created_by UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Media Assets
CREATE TABLE media_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    type VARCHAR(10) NOT NULL CHECK (type IN ('Video', 'Photo', 'Audio')),
    title VARCHAR(100) NOT NULL,
    description TEXT,
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    category VARCHAR(20) NOT NULL CHECK (category IN ('Highlight', 'Interview', 'Training', 'Analysis')),
    is_featured BOOLEAN DEFAULT FALSE,
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Media Likes
CREATE TABLE media_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    media_id UUID REFERENCES media_assets(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(media_id, user_id)
);

-- Interviews
CREATE TABLE interviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    interviewer_name VARCHAR(100) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    video_url TEXT,
    audio_url TEXT,
    transcript TEXT,
    duration INTEGER, -- in seconds
    scheduled_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Press Conferences
CREATE TABLE press_conferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    stream_url TEXT,
    participants JSONB DEFAULT '[]', -- array of fighter IDs
    status VARCHAR(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Live', 'Completed', 'Cancelled')),
    created_by UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Social Links
CREATE TABLE social_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('Twitter', 'Instagram', 'YouTube', 'Twitch', 'TikTok', 'Facebook')),
    url TEXT NOT NULL,
    handle VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Training Camps
CREATE TABLE training_camps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    difficulty VARCHAR(20) NOT NULL CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced', 'Elite')),
    duration_days INTEGER NOT NULL,
    points_reward INTEGER NOT NULL,
    requirements JSONB DEFAULT '[]',
    created_by UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Training Objectives
CREATE TABLE training_objectives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    camp_id UUID REFERENCES training_camps(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('Fitness', 'Technique', 'Strategy', 'Mental')),
    points_reward INTEGER NOT NULL,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Training Logs
CREATE TABLE training_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    camp_id UUID REFERENCES training_camps(id) ON DELETE CASCADE,
    objective_id UUID REFERENCES training_objectives(id) ON DELETE CASCADE,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    proof_url TEXT
);

-- Rivalries
CREATE TABLE rivalries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fighter1_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    fighter2_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    intensity INTEGER DEFAULT 1 CHECK (intensity BETWEEN 1 AND 10),
    reason TEXT,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Resolved', 'Settled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(fighter1_id, fighter2_id)
);

-- News Articles
CREATE TABLE news_articles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    author VARCHAR(100) NOT NULL,
    category VARCHAR(20) NOT NULL CHECK (category IN ('Fight', 'Tournament', 'Ranking', 'General')),
    featured_image_url TEXT,
    is_featured BOOLEAN DEFAULT FALSE,
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Scouting Reports
CREATE TABLE scouting_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scout_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    target_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
    strengths TEXT,
    weaknesses TEXT,
    recommendations TEXT,
    rating INTEGER CHECK (rating BETWEEN 1 AND 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('Match', 'Tournament', 'Tier', 'Dispute', 'Award', 'General')),
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notification Preferences
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    match_notifications BOOLEAN DEFAULT TRUE,
    tournament_notifications BOOLEAN DEFAULT TRUE,
    tier_notifications BOOLEAN DEFAULT TRUE,
    dispute_notifications BOOLEAN DEFAULT TRUE,
    award_notifications BOOLEAN DEFAULT TRUE,
    general_notifications BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Push Tokens
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(10) NOT NULL CHECK (platform IN ('Web', 'iOS', 'Android')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin Logs
CREATE TABLE admin_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(50) NOT NULL,
    target_id UUID NOT NULL,
    details JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System Settings
CREATE TABLE system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(50) NOT NULL UNIQUE,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Achievements
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(50) NOT NULL,
    category VARCHAR(20) NOT NULL CHECK (category IN ('Performance', 'Tournament', 'Special', 'Milestone')),
    rarity VARCHAR(20) NOT NULL CHECK (rarity IN ('Common', 'Rare', 'Epic', 'Legendary')),
    points_required INTEGER,
    fights_required INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Achievements
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

-- Analytics Snapshots
CREATE TABLE analytics_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    total_fighters INTEGER NOT NULL,
    total_fights INTEGER NOT NULL,
    tier_distribution JSONB NOT NULL,
    weight_class_distribution JSONB NOT NULL,
    platform_distribution JSONB NOT NULL,
    dispute_rate DECIMAL(5,2) NOT NULL,
    average_time_to_match DECIMAL(8,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_fighter_profiles_user_id ON fighter_profiles(user_id);
CREATE INDEX idx_fighter_profiles_handle ON fighter_profiles(handle);
CREATE INDEX idx_fighter_profiles_tier ON fighter_profiles(tier);
CREATE INDEX idx_fighter_profiles_weight_class ON fighter_profiles(weight_class);
CREATE INDEX idx_fighter_profiles_points ON fighter_profiles(points DESC);

CREATE INDEX idx_fight_records_fighter_id ON fight_records(fighter_id);
CREATE INDEX idx_fight_records_date ON fight_records(date DESC);

CREATE INDEX idx_rankings_weight_class ON rankings(weight_class);
CREATE INDEX idx_rankings_rank ON rankings(rank);
CREATE INDEX idx_rankings_points ON rankings(points DESC);

CREATE INDEX idx_matchmaking_requests_requester ON matchmaking_requests(requester_id);
CREATE INDEX idx_matchmaking_requests_status ON matchmaking_requests(status);

CREATE INDEX idx_scheduled_fights_fighter1 ON scheduled_fights(fighter1_id);
CREATE INDEX idx_scheduled_fights_fighter2 ON scheduled_fights(fighter2_id);
CREATE INDEX idx_scheduled_fights_date ON scheduled_fights(scheduled_date);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

CREATE INDEX idx_media_assets_fighter_id ON media_assets(fighter_id);
CREATE INDEX idx_media_assets_category ON media_assets(category);

-- Row Level Security (RLS) policies
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE fight_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchmaking_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_assets ENABLE ROW LEVEL SECURITY;

-- Policies for fighter profiles
CREATE POLICY "Users can view all fighter profiles" ON fighter_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own fighter profile" ON fighter_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own fighter profile" ON fighter_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies for fight records
CREATE POLICY "Users can view all fight records" ON fight_records
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own fight records" ON fight_records
    FOR INSERT WITH CHECK (auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id));

-- Policies for notifications
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Functions for automatic updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_fighter_profiles_updated_at BEFORE UPDATE ON fighter_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate points for a fight
CREATE OR REPLACE FUNCTION calculate_fight_points(
    result VARCHAR,
    method VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    base_points INTEGER;
    ko_bonus INTEGER := 0;
BEGIN
    -- Base points
    CASE result
        WHEN 'Win' THEN base_points := 5;
        WHEN 'Loss' THEN base_points := -2;
        WHEN 'Draw' THEN base_points := 0;
        ELSE base_points := 0;
    END CASE;
    
    -- KO bonus
    IF method IN ('KO', 'TKO') THEN
        ko_bonus := 3;
    END IF;
    
    RETURN base_points + ko_bonus;
END;
$$ LANGUAGE plpgsql;

-- Function to update fighter stats after a fight
CREATE OR REPLACE FUNCTION update_fighter_stats()
RETURNS TRIGGER AS $$
DECLARE
    fighter_points INTEGER;
    total_fights INTEGER;
    win_percentage DECIMAL(5,2);
    ko_percentage DECIMAL(5,2);
BEGIN
    -- Get current fighter stats
    SELECT points, (wins + losses + draws) INTO fighter_points, total_fights
    FROM fighter_profiles 
    WHERE id = NEW.fighter_id;
    
    -- Update wins/losses/draws/knockouts
    UPDATE fighter_profiles SET
        wins = CASE WHEN NEW.result = 'Win' THEN wins + 1 ELSE wins END,
        losses = CASE WHEN NEW.result = 'Loss' THEN losses + 1 ELSE losses END,
        draws = CASE WHEN NEW.result = 'Draw' THEN draws + 1 ELSE draws END,
        knockouts = CASE WHEN NEW.method IN ('KO', 'TKO') THEN knockouts + 1 ELSE knockouts END,
        points = points + NEW.points_earned
    WHERE id = NEW.fighter_id;
    
    -- Calculate percentages
    SELECT 
        CASE WHEN (wins + losses + draws) > 0 
            THEN (wins::DECIMAL / (wins + losses + draws) * 100) 
            ELSE 0 
        END,
        CASE WHEN wins > 0 
            THEN (knockouts::DECIMAL / wins * 100) 
            ELSE 0 
        END
    INTO win_percentage, ko_percentage
    FROM fighter_profiles 
    WHERE id = NEW.fighter_id;
    
    -- Update percentages
    UPDATE fighter_profiles SET
        win_percentage = win_percentage,
        ko_percentage = ko_percentage
    WHERE id = NEW.fighter_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update fighter stats when a fight record is added
CREATE TRIGGER update_fighter_stats_trigger
    AFTER INSERT ON fight_records
    FOR EACH ROW EXECUTE FUNCTION update_fighter_stats();

-- Insert default tiers
INSERT INTO tiers (name, min_points, max_points, color, description) VALUES
('Amateur', 0, 49, '#808080', 'Starting tier for new fighters'),
('Semi-Pro', 50, 99, '#4CAF50', 'Intermediate tier for developing fighters'),
('Pro', 100, 199, '#2196F3', 'Professional tier for experienced fighters'),
('Contender', 200, 299, '#FF9800', 'Elite tier for championship contenders'),
('Elite', 300, NULL, '#9C27B0', 'Highest tier for the best fighters');

-- Insert default achievements
INSERT INTO achievements (name, description, icon, category, rarity, points_required) VALUES
('First Victory', 'Win your first fight', '🥊', 'Milestone', 'Common', 5),
('Knockout Artist', 'Win 10 fights by knockout', '💥', 'Performance', 'Rare', 50),
('Undefeated', 'Win 10 fights in a row', '👑', 'Performance', 'Epic', 50),
('Fight of the Night', 'Participate in a Fight of the Night', '⭐', 'Special', 'Rare', 0),
('Tournament Champion', 'Win a tournament', '🏆', 'Tournament', 'Legendary', 0),
('Elite Fighter', 'Reach Elite tier', '💎', 'Milestone', 'Legendary', 150);

-- Insert default system settings
INSERT INTO system_settings (key, value, description) VALUES
('matchmaking_enabled', 'true', 'Enable/disable matchmaking system'),
('tier_promotion_threshold', '50', 'Points required for tier promotion'),
('tier_demotion_threshold', '4', 'Consecutive losses before tier demotion'),
('dispute_timeout_hours', '24', 'Hours before dispute auto-resolution'),
('tournament_entry_fee_percentage', '0.1', 'Percentage of prize pool as entry fee'),
('max_fighters_per_tournament', '32', 'Maximum fighters allowed in tournaments'),
('notification_retention_days', '30', 'Days to keep notifications'),
('analytics_snapshot_frequency', 'daily', 'How often to create analytics snapshots');
