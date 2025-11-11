# Rankings, Tier, Demotion, and Matchmaking System Fixes

## ✅ Completed Fixes

### 1. Points Calculation System (FIXED)
- **Database**: Updated `calculate_fight_points()` function
  - Win: **+5 points** (was already correct)
  - Loss: **-3 points** (CORRECTED from -2)
  - Draw: **0 points**
  - KO/TKO Bonus: **+3 points**
  
- **Frontend**: Updated `FighterProfile.tsx` to calculate points correctly

### 2. Tier System (UPDATED)
- **New Tier Thresholds**:
  - Amateur: **≤29 points** (was ≤19)
  - Semi-Pro: **30-69 points** (was 20-39)
  - Pro: **70-139 points** (was 40-89)
  - Contender: **140-279 points** (was 90-149)
  - Elite: **≥280 points** (was ≥150)

- **Database**: Updated `calculate_tier()` function with new thresholds
- **Frontend**: Updated `TIER_THRESHOLDS` in `rankingsService.ts`

### 3. Demotion System (IMPLEMENTED)
- **Lose 5 in a row** = Automatically demote one tier
- **Win 5 in a row after demotion** = Promote back to tier based on points
- Database functions: `get_consecutive_losses()`, `get_consecutive_wins()`
- Automatic tier updates via trigger `trigger_update_fighter_tier`

### 4. Auto-Post Fight Results to News (IMPLEMENTED)
- When fighters enter fight records, results are automatically posted to News/Announcements
- Author: "Mike Glove" (AI News Reporter)
- Type: `fight_result`
- Includes fighter names, opponent, result, method, round, and weight class

### 5. Rankings Calculation (ENHANCED)
- **Tiebreakers** (in order):
  1. Head-to-head record
  2. KO Percentage
  3. Strength of Opponent (average opponent points)
  4. Recent Form (last 5 results)
  5. Win Percentage

## 📋 Files Modified

### Database Scripts:
- `database/fix-rankings-points-tier-system.sql` - Comprehensive fix for all ranking/tier calculations
- `database/fix-fight-records-rls.sql` - RLS policies for fight records
- `database/fix-fight-records-method-constraint.sql` - Method constraint fixes

### Frontend Files:
- `src/services/rankingsService.ts` - Updated tier thresholds and helper functions
- `src/components/FighterProfile/FighterProfile.tsx` - Fixed points calculation, added auto-news posting

## 🔧 Next Steps (Still To Do)

### 6. Matchmaking System (Needs Verification)
- Smart Matchmaking exists but needs testing:
  - Auto-opponent selection based on rankings, weight class, tier
  - Rank window: ±3-5 positions
  - Avoid repeat opponents within last X matches
  - Timezone compatibility
  - Points proximity guardrails (>50 pts gap requires consent)

**Files to check:**
- `src/services/matchmakingService.ts` - Already has `autoAssignOpponent()` and `autoAssignSparringPartner()`
- `src/components/Matchmaking/Matchmaking.tsx` - UI exists

### 7. Training Camp Sparring Partner Search
- Already implemented in `matchmakingService.ts`:
  - `autoAssignSparringPartner()` method
  - Searches based on rankings, weight class, tier
  - More flexible than matchmaking (allows adjacent tiers)

**Action needed:** Verify it's connected to the Training Camp UI

### 8. Real-Time Updates
- Need to add Supabase Realtime subscriptions for:
  - Rankings updates
  - Tier changes
  - Matchmaking updates
  - News/Announcements

**Files to modify:**
- `src/contexts/RealtimeContext.tsx` - Add subscriptions
- Pages: Home, Rankings, Matchmaking, Analytics

### 9. Home Page, Rankings, Analytics Updates
- Ensure all pages show real-time data (not mock)
- Rankings should update automatically when fight records are added
- Analytics should reflect current tier distributions and fight trends

## 📝 SQL Scripts to Run

**Run these in Supabase SQL Editor in order:**

1. `database/fix-rankings-points-tier-system.sql`
   - Fixes points calculation
   - Updates tier thresholds
   - Implements demotion system
   - Creates automatic triggers

2. `database/fix-fight-records-rls.sql`
   - Ensures fighters can insert their own records

3. `database/fix-fight-records-method-constraint.sql`
   - Fixes method constraint for fight records

## 🔍 Testing Checklist

- [ ] Add a fight record (Win) - verify +5 points (or +8 if KO/TKO)
- [ ] Add a fight record (Loss) - verify -3 points
- [ ] Add 5 consecutive losses - verify demotion
- [ ] Add 5 consecutive wins after demotion - verify promotion back
- [ ] Check tier thresholds (Amateur ≤29, Semi-Pro 30-69, etc.)
- [ ] Verify fight result auto-posts to News
- [ ] Test Smart Matchmaking auto-assignment
- [ ] Test Training Camp sparring partner search
- [ ] Verify rankings update in real-time
- [ ] Check tiebreakers work correctly

## 📊 Current Status

**Completed:**
- ✅ Points calculation (Win +5, Loss -3, Draw 0, KO +3)
- ✅ Tier thresholds updated
- ✅ Demotion system (5 losses = demote, 5 wins = promote back)
- ✅ Auto-post to News when fight records added
- ✅ Rankings tiebreakers implemented

**In Progress:**
- 🔄 Matchmaking system verification
- 🔄 Real-time updates

**Pending:**
- ⏳ Training Camp UI integration verification
- ⏳ Real-time subscriptions for all pages

