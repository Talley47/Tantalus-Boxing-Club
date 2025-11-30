-- DIAGNOSE: Check why news items are not showing on home page
-- Run this in Supabase SQL Editor to diagnose the issue

-- Step 1: Check if news_announcements table exists and has data
DO $$
DECLARE
    news_count INTEGER;
    published_count INTEGER;
    unpublished_count INTEGER;
BEGIN
    -- Count total news items
    SELECT COUNT(*) INTO news_count FROM news_announcements;
    
    -- Count published news items
    SELECT COUNT(*) INTO published_count 
    FROM news_announcements 
    WHERE is_published = TRUE;
    
    -- Count unpublished news items
    SELECT COUNT(*) INTO unpublished_count 
    FROM news_announcements 
    WHERE is_published = FALSE OR is_published IS NULL;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'NEWS ITEMS DIAGNOSIS';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total news items in database: %', news_count;
    RAISE NOTICE 'Published news items (is_published = TRUE): %', published_count;
    RAISE NOTICE 'Unpublished news items (is_published = FALSE or NULL): %', unpublished_count;
    RAISE NOTICE '========================================';
    
    IF news_count = 0 THEN
        RAISE WARNING '❌ No news items found in database!';
        RAISE NOTICE '   → Admin needs to create news items in Admin Panel';
    ELSIF published_count = 0 THEN
        RAISE WARNING '❌ No published news items found!';
        RAISE NOTICE '   → All news items are unpublished (is_published = FALSE)';
        RAISE NOTICE '   → Admin needs to publish news items or set is_published = TRUE';
    ELSE
        RAISE NOTICE '✅ Found % published news items', published_count;
    END IF;
END $$;

-- Step 2: Show recent news items (last 10)
SELECT 
    id,
    title,
    type,
    is_published,
    created_at,
    published_at,
    CASE 
        WHEN is_published = TRUE THEN '✅ Published'
        WHEN is_published = FALSE THEN '❌ Unpublished'
        ELSE '⚠️  NULL'
    END as status
FROM news_announcements
ORDER BY created_at DESC
LIMIT 10;

-- Step 3: Check RLS policies
DO $$
DECLARE
    policy_count INTEGER;
    policy_record RECORD;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'news_announcements';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RLS POLICIES CHECK';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total RLS policies on news_announcements: %', policy_count;
    RAISE NOTICE '';
    
    IF policy_count = 0 THEN
        RAISE WARNING '❌ No RLS policies found! This will block all access.';
    ELSE
        RAISE NOTICE 'RLS Policies:';
        FOR policy_record IN
            SELECT policyname, cmd, qual, with_check
            FROM pg_policies
            WHERE schemaname = 'public'
              AND tablename = 'news_announcements'
            ORDER BY cmd, policyname
        LOOP
            RAISE NOTICE '  - % (%): %', 
                policy_record.policyname, 
                policy_record.cmd,
                COALESCE(policy_record.qual, policy_record.with_check, 'No condition');
        END LOOP;
    END IF;
END $$;

-- Step 4: Test query as authenticated user (simulate what frontend does)
-- This will show what the frontend query would return
DO $$
DECLARE
    test_result RECORD;
    result_count INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TEST QUERY (as authenticated user)';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Simulating: SELECT * FROM news_announcements WHERE is_published = TRUE';
    RAISE NOTICE '';
    
    -- Count what would be returned
    SELECT COUNT(*) INTO result_count
    FROM news_announcements
    WHERE is_published = TRUE;
    
    RAISE NOTICE 'News items that would be returned: %', result_count;
    
    IF result_count = 0 THEN
        RAISE WARNING '❌ Query returns 0 results!';
        RAISE NOTICE '   → Check if news items have is_published = TRUE';
        RAISE NOTICE '   → Check RLS policies are not blocking access';
    ELSE
        RAISE NOTICE '✅ Query would return % news items', result_count;
    END IF;
END $$;

-- Step 5: Check if is_published column exists
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'news_announcements' 
          AND column_name = 'is_published'
    ) INTO column_exists;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COLUMN CHECK';
    RAISE NOTICE '========================================';
    
    IF column_exists THEN
        RAISE NOTICE '✅ is_published column exists';
    ELSE
        RAISE WARNING '❌ is_published column does NOT exist!';
        RAISE NOTICE '   → This will cause query errors';
        RAISE NOTICE '   → Run news-announcements-schema.sql to add the column';
    END IF;
END $$;

-- Step 6: Recommendations
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RECOMMENDATIONS';
    RAISE NOTICE '========================================';
    RAISE NOTICE '1. If no news items exist:';
    RAISE NOTICE '   → Login as Admin';
    RAISE NOTICE '   → Go to Admin Panel → Content Management → News Management';
    RAISE NOTICE '   → Create a new news item';
    RAISE NOTICE '   → Make sure "Published" toggle is ON (is_published = TRUE)';
    RAISE NOTICE '';
    RAISE NOTICE '2. If news items exist but are unpublished:';
    RAISE NOTICE '   → Edit existing news items';
    RAISE NOTICE '   → Set is_published = TRUE';
    RAISE NOTICE '';
    RAISE NOTICE '3. If RLS policies are blocking:';
    RAISE NOTICE '   → Run fix-news-rls-policy.sql';
    RAISE NOTICE '   → Or run FIX-NEWS-500-ERROR-SIMPLE.sql';
    RAISE NOTICE '';
    RAISE NOTICE '4. If is_published column is missing:';
    RAISE NOTICE '   → Run news-announcements-schema.sql';
    RAISE NOTICE '========================================';
END $$;

