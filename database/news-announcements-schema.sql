-- News & Announcements Schema for TBC Promotions
-- Supports News, Announcements, Blogs with unlimited text and images

-- News and Announcements table
CREATE TABLE IF NOT EXISTS news_announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL, -- Unlimited text support
    author VARCHAR(100) NOT NULL DEFAULT 'Mike Glove',
    author_title VARCHAR(100) DEFAULT 'TBC News Reporter',
    type VARCHAR(20) NOT NULL CHECK (type IN ('news', 'announcement', 'blog', 'fight_result')),
    priority VARCHAR(10) DEFAULT 'low' CHECK (priority IN ('high', 'medium', 'low')),
    images JSONB DEFAULT '[]', -- Array of image URLs/paths
    featured_image TEXT, -- Main featured image URL
    tags TEXT[], -- Array of tags for categorization
    is_featured BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT TRUE,
    published_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fight results for news posts
CREATE TABLE IF NOT EXISTS news_fight_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    news_id UUID REFERENCES news_announcements(id) ON DELETE CASCADE,
    fight_id UUID REFERENCES scheduled_fights(id) ON DELETE SET NULL,
    fighter1_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    fighter2_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    winner_id UUID REFERENCES fighter_profiles(id) ON DELETE SET NULL,
    result_method VARCHAR(50), -- KO, Decision, etc.
    round INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_news_announcements_type ON news_announcements(type);
CREATE INDEX IF NOT EXISTS idx_news_announcements_published ON news_announcements(is_published, published_at);
CREATE INDEX IF NOT EXISTS idx_news_announcements_featured ON news_announcements(is_featured);
CREATE INDEX IF NOT EXISTS idx_news_announcements_created ON news_announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_fight_results_news ON news_fight_results(news_id);

-- RLS Policies
ALTER TABLE news_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE news_fight_results ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Public read published news" ON news_announcements;
    DROP POLICY IF EXISTS "Admin manage news" ON news_announcements;
    DROP POLICY IF EXISTS "Public read fight results" ON news_fight_results;
    DROP POLICY IF EXISTS "Admin manage fight results" ON news_fight_results;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Public read access for published news
CREATE POLICY "Public read published news" ON news_announcements
    FOR SELECT USING (is_published = TRUE);

-- Admin write access for news
CREATE POLICY "Admin manage news" ON news_announcements
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM fighter_profiles fp
            JOIN auth.users u ON fp.user_id = u.id
            WHERE fp.id = (SELECT id FROM fighter_profiles WHERE user_id = auth.uid() LIMIT 1)
            AND u.email LIKE '%@admin.tantalus%'
        )
    );

-- Public read access for fight results
CREATE POLICY "Public read fight results" ON news_fight_results
    FOR SELECT USING (true);

-- Admin write access for fight results
CREATE POLICY "Admin manage fight results" ON news_fight_results
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM fighter_profiles fp
            JOIN auth.users u ON fp.user_id = u.id
            WHERE fp.id = (SELECT id FROM fighter_profiles WHERE user_id = auth.uid() LIMIT 1)
            AND u.email LIKE '%@admin.tantalus%'
        )
    );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_news_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_news_updated_at_trigger ON news_announcements;
CREATE TRIGGER update_news_updated_at_trigger
    BEFORE UPDATE ON news_announcements
    FOR EACH ROW
    EXECUTE FUNCTION update_news_updated_at();

-- Function to auto-publish when created (if not specified)
CREATE OR REPLACE FUNCTION set_news_published_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.published_at IS NULL AND NEW.is_published = TRUE THEN
        NEW.published_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-set published_at
DROP TRIGGER IF EXISTS set_news_published_at_trigger ON news_announcements;
CREATE TRIGGER set_news_published_at_trigger
    BEFORE INSERT ON news_announcements
    FOR EACH ROW
    EXECUTE FUNCTION set_news_published_at();

