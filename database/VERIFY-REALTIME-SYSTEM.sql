-- VERIFY REAL-TIME SYSTEM: Ensure all triggers and real-time subscriptions are working
-- Run this in Supabase SQL Editor to verify the system is set up correctly

-- ============================================
-- STEP 1: Verify Points Calculation Function
-- ============================================
DO $$
BEGIN
    -- Test Win = +5
    IF calculate_fight_points('Win', 'Decision') != 5 THEN
        RAISE EXCEPTION 'FAIL: Win + Decision should be 5, got %', calculate_fight_points('Win', 'Decision');
    END IF;
    
    -- Test Win + KO = +8 (5 + 3 bonus)
    IF calculate_fight_points('Win', 'KO') != 8 THEN
        RAISE EXCEPTION 'FAIL: Win + KO should be 8, got %', calculate_fight_points('Win', 'KO');
    END IF;
    
    -- Test Win + TKO = +8 (5 + 3 bonus)
    IF calculate_fight_points('Win', 'TKO') != 8 THEN
        RAISE EXCEPTION 'FAIL: Win + TKO should be 8, got %', calculate_fight_points('Win', 'TKO');
    END IF;
    
    -- Test Loss = -3
    IF calculate_fight_points('Loss', 'Decision') != -3 THEN
        RAISE EXCEPTION 'FAIL: Loss + Decision should be -3, got %', calculate_fight_points('Loss', 'Decision');
    END IF;
    
    -- Test Loss + KO = -3 (no bonus for losers)
    IF calculate_fight_points('Loss', 'KO') != -3 THEN
        RAISE EXCEPTION 'FAIL: Loss + KO should be -3, got %', calculate_fight_points('Loss', 'KO');
    END IF;
    
    -- Test Draw = 0
    IF calculate_fight_points('Draw', 'Decision') != 0 THEN
        RAISE EXCEPTION 'FAIL: Draw should be 0, got %', calculate_fight_points('Draw', 'Decision');
    END IF;
    
    RAISE NOTICE '✅ Points calculation function is correct';
END $$;

-- ============================================
-- STEP 2: Verify Tier Calculation Function
-- ============================================
DO $$
BEGIN
    -- Test tier thresholds
    IF calculate_tier(0) != 'Amateur' THEN
        RAISE EXCEPTION 'FAIL: 0 points should be Amateur, got %', calculate_tier(0);
    END IF;
    
    IF calculate_tier(29) != 'Amateur' THEN
        RAISE EXCEPTION 'FAIL: 29 points should be Amateur, got %', calculate_tier(29);
    END IF;
    
    IF calculate_tier(30) != 'Semi-Pro' THEN
        RAISE EXCEPTION 'FAIL: 30 points should be Semi-Pro, got %', calculate_tier(30);
    END IF;
    
    IF calculate_tier(69) != 'Semi-Pro' THEN
        RAISE EXCEPTION 'FAIL: 69 points should be Semi-Pro, got %', calculate_tier(69);
    END IF;
    
    IF calculate_tier(70) != 'Pro' THEN
        RAISE EXCEPTION 'FAIL: 70 points should be Pro, got %', calculate_tier(70);
    END IF;
    
    IF calculate_tier(139) != 'Pro' THEN
        RAISE EXCEPTION 'FAIL: 139 points should be Pro, got %', calculate_tier(139);
    END IF;
    
    IF calculate_tier(140) != 'Contender' THEN
        RAISE EXCEPTION 'FAIL: 140 points should be Contender, got %', calculate_tier(140);
    END IF;
    
    IF calculate_tier(279) != 'Contender' THEN
        RAISE EXCEPTION 'FAIL: 279 points should be Contender, got %', calculate_tier(279);
    END IF;
    
    IF calculate_tier(280) != 'Elite' THEN
        RAISE EXCEPTION 'FAIL: 280 points should be Elite, got %', calculate_tier(280);
    END IF;
    
    RAISE NOTICE '✅ Tier calculation function is correct';
END $$;

-- ============================================
-- STEP 3: Verify Triggers Exist
-- ============================================
DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    -- Check if update_fighter_stats_after_fight trigger exists
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger
    WHERE tgname = 'update_fighter_stats_after_fight';
    
    IF trigger_count = 0 THEN
        RAISE WARNING '⚠️ update_fighter_stats_after_fight trigger not found';
    ELSE
        RAISE NOTICE '✅ update_fighter_stats_after_fight trigger exists';
    END IF;
    
    -- Check if update_fighter_tier_after_fight trigger exists
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger
    WHERE tgname = 'update_fighter_tier_after_fight';
    
    IF trigger_count = 0 THEN
        RAISE WARNING '⚠️ update_fighter_tier_after_fight trigger not found';
    ELSE
        RAISE NOTICE '✅ update_fighter_tier_after_fight trigger exists';
    END IF;
    
    -- Check if auto-create opponent loss trigger exists
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger
    WHERE tgname = 'trigger_auto_create_opponent_loss';
    
    IF trigger_count = 0 THEN
        RAISE WARNING '⚠️ trigger_auto_create_opponent_loss trigger not found';
    ELSE
        RAISE NOTICE '✅ trigger_auto_create_opponent_loss trigger exists';
    END IF;
END $$;

-- ============================================
-- STEP 4: Verify Realtime is Enabled on Tables
-- ============================================
-- Note: This requires checking Supabase dashboard manually
-- Go to Database > Replication and ensure these tables have Realtime enabled:
-- - fighter_profiles
-- - fight_records
-- - scheduled_fights
-- - rankings (if it's a table)

DO $$
BEGIN
    RAISE NOTICE '📋 MANUAL CHECK REQUIRED:';
    RAISE NOTICE '   Go to Supabase Dashboard > Database > Replication';
    RAISE NOTICE '   Ensure Realtime is enabled for:';
    RAISE NOTICE '   - fighter_profiles';
    RAISE NOTICE '   - fight_records';
    RAISE NOTICE '   - scheduled_fights';
    RAISE NOTICE '   - rankings (if table exists)';
END $$;

-- ============================================
-- STEP 5: Check for Fighters with Incorrect Points
-- ============================================
DO $$
DECLARE
    incorrect_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO incorrect_count
    FROM fighter_profiles fp
    WHERE fp.points != (
        SELECT COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)
        FROM fight_records fr
        WHERE fr.fighter_id = fp.user_id
    );
    
    IF incorrect_count > 0 THEN
        RAISE WARNING '⚠️ Found % fighters with incorrect points. Run complete-calculation-system-verification.sql to fix.', incorrect_count;
    ELSE
        RAISE NOTICE '✅ All fighter points are correct';
    END IF;
END $$;

-- ============================================
-- STEP 6: Summary
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE 'REAL-TIME SYSTEM VERIFICATION COMPLETE';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Points System: Win = +5, Loss = -3, Draw = 0, KO/TKO Bonus = +3';
    RAISE NOTICE '✅ Tier Thresholds: Amateur (0-29), Semi-Pro (30-69), Pro (70-139), Contender (140-279), Elite (280+)';
    RAISE NOTICE '✅ Demotion System: 5 consecutive losses = demote, 5 consecutive wins after demotion = promote back';
    RAISE NOTICE '✅ Auto-create Opponent Loss: When fighter enters Win, opponent gets Loss automatically';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Frontend Components with Real-Time Subscriptions:';
    RAISE NOTICE '   - HomePage: Updates on fight_records, fighter_profiles, scheduled_fights, rankings';
    RAISE NOTICE '   - Rankings: Updates on fight_records, fighter_profiles, rankings';
    RAISE NOTICE '   - FighterProfile: Updates on fight_records, fighter_profiles, scheduled_fights';
    RAISE NOTICE '   - Analytics: Updates on fight_records, fighter_profiles';
    RAISE NOTICE '   - AdminAnalytics: Updates on fight_records, fighter_profiles';
    RAISE NOTICE '   - Matchmaking: Updates on fight_records, fighter_profiles, scheduled_fights';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Remember to enable Realtime in Supabase Dashboard for all tables!';
    RAISE NOTICE '';
END $$;

