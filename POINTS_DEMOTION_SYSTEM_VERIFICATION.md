# Points & Demotion System Verification

## ✅ System Requirements

### Point System
- **Win** = +5 points
- **Loss** = -3 points
- **Draw** = 0 points
- **KO/TKO Bonus** = +3 points (only for winners)
  - Win by Decision = 5 points
  - Win by KO/TKO = 8 points (5 + 3)
  - Loss = -3 points (regardless of method)
  - Draw = 0 points

### Tiebreakers (in order)
1. **Head-to-head** - If fighters have fought, use their record against each other
2. **KO Percentage** - Higher KO% ranks higher
3. **Strength of Opponent** - Average opponent points (higher = better)
4. **Recent Form** - Last 5 results (W/L/D pattern)
5. **Win Percentage** - Final tiebreaker

### Demotion System
- **Automatic Demotion**: 5 consecutive losses = demote one tier
- **Promotion Back**: After demotion, must win 5 consecutive fights to be promoted back
- **Tier Progression**: Amateur → Semi-Pro → Pro → Contender → Elite
- **Warning Indicator**: 3+ consecutive losses = red warning indicator (!) next to fighter's name

### Tier Thresholds
- **Amateur**: ≤29 points
- **Semi-Pro**: 30-69 points
- **Pro**: 70-139 points
- **Contender**: 140-279 points
- **Elite**: ≥280 points

## 🔧 Verification Steps

### 1. Run the SQL Script
Run `database/verify-and-fix-points-demotion-system.sql` in Supabase SQL Editor.

This script will:
- ✅ Fix points calculation (Loss = -3)
- ✅ Fix tier calculation (correct thresholds)
- ✅ Fix demotion system (5 consecutive losses)
- ✅ Fix promotion back system (5 consecutive wins)
- ✅ Recalculate all existing records
- ✅ Run verification tests

### 2. Test Points Calculation

**Test Cases:**
```sql
-- Should return 5
SELECT calculate_fight_points('Win', 'Decision');

-- Should return 8 (5 + 3)
SELECT calculate_fight_points('Win', 'KO');

-- Should return -3
SELECT calculate_fight_points('Loss', 'Decision');

-- Should return -3 (no bonus for losers)
SELECT calculate_fight_points('Loss', 'TKO');

-- Should return 0
SELECT calculate_fight_points('Draw', 'Decision');
```

### 3. Test Tier Calculation

**Test Cases:**
```sql
-- Should return 'Amateur'
SELECT calculate_tier(0);
SELECT calculate_tier(29);

-- Should return 'Semi-Pro'
SELECT calculate_tier(30);
SELECT calculate_tier(69);

-- Should return 'Pro'
SELECT calculate_tier(70);
SELECT calculate_tier(139);

-- Should return 'Contender'
SELECT calculate_tier(140);
SELECT calculate_tier(279);

-- Should return 'Elite'
SELECT calculate_tier(280);
SELECT calculate_tier(500);
```

### 4. Test Demotion System

**Test Scenario:**
1. Fighter has 4 consecutive losses → No demotion (warning only)
2. Fighter gets 5th consecutive loss → Demoted one tier
3. Fighter wins 5 consecutive fights → Promoted back to tier based on points

**Check Consecutive Losses:**
```sql
-- Get fighters with 3+ consecutive losses (warning indicator)
SELECT 
    fp.name,
    fp.tier,
    fp.points,
    get_consecutive_losses(fp.user_id) as consecutive_losses,
    CASE 
        WHEN get_consecutive_losses(fp.user_id) >= 5 THEN '⚠️ DEMOTION RISK (5+)'
        WHEN get_consecutive_losses(fp.user_id) >= 3 THEN '⚠️ WARNING (3+)'
        ELSE 'OK'
    END as status
FROM fighter_profiles fp
WHERE get_consecutive_losses(fp.user_id) >= 3
ORDER BY get_consecutive_losses(fp.user_id) DESC;
```

### 5. Test Tiebreakers

The tiebreaker system is implemented in `src/services/rankingsService.ts`:
- ✅ Head-to-head comparison
- ✅ KO percentage comparison
- ✅ Average opponent points comparison
- ✅ Recent form comparison (last 5 results)
- ✅ Win percentage (final tiebreaker)

## 📋 Files Modified

### Database:
- `database/verify-and-fix-points-demotion-system.sql` - Comprehensive fix and verification

### Frontend:
- `src/components/FighterProfile/FighterProfile.tsx` - Points calculation (Loss = -3)
- `src/components/Rankings/Rankings.tsx` - Warning indicator for 3+ consecutive losses
- `src/services/rankingsService.ts` - Tiebreaker logic

## ⚠️ Important Notes

1. **Loss = -3** (not -2 or -4)
2. **KO/TKO Bonus = +3** (only for winners)
3. **Demotion = 5 consecutive losses** (not 4)
4. **Warning = 3+ consecutive losses** (red indicator)
5. **Promotion Back = 5 consecutive wins** (after demotion)
6. **Tier Progression**: Amateur → Semi-Pro → Pro → Contender → Elite

## 🧪 Testing Checklist

- [ ] Run SQL verification script
- [ ] Test points calculation (Win, Loss, Draw, KO/TKO)
- [ ] Test tier calculation (all thresholds)
- [ ] Test demotion (5 consecutive losses)
- [ ] Test promotion back (5 consecutive wins)
- [ ] Test warning indicator (3+ consecutive losses)
- [ ] Test tiebreakers (head-to-head, KO%, etc.)
- [ ] Verify real-time updates work correctly

## 📊 Expected Results

After running the script, you should see:
- ✅ All test cases pass
- ✅ Points calculated correctly (Loss = -3)
- ✅ Tiers calculated correctly
- ✅ Fighters with 3+ consecutive losses show warning
- ✅ Fighters with 5+ consecutive losses are demoted
- ✅ Tiebreakers work correctly in rankings

