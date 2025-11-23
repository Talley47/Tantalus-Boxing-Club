# Real-Time System - Complete Implementation Guide

## ✅ System Status: FULLY IMPLEMENTED

All components now update in real-time when fighters enter their records. The system automatically:
- Updates points, tier, and demotion status
- Creates opponent loss records when a fighter enters a win
- Updates all relevant pages (Home, Rankings, Analytics, etc.) instantly

---

## 📋 What Updates in Real-Time

### 1. **Home Page** ✅
- **Top 30 Fighters** - Updates when:
  - Fight records are added/updated
  - Fighter profiles change (points, tier, weight_class, wins, losses, draws)
  - Rankings change
- **Scheduled Fights** - Updates when fights are scheduled/cancelled
- **News & Announcements** - Updates when news is added/updated

**Real-Time Subscriptions:**
- `fight_records` table changes
- `fighter_profiles` table changes
- `scheduled_fights` table changes
- `rankings` table changes (if exists)

### 2. **Rankings Page** ✅
- **Overall Rankings** - Updates when:
  - Fight records are added/updated
  - Fighter profiles change (points, tier, weight_class)
- **Weight Class Rankings** - Updates when:
  - Points change within a weight class
  - Tier changes
  - Weight class assignments change

**Real-Time Subscriptions:**
- `fight_records` table changes
- `fighter_profiles` table changes
- `rankings` table changes (if exists)

### 3. **Fighter Profile Page** ✅
- **Fighter Stats** - Updates when:
  - Points change
  - Tier changes (promotion/demotion)
  - Weight class changes
  - Wins, losses, or draws change
- **Fight Records** - Updates when new records are added
- **Ranking** - Updates when points or tier change
- **Scheduled Fights** - Updates when fights are scheduled/cancelled

**Real-Time Subscriptions:**
- `fight_records` table changes
- `fighter_profiles` table changes
- `scheduled_fights` table changes

### 4. **Analytics (Fighter Stats)** ✅
- Updates when:
  - Fight records are added/updated for the fighter
  - Fighter profile changes (affects stats, tier, etc.)

**Real-Time Subscriptions:**
- `fight_records` table changes (filtered by fighter)
- `fighter_profiles` table changes (filtered by fighter)

### 5. **Admin League Analytics** ✅
- Updates when:
  - Any fight record changes
  - Any fighter profile changes (points, tier, weight_class)
  - Affects league-wide statistics and tier distributions

**Real-Time Subscriptions:**
- `fight_records` table changes (all fighters)
- `fighter_profiles` table changes (all fighters)

### 6. **Weight Class Rankings** ✅
- Updates automatically when:
  - Fighter weight class changes
  - Rankings are recalculated
  - Points change within a weight class

**Note:** Weight Class rankings are part of the Rankings page and use the same real-time subscriptions.

### 7. **Demotion System** ✅
- Updates automatically when:
  - Points drop below tier thresholds
  - Tier changes (promotion/demotion)
  - Fight records are added (may trigger demotion)

**Database Triggers:**
- `update_fighter_tier_after_fight` - Automatically handles demotion (5 consecutive losses) and promotion back (5 consecutive wins)

### 8. **Tier System** ✅
- Updates automatically when:
  - Tier changes (promotion/demotion)
  - Points change (may affect tier progression)
  - Fight records are added

**Database Functions:**
- `calculate_tier(points)` - Calculates tier based on points
- `get_consecutive_losses(fighter_user_id)` - Counts consecutive losses
- `get_consecutive_wins(fighter_user_id)` - Counts consecutive wins

### 9. **Points System** ✅
- Updates automatically when:
  - Fight records are added (points are calculated)
  - Points are manually adjusted
  - Tier thresholds are crossed

**Database Functions:**
- `calculate_fight_points(result, method)` - Calculates points:
  - Win = +5
  - Loss = -3
  - Draw = 0
  - KO/TKO Bonus = +3 (only for winners)

**Database Triggers:**
- `update_fighter_stats_after_fight` - Automatically updates points when fight record is added

### 10. **Auto-Create Opponent Loss** ✅
- When a fighter enters a Win, their opponent automatically gets a Loss record

**Database Triggers:**
- `trigger_auto_create_opponent_loss` - Automatically creates loss record for opponent

---

## 🔧 Technical Implementation

### Database Triggers

1. **`update_fighter_stats_after_fight`**
   - Fires: AFTER INSERT on `fight_records`
   - Updates: points, wins, losses, draws, win_percentage, ko_percentage
   - Uses: `calculate_fight_points()` function

2. **`update_fighter_tier_after_fight`**
   - Fires: AFTER UPDATE on `fighter_profiles` (when points change)
   - Handles: Demotion (5 consecutive losses) and promotion back (5 consecutive wins)
   - Uses: `calculate_tier()`, `get_consecutive_losses()`, `get_consecutive_wins()`

3. **`trigger_auto_create_opponent_loss`**
   - Fires: AFTER INSERT on `fight_records` (when result = 'Win')
   - Creates: Loss record for opponent automatically
   - Uses: `calculate_fight_points()` for opponent's loss points

### Database Functions

1. **`calculate_fight_points(result TEXT, method TEXT)`**
   - Returns: Points for the fight
   - Rules:
     - Win = +5
     - Loss = -3
     - Draw = 0
     - KO/TKO Bonus = +3 (only for winners)

2. **`calculate_tier(points INTEGER)`**
   - Returns: Tier name based on points
   - Thresholds:
     - Amateur: 0-29 pts
     - Semi-Pro: 30-69 pts
     - Pro: 70-139 pts
     - Contender: 140-279 pts
     - Elite: 280+ pts

3. **`get_consecutive_losses(fighter_user_id UUID)`**
   - Returns: Number of consecutive losses
   - Used for: Demotion check (5 losses = demote)

4. **`get_consecutive_wins(fighter_user_id UUID)`**
   - Returns: Number of consecutive wins
   - Used for: Promotion back check (5 wins after demotion = promote back)

### Frontend Real-Time Subscriptions

All components use the `RealtimeContext` which provides:
- `subscribeToFightRecords(callback)` - Subscribe to fight_records changes
- `subscribeToFighterProfiles(callback)` - Subscribe to fighter_profiles changes
- `subscribeToScheduledFights(callback)` - Subscribe to scheduled_fights changes
- `subscribeToRankings(callback)` - Subscribe to rankings changes

**Components with Real-Time:**
- ✅ HomePage.tsx
- ✅ Rankings.tsx
- ✅ FighterProfile.tsx
- ✅ Analytics.tsx
- ✅ AdminAnalytics.tsx
- ✅ Matchmaking.tsx
- ✅ RankingsScreen.tsx (Mobile)

---

## 🚀 Setup Instructions

### 1. Enable Realtime in Supabase

Go to **Supabase Dashboard > Database > Replication** and enable Realtime for:
- ✅ `fighter_profiles`
- ✅ `fight_records`
- ✅ `scheduled_fights`
- ✅ `rankings` (if it's a table)

### 2. Run Database Scripts

Run these SQL scripts in order:

1. **`complete-calculation-system-verification.sql`**
   - Sets up points calculation, tier calculation, and demotion system
   - Creates all necessary triggers and functions

2. **`auto-create-opponent-loss-trigger.sql`**
   - Sets up automatic opponent loss creation

3. **`VERIFY-REALTIME-SYSTEM.sql`** (Optional)
   - Verifies that all triggers and functions are working correctly

### 3. Verify Frontend Subscriptions

All frontend components already have real-time subscriptions set up. No additional code changes needed.

---

## ✅ Verification Checklist

- [x] Points calculation: Win = +5, Loss = -3, Draw = 0, KO/TKO Bonus = +3
- [x] Tier thresholds: Amateur (0-29), Semi-Pro (30-69), Pro (70-139), Contender (140-279), Elite (280+)
- [x] Demotion system: 5 consecutive losses = demote one tier
- [x] Promotion back: 5 consecutive wins after demotion = promote back
- [x] Auto-create opponent loss: When fighter enters Win, opponent gets Loss
- [x] Home Page updates in real-time
- [x] Rankings page updates in real-time
- [x] Weight Class rankings update in real-time
- [x] Fighter Profile updates in real-time
- [x] Analytics updates in real-time
- [x] Admin Analytics updates in real-time
- [x] Mobile RankingsScreen updates in real-time

---

## 📝 Point System Rules

- **Win = +5 points**
- **Loss = -3 points**
- **Draw = 0 points**
- **KO/TKO Bonus = +3 points** (only applies to winners)

### Examples:
- Win by Decision = 5 points
- Win by KO = 8 points (5 + 3 bonus)
- Win by TKO = 8 points (5 + 3 bonus)
- Loss by Decision = -3 points
- Loss by KO = -3 points (no bonus for losers)
- Loss by TKO = -3 points (no bonus for losers)
- Draw = 0 points

---

## 📝 Tier System Rules

### Tier Thresholds:
- **Amateur**: 0-29 points
- **Semi-Pro**: 30-69 points
- **Pro**: 70-139 points
- **Contender**: 140-279 points
- **Elite**: 280+ points

### Demotion System:
- **Automatic Demotion**: If a fighter loses 5 consecutive fights, they will be automatically demoted one tier.
- **Promotion Back**: After demotion, a fighter must win 5 consecutive fights to be promoted back to their previous tier.
- **Warning**: Fighters with 3+ consecutive losses are at risk of demotion. Look for the red warning indicator (!) next to fighters' names.

### Tier Progression:
- Amateur → Semi-Pro → Pro → Contender → Elite

---

## 🐛 Troubleshooting

### Real-Time Not Working?

1. **Check Supabase Dashboard:**
   - Go to Database > Replication
   - Ensure Realtime is enabled for all required tables

2. **Check Browser Console:**
   - Look for Realtime connection errors
   - Check if subscriptions are being created

3. **Check Network:**
   - Ensure WebSocket connections are not blocked
   - Check firewall settings

### Points Not Updating?

1. **Check Database Triggers:**
   - Run `VERIFY-REALTIME-SYSTEM.sql` to verify triggers exist
   - Check if `update_fighter_stats_after_fight` trigger is firing

2. **Check Points Calculation:**
   - Verify `calculate_fight_points()` function is correct
   - Check if points_earned in fight_records is being set correctly

### Tier Not Updating?

1. **Check Demotion System:**
   - Verify `update_fighter_tier_after_fight` trigger exists
   - Check if `calculate_tier()` function is correct
   - Verify consecutive losses/wins are being counted correctly

### Opponent Loss Not Created?

1. **Check Auto-Create Trigger:**
   - Verify `trigger_auto_create_opponent_loss` exists
   - Check if opponent name matches exactly in fighter_profiles
   - Check trigger logs for errors

---

## 📚 Related Files

### Database Scripts:
- `complete-calculation-system-verification.sql` - Main calculation system
- `auto-create-opponent-loss-trigger.sql` - Opponent loss auto-creation
- `VERIFY-REALTIME-SYSTEM.sql` - Verification script

### Frontend Components:
- `src/components/HomePage/HomePage.tsx` - Home page with real-time
- `src/components/Rankings/Rankings.tsx` - Rankings page with real-time
- `src/components/FighterProfile/FighterProfile.tsx` - Fighter profile with real-time
- `src/components/Analytics/Analytics.tsx` - Fighter analytics with real-time
- `src/components/Admin/AdminAnalytics.tsx` - Admin analytics with real-time
- `src/contexts/RealtimeContext.tsx` - Real-time subscription context

### Mobile Components:
- `tantalus-boxing-mobile/src/screens/RankingsScreen.tsx` - Mobile rankings with real-time

---

## ✅ System Complete

All real-time updates are now fully implemented and working. When a fighter enters a record:
1. Points are automatically calculated and updated
2. Tier is automatically recalculated
3. Demotion/promotion is automatically handled
4. Opponent loss is automatically created (if win)
5. All pages update in real-time
6. Analytics update in real-time
7. Rankings update in real-time

**No manual refresh needed!** 🎉

