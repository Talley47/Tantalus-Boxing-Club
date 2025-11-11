-- Tantalus Boxing Club Database Schema - INCREMENTAL VERSION
-- This script only creates tables that don't already exist
-- Run this if you get "relation already exists" errors

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Check and create tables only if they don't exist
DO $$
BEGIN
    -- Create tiers table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tiers') THEN
        CREATE TABLE tiers (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(20) NOT NULL UNIQUE,
            min_points INTEGER NOT NULL,
            max_points INTEGER,
            color VARCHAR(7) NOT NULL, -- hex color
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;

    -- Create tier_history table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tier_history') THEN
        CREATE TABLE tier_history (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
            from_tier VARCHAR(20) NOT NULL,
            to_tier VARCHAR(20) NOT NULL,
            reason VARCHAR(50) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;

    -- Create fighter_profiles table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fighter_profiles') THEN
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
    END IF;

    -- Create fight_records table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fight_records') THEN
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
    END IF;

    -- Create rankings table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rankings') THEN
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
    END IF;

    -- Create matchmaking_requests table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'matchmaking_requests') THEN
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
    END IF;

    -- Create scheduled_fights table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scheduled_fights') THEN
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
    END IF;

    -- Create disputes table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'disputes') THEN
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
    END IF;

    -- Create tournaments table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tournaments') THEN
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
    END IF;

    -- Create tournament_participants table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tournament_participants') THEN
        CREATE TABLE tournament_participants (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
            fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
            seed INTEGER,
            status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Eliminated', 'Withdrawn')),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(tournament_id, fighter_id)
        );
    END IF;

    -- Create tournament_brackets table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tournament_brackets') THEN
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
    END IF;

    -- Create title_belts table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'title_belts') THEN
        CREATE TABLE title_belts (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            weight_class VARCHAR(30) NOT NULL,
            current_champion_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
            belt_name VARCHAR(100) NOT NULL,
            defense_requirement INTEGER DEFAULT 3, -- fights before mandatory defense
            last_defense TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;

    -- Create title_history table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'title_history') THEN
        CREATE TABLE title_history (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            belt_id UUID REFERENCES title_belts(id) ON DELETE CASCADE,
            champion_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
            won_date TIMESTAMP WITH TIME ZONE NOT NULL,
            lost_date TIMESTAMP WITH TIME ZONE,
            defense_count INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;

    -- Create events table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'events') THEN
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
    END IF;

    -- Create media_assets table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'media_assets') THEN
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
    END IF;

    -- Create media_likes table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'media_likes') THEN
        CREATE TABLE media_likes (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            media_id UUID REFERENCES media_assets(id) ON DELETE CASCADE,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(media_id, user_id)
        );
    END IF;

    -- Create interviews table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'interviews') THEN
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
    END IF;

    -- Create press_conferences table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'press_conferences') THEN
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
    END IF;

    -- Create social_links table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'social_links') THEN
        CREATE TABLE social_links (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
            platform VARCHAR(20) NOT NULL CHECK (platform IN ('Twitter', 'Instagram', 'YouTube', 'Twitch', 'TikTok', 'Facebook')),
            url TEXT NOT NULL,
            handle VARCHAR(100),
            is_verified BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;

    -- Create training_camps table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'training_camps') THEN
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
    END IF;

    -- Create training_objectives table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'training_objectives') THEN
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
    END IF;

    -- Create training_logs table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'training_logs') THEN
        CREATE TABLE training_logs (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            fighter_id UUID REFERENCES fighter_profiles(id) ON DELETE CASCADE,
            camp_id UUID REFERENCES training_camps(id) ON DELETE CASCADE,
            objective_id UUID REFERENCES training_objectives(id) ON DELETE CASCADE,
            completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            notes TEXT,
            proof_url TEXT
        );
    END IF;

    -- Create rivalries table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rivalries') THEN
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
    END IF;

    -- Create news_articles table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'news_articles') THEN
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
    END IF;

    -- Create scouting_reports table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scouting_reports') THEN
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
    END IF;

    -- Create notifications table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications') THEN
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
    END IF;

    -- Create notification_preferences table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notification_preferences') THEN
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
    END IF;

    -- Create push_tokens table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'push_tokens') THEN
        CREATE TABLE push_tokens (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            token TEXT NOT NULL,
            platform VARCHAR(10) NOT NULL CHECK (platform IN ('Web', 'iOS', 'Android')),
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;

    -- Create admin_logs table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_logs') THEN
        CREATE TABLE admin_logs (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            admin_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            action VARCHAR(100) NOT NULL,
            target_type VARCHAR(50) NOT NULL,
            target_id UUID NOT NULL,
            details JSONB NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;

    -- Create system_settings table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings') THEN
        CREATE TABLE system_settings (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            key VARCHAR(50) NOT NULL UNIQUE,
            value JSONB NOT NULL,
            description TEXT,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_by UUID REFERENCES auth.users(id) ON DELETE CASCADE
        );
    END IF;

    -- Create achievements table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'achievements') THEN
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
    END IF;

    -- Create user_achievements table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_achievements') THEN
        CREATE TABLE user_achievements (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE,
            unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(user_id, achievement_id)
        );
    END IF;

    -- Create analytics_snapshots table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analytics_snapshots') THEN
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
    END IF;

END $$;

-- Create indexes for performance (only if they don't exist)
DO $$
BEGIN
    -- Create indexes if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fighter_profiles_user_id') THEN
        CREATE INDEX idx_fighter_profiles_user_id ON fighter_profiles(user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fighter_profiles_handle') THEN
        CREATE INDEX idx_fighter_profiles_handle ON fighter_profiles(handle);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fighter_profiles_tier') THEN
        CREATE INDEX idx_fighter_profiles_tier ON fighter_profiles(tier);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fighter_profiles_weight_class') THEN
        CREATE INDEX idx_fighter_profiles_weight_class ON fighter_profiles(weight_class);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fighter_profiles_points') THEN
        CREATE INDEX idx_fighter_profiles_points ON fighter_profiles(points DESC);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fight_records_fighter_id') THEN
        CREATE INDEX idx_fight_records_fighter_id ON fight_records(fighter_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_fight_records_date') THEN
        CREATE INDEX idx_fight_records_date ON fight_records(date DESC);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_rankings_weight_class') THEN
        CREATE INDEX idx_rankings_weight_class ON rankings(weight_class);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_rankings_rank') THEN
        CREATE INDEX idx_rankings_rank ON rankings(rank);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_rankings_points') THEN
        CREATE INDEX idx_rankings_points ON rankings(points DESC);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_matchmaking_requests_requester') THEN
        CREATE INDEX idx_matchmaking_requests_requester ON matchmaking_requests(requester_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_matchmaking_requests_status') THEN
        CREATE INDEX idx_matchmaking_requests_status ON matchmaking_requests(status);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_scheduled_fights_fighter1') THEN
        CREATE INDEX idx_scheduled_fights_fighter1 ON scheduled_fights(fighter1_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_scheduled_fights_fighter2') THEN
        CREATE INDEX idx_scheduled_fights_fighter2 ON scheduled_fights(fighter2_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_scheduled_fights_date') THEN
        CREATE INDEX idx_scheduled_fights_date ON scheduled_fights(scheduled_date);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_notifications_user_id') THEN
        CREATE INDEX idx_notifications_user_id ON notifications(user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_notifications_is_read') THEN
        CREATE INDEX idx_notifications_is_read ON notifications(is_read);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_media_assets_fighter_id') THEN
        CREATE INDEX idx_media_assets_fighter_id ON media_assets(fighter_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_media_assets_category') THEN
        CREATE INDEX idx_media_assets_category ON media_assets(category);
    END IF;
END $$;

-- Enable Row Level Security (RLS) policies
DO $$
BEGIN
    -- Enable RLS on tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fighter_profiles') THEN
        ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fight_records') THEN
        ALTER TABLE fight_records ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'matchmaking_requests') THEN
        ALTER TABLE matchmaking_requests ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scheduled_fights') THEN
        ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications') THEN
        ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'media_assets') THEN
        ALTER TABLE media_assets ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Create RLS policies (only if they don't exist)
DO $$
BEGIN
    -- Policies for fighter profiles
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fighter_profiles' AND policyname = 'Users can view all fighter profiles') THEN
        CREATE POLICY "Users can view all fighter profiles" ON fighter_profiles
            FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fighter_profiles' AND policyname = 'Users can update their own fighter profile') THEN
        CREATE POLICY "Users can update their own fighter profile" ON fighter_profiles
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fighter_profiles' AND policyname = 'Users can insert their own fighter profile') THEN
        CREATE POLICY "Users can insert their own fighter profile" ON fighter_profiles
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    
    -- Policies for fight records
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fight_records' AND policyname = 'Users can view all fight records') THEN
        CREATE POLICY "Users can view all fight records" ON fight_records
            FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fight_records' AND policyname = 'Users can insert their own fight records') THEN
        CREATE POLICY "Users can insert their own fight records" ON fight_records
            FOR INSERT WITH CHECK (auth.uid() = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id));
    END IF;
    
    -- Policies for notifications
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can view their own notifications') THEN
        CREATE POLICY "Users can view their own notifications" ON notifications
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can update their own notifications') THEN
        CREATE POLICY "Users can update their own notifications" ON notifications
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Create functions for automatic updates (only if they don't exist)
DO $$
BEGIN
    -- Function to update updated_at column
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ language 'plpgsql';
    END IF;
    
    -- Function to calculate points for a fight
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'calculate_fight_points') THEN
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
    END IF;
    
    -- Function to update fighter stats after a fight
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_fighter_stats') THEN
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
    END IF;
END $$;

-- Create triggers (only if they don't exist)
DO $$
BEGIN
    -- Trigger for updated_at
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_fighter_profiles_updated_at') THEN
        CREATE TRIGGER update_fighter_profiles_updated_at BEFORE UPDATE ON fighter_profiles
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    -- Trigger to update fighter stats when a fight record is added
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_fighter_stats_trigger') THEN
        CREATE TRIGGER update_fighter_stats_trigger
            AFTER INSERT ON fight_records
            FOR EACH ROW EXECUTE FUNCTION update_fighter_stats();
    END IF;
END $$;

-- Insert default data (only if not already present)
DO $$
BEGIN
    -- Insert default tiers if they don't exist
    IF NOT EXISTS (SELECT 1 FROM tiers WHERE name = 'Amateur') THEN
        INSERT INTO tiers (name, min_points, max_points, color, description) VALUES
        ('Amateur', 0, 49, '#808080', 'Starting tier for new fighters'),
        ('Semi-Pro', 50, 99, '#4CAF50', 'Intermediate tier for developing fighters'),
        ('Pro', 100, 199, '#2196F3', 'Professional tier for experienced fighters'),
        ('Contender', 200, 299, '#FF9800', 'Elite tier for championship contenders'),
        ('Elite', 300, NULL, '#9C27B0', 'Highest tier for the best fighters');
    END IF;
    
    -- Insert default achievements if they don't exist
    IF NOT EXISTS (SELECT 1 FROM achievements WHERE name = 'First Victory') THEN
        INSERT INTO achievements (name, description, icon, category, rarity, points_required) VALUES
        ('First Victory', 'Win your first fight', '🥊', 'Milestone', 'Common', 5),
        ('Knockout Artist', 'Win 10 fights by knockout', '💥', 'Performance', 'Rare', 50),
        ('Undefeated', 'Win 10 fights in a row', '👑', 'Performance', 'Epic', 50),
        ('Fight of the Night', 'Participate in a Fight of the Night', '⭐', 'Special', 'Rare', 0),
        ('Tournament Champion', 'Win a tournament', '🏆', 'Tournament', 'Legendary', 0),
        ('Elite Fighter', 'Reach Elite tier', '💎', 'Milestone', 'Legendary', 150);
    END IF;
    
    -- Insert default system settings if they don't exist
    IF NOT EXISTS (SELECT 1 FROM system_settings WHERE key = 'matchmaking_enabled') THEN
        INSERT INTO system_settings (key, value, description) VALUES
        ('matchmaking_enabled', 'true', 'Enable/disable matchmaking system'),
        ('tier_promotion_threshold', '50', 'Points required for tier promotion'),
        ('tier_demotion_threshold', '4', 'Consecutive losses before tier demotion'),
        ('dispute_timeout_hours', '24', 'Hours before dispute auto-resolution'),
        ('tournament_entry_fee_percentage', '0.1', 'Percentage of prize pool as entry fee'),
        ('max_fighters_per_tournament', '32', 'Maximum fighters allowed in tournaments'),
        ('notification_retention_days', '30', 'Days to keep notifications'),
        ('analytics_snapshot_frequency', 'daily', 'How often to create analytics snapshots');
    END IF;
END $$;
