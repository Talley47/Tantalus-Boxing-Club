-- Migration script to add missing columns to news_announcements table
-- Run this if you get errors about missing columns like is_published

DO $$
BEGIN
    -- Add author_title column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'news_announcements' AND column_name = 'author_title'
    ) THEN
        ALTER TABLE news_announcements
        ADD COLUMN author_title VARCHAR(100) DEFAULT 'TBC News Reporter';
    END IF;

    -- Add images column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'news_announcements' AND column_name = 'images'
    ) THEN
        ALTER TABLE news_announcements
        ADD COLUMN images JSONB DEFAULT '[]';
    END IF;

    -- Add featured_image column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'news_announcements' AND column_name = 'featured_image'
    ) THEN
        ALTER TABLE news_announcements
        ADD COLUMN featured_image TEXT;
    END IF;

    -- Add tags column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'news_announcements' AND column_name = 'tags'
    ) THEN
        ALTER TABLE news_announcements
        ADD COLUMN tags TEXT[];
    END IF;

    -- Add is_featured column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'news_announcements' AND column_name = 'is_featured'
    ) THEN
        ALTER TABLE news_announcements
        ADD COLUMN is_featured BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add is_published column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'news_announcements' AND column_name = 'is_published'
    ) THEN
        ALTER TABLE news_announcements
        ADD COLUMN is_published BOOLEAN DEFAULT TRUE;
        
        -- Update existing rows to be published
        UPDATE news_announcements SET is_published = TRUE WHERE is_published IS NULL;
    END IF;

    -- Add published_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'news_announcements' AND column_name = 'published_at'
    ) THEN
        ALTER TABLE news_announcements
        ADD COLUMN published_at TIMESTAMP WITH TIME ZONE;
        
        -- Set published_at for existing published items
        UPDATE news_announcements 
        SET published_at = created_at 
        WHERE published_at IS NULL AND is_published = TRUE;
    END IF;

    -- Add created_by column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'news_announcements' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE news_announcements
        ADD COLUMN created_by UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL;
    END IF;

    -- Update type constraint to include 'blog' and 'fight_result'
    -- First, drop the existing constraint if it exists
    ALTER TABLE news_announcements DROP CONSTRAINT IF EXISTS news_announcements_type_check;
    
    -- Add the new constraint with all types
    ALTER TABLE news_announcements
    ADD CONSTRAINT news_announcements_type_check 
    CHECK (type IN ('news', 'announcement', 'blog', 'fight_result'));
END $$;

-- Ensure the news_fight_results table exists
CREATE TABLE IF NOT EXISTS news_fight_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    news_id UUID REFERENCES news_announcements(id) ON DELETE CASCADE,
    fight_id UUID REFERENCES scheduled_fights(id) ON DELETE SET NULL,
    fighter1_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    fighter2_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    winner_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    result_method VARCHAR(50),
    round INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_news_announcements_type ON news_announcements(type);
CREATE INDEX IF NOT EXISTS idx_news_announcements_published ON news_announcements(is_published, published_at);
CREATE INDEX IF NOT EXISTS idx_news_announcements_featured ON news_announcements(is_featured);
CREATE INDEX IF NOT EXISTS idx_news_announcements_created ON news_announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_fight_results_news ON news_fight_results(news_id);

-- Update RLS policies to use is_published
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT USING (is_published = TRUE);

