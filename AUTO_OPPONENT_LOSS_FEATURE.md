# Auto-Create Opponent Loss Record Feature

## Overview
When a fighter enters a **Win** on their record, the system now automatically creates a corresponding **Loss** record for their opponent. This ensures both fighters' records stay synchronized.

## How It Works

### Automatic Process
1. Fighter A enters a Win against Fighter B
2. System finds Fighter B by matching the opponent name
3. System automatically creates a Loss record for Fighter B
4. Fighter B's stats are automatically updated (losses +1, points -3)

### Opponent Matching
The system matches opponents using:
- **Exact match** on fighter name (case-insensitive)
- **Exact match** on fighter handle
- **Partial match** if exact match fails (handles slight name variations)

### Duplicate Prevention
- Checks if opponent already has a Loss record for this fight
- Skips auto-creation if record already exists
- Prevents duplicate records

### Error Handling
- If opponent not found: Logs a notice but doesn't fail the original Win entry
- If auto-creation fails: Logs a warning but doesn't affect the original Win entry
- Original Win record is always saved successfully

## Database Setup

### Step 1: Run the SQL Script
1. Open your Supabase SQL Editor
2. Copy and paste the contents of `database/auto-create-opponent-loss-trigger.sql`
3. Run the SQL script
4. You should see: `✅ Auto-create opponent loss trigger created successfully!`

### Step 2: Verify the Trigger
```sql
-- Check if trigger exists
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'trigger_auto_create_opponent_loss';
```

## Features

### What Gets Auto-Created
When Fighter A enters a Win, Fighter B automatically gets:
- **Result**: Loss
- **Opponent Name**: Fighter A's name
- **Method**: Same as the win (e.g., if Fighter A won by KO, Fighter B lost by KO)
- **Round**: Same as the win
- **Date**: Same as the win
- **Weight Class**: Same as the win
- **Points**: -3 (calculated using `calculate_fight_points` function)
- **Notes**: "Auto-created from opponent's win record"

### What Doesn't Get Auto-Created
- **Draws**: Only Wins trigger auto-loss creation
- **Losses**: If Fighter A enters a Loss, nothing happens (opponent would have entered their own Win)
- **Opponent Not Found**: If the opponent name doesn't match any fighter, no record is created

## Testing

### Test Case 1: Basic Win Entry
1. Fighter A (e.g., "John Doe") enters a Win against Fighter B (e.g., "Jane Smith")
2. Check Fighter B's records - should see a Loss record auto-created
3. Check Fighter B's stats - losses should be +1, points should be -3

### Test Case 2: Opponent Not Found
1. Fighter A enters a Win against "Non-Existent Fighter"
2. Win record is saved successfully
3. No loss record is created (opponent not found)
4. Check Supabase logs for notice message

### Test Case 3: Duplicate Prevention
1. Fighter A enters a Win against Fighter B
2. Loss record is auto-created for Fighter B
3. Fighter A tries to enter the same Win again (or Fighter B manually enters the Loss)
4. System detects duplicate and skips auto-creation

### Test Case 4: Name Variations
1. Fighter A enters Win against "John Doe"
2. Fighter B's name in database is "John Doe" (exact match) - should work
3. Fighter A enters Win against "john doe" (lowercase) - should still work (case-insensitive)
4. Fighter A enters Win against "John" - should work if Fighter B's name contains "John" (partial match)

## Important Notes

### Opponent Name Matching
- **Exact match preferred**: Use the exact fighter name for best results
- **Handle matching**: Can also match by fighter handle
- **Partial matching**: Falls back to partial match if exact match fails
- **Case-insensitive**: "John Doe" matches "john doe"

### Points Calculation
- Uses the same `calculate_fight_points` function as the rest of the system
- Loss = -3 points (no KO bonus for losers)
- Ensures consistency across all fight records

### Trigger Order
The trigger fires **AFTER INSERT**, which means:
1. Winner's Win record is inserted
2. Winner's stats are updated (by existing stats trigger)
3. Opponent's Loss record is auto-created (by this trigger)
4. Opponent's stats are automatically updated (by existing stats trigger on the new INSERT)

### Security
- Uses `SECURITY DEFINER` to bypass RLS for the INSERT
- The auto-created record respects RLS policies
- Only authenticated users can trigger this (through their own Win entries)

## Troubleshooting

### Opponent Loss Not Created?
1. **Check opponent name**: Make sure the opponent name exactly matches a fighter in the database
2. **Check Supabase logs**: Look for notice/warning messages
3. **Check if already exists**: The opponent might already have the Loss record
4. **Check trigger exists**: Run the verification SQL above

### Duplicate Records?
- The system checks for existing records before creating
- If duplicates appear, check the date and opponent_name matching logic
- Manual cleanup may be needed for edge cases

### Points Not Updated?
- The auto-created Loss record triggers the stats update trigger
- Check if the stats update trigger is working correctly
- Verify `calculate_fight_points` function exists and works

## Future Enhancements

Potential improvements:
- Support for Draws (auto-create Draw for opponent)
- Better name matching (fuzzy matching, nickname support)
- Admin override to manually trigger opponent record creation
- Notification to opponent when loss is auto-created

