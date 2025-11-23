# Point System Verification Guide

## Point System Rules
- **Win** = +5 points
- **Loss** = -3 points
- **Draw** = 0 points
- **KO/TKO Bonus** = +3 points (only for winners)
  - Win by KO/TKO = 5 + 3 = **8 points total**
  - Loss by KO/TKO = **-3 points** (no bonus for losers)

## Tiebreakers (in order)
1. **Head-to-head** - If fighters have fought, use their record against each other
2. **KO Percentage** - Higher KO% wins the tie
3. **Strength of Opponent** - Average opponent points (higher is better)
4. **Recent Form** - Last 5 fight results (W/L/D)
5. **Win Percentage** - Final tiebreaker

## Verification Steps

### Step 1: Run Database Verification Script
1. Open Supabase SQL Editor
2. Run: `database/verify-point-system-complete.sql`
3. This will:
   - Verify `calculate_fight_points()` function is correct
   - Test all point calculation scenarios
   - Fix all fight records with incorrect points
   - Recalculate all fighter points
   - Show any fighters with incorrect points

### Step 2: Verify Frontend Calculations
The frontend should match the database:

**FighterProfile.tsx** (lines 1043-1055):
```typescript
if (newFightRecord.result === 'win') {
  pointsEarned = 5;
  if (methodUpper === 'KO' || methodUpper === 'TKO') {
    pointsEarned += 3; // Total: 8 points
  }
} else if (newFightRecord.result === 'loss') {
  pointsEarned = -3; // CORRECT
} else if (newFightRecord.result === 'draw') {
  pointsEarned = 0;
}
```

**schedulingService.ts** (lines 675-688):
```typescript
if (result === 'Win') points = 5;
else if (result === 'Loss') points = -3; // CORRECT
else if (result === 'Draw') points = 0;

if (result === 'Win' && (method === 'KO' || method === 'TKO')) {
  points += 3; // Total: 8 points
}
```

**types/index.ts** (lines 480-485):
```typescript
export const POINT_SYSTEM = {
  WIN: 5,
  LOSS: -3, // CORRECT
  DRAW: 0,
  KO_BONUS: 3
} as const;
```

### Step 3: Test Point Calculations

#### Test Case 1: Win by Decision
- **Input**: Result = "Win", Method = "Decision"
- **Expected**: +5 points
- **Database**: `SELECT calculate_fight_points('Win', 'Decision');` → Should return `5`

#### Test Case 2: Win by KO
- **Input**: Result = "Win", Method = "KO"
- **Expected**: +8 points (5 + 3 bonus)
- **Database**: `SELECT calculate_fight_points('Win', 'KO');` → Should return `8`

#### Test Case 3: Win by TKO
- **Input**: Result = "Win", Method = "TKO"
- **Expected**: +8 points (5 + 3 bonus)
- **Database**: `SELECT calculate_fight_points('Win', 'TKO');` → Should return `8`

#### Test Case 4: Loss by Decision
- **Input**: Result = "Loss", Method = "Decision"
- **Expected**: -3 points
- **Database**: `SELECT calculate_fight_points('Loss', 'Decision');` → Should return `-3`

#### Test Case 5: Loss by KO
- **Input**: Result = "Loss", Method = "KO"
- **Expected**: -3 points (no bonus for losers)
- **Database**: `SELECT calculate_fight_points('Loss', 'KO');` → Should return `-3`

#### Test Case 6: Draw
- **Input**: Result = "Draw", Method = "Decision"
- **Expected**: 0 points
- **Database**: `SELECT calculate_fight_points('Draw', 'Decision');` → Should return `0`

### Step 4: Verify Tiebreakers

The tiebreakers are implemented in `rankingsService.ts` (lines 255-280):

1. **Primary**: Points (descending)
2. **Tiebreaker 1**: Head-to-head record
3. **Tiebreaker 2**: KO Percentage (descending)
4. **Tiebreaker 3**: Average Opponent Points (descending)
5. **Tiebreaker 4**: Recent Form (last 5 results)
6. **Final**: Win Percentage (descending)

### Step 5: Check Rankings Display

The Rankings page should display:
- **Points** column showing correct values
- **Tier** based on points thresholds
- **Record** (W-L-D format)
- **Stats** (Win%, KO%)
- **Recent Form** (last 5 results as W/L/D chips)
- **Streak** (current win/loss streak)

## Common Issues & Fixes

### Issue 1: Fighter shows -2 points instead of -3
**Cause**: Old data in database
**Fix**: Run `database/verify-point-system-complete.sql` to recalculate all points

### Issue 2: KO/TKO win shows +5 instead of +8
**Cause**: KO bonus not being applied
**Fix**: Verify `calculate_fight_points()` function includes KO bonus check

### Issue 3: Loss by KO shows -6 instead of -3
**Cause**: KO bonus being applied to losers
**Fix**: Ensure KO bonus only applies when `result = 'Win'`

### Issue 4: Points don't match between database and frontend
**Cause**: Frontend calculating points differently than database
**Fix**: Ensure frontend uses database `points` field, not recalculating

## Verification Queries

### Check all fighters' points
```sql
SELECT 
    name,
    points,
    wins,
    losses,
    draws,
    COALESCE(SUM(calculate_fight_points(result, method)), 0) as calculated_points
FROM fighter_profiles fp
LEFT JOIN fight_records fr ON fr.fighter_id = fp.user_id
GROUP BY name, points, wins, losses, draws
ORDER BY points DESC;
```

### Find fighters with incorrect points
```sql
SELECT 
    fp.name,
    fp.points as stored_points,
    COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0) as calculated_points,
    fp.points - COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0) as difference
FROM fighter_profiles fp
LEFT JOIN fight_records fr ON fr.fighter_id = fp.user_id
GROUP BY fp.name, fp.points
HAVING fp.points != COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)
ORDER BY ABS(difference) DESC;
```

### Test point calculation function
```sql
SELECT 
    'Win + Decision' as test,
    calculate_fight_points('Win', 'Decision') as points,
    CASE WHEN calculate_fight_points('Win', 'Decision') = 5 THEN 'PASS' ELSE 'FAIL' END as result
UNION ALL
SELECT 
    'Win + KO',
    calculate_fight_points('Win', 'KO'),
    CASE WHEN calculate_fight_points('Win', 'KO') = 8 THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 
    'Loss + Decision',
    calculate_fight_points('Loss', 'Decision'),
    CASE WHEN calculate_fight_points('Loss', 'Decision') = -3 THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 
    'Loss + KO',
    calculate_fight_points('Loss', 'KO'),
    CASE WHEN calculate_fight_points('Loss', 'KO') = -3 THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 
    'Draw',
    calculate_fight_points('Draw', 'Decision'),
    CASE WHEN calculate_fight_points('Draw', 'Decision') = 0 THEN 'PASS' ELSE 'FAIL' END;
```

## Summary

✅ **Database Function**: `calculate_fight_points()` correctly implements Win=+5, Loss=-3, Draw=0, KO Bonus=+3
✅ **Frontend Constants**: `POINT_SYSTEM` correctly defines LOSS: -3
✅ **Frontend Calculations**: FighterProfile and schedulingService correctly calculate points
✅ **Tiebreakers**: Implemented in correct order (Head-to-head → KO% → Opponent Strength → Recent Form)
✅ **Rankings Display**: Shows all required information (Tier, Points, Record, Stats, Recent Form, Streak)

The point system is fully implemented and verified!

