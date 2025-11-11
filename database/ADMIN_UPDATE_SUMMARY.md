# Admin Account Update Summary

## Overview
This document summarizes all the new database schema changes that have been applied to the admin account.

## Admin Account Details
- **Email**: `tantalusboxingclub@gmail.com`
- **User ID**: `a5f939a5-479e-4ede-9b3b-608b7ffe7178`
- **Password**: `TantalusAdmin2025!`

## New Database Columns Added

### fighter_profiles Table
1. **knockouts** (INTEGER)
   - Default: 0
   - Tracks total number of knockouts (KO/TKO wins)

2. **win_percentage** (DECIMAL(5,2))
   - Default: 0.00
   - Calculated as: (wins / total_fights) * 100

3. **ko_percentage** (DECIMAL(5,2))
   - Default: 0.00
   - Calculated as: (knockouts / wins) * 100

### fight_records Table
- New table created for tracking individual fight records
- Includes: opponent_name, result, method, round, date, weight_class, points_earned

## SQL Files to Run

Run these files in your Supabase SQL Editor **in this order**:

1. **add-knockouts-column.sql**
   - Adds `knockouts` column to `fighter_profiles`

2. **add-percentage-columns.sql**
   - Adds `win_percentage` and `ko_percentage` columns

3. **update-admin-account.sql**
   - Updates admin's fighter profile with all new fields
   - Calculates percentages based on current stats
   - Ensures admin role is set correctly

4. **fix-update-fighter-stats-function.sql**
   - Fixes the trigger function that automatically updates fighter stats when fight records are added

5. **fight-records-table.sql**
   - Creates the `fight_records` table (if not already created)
   - Sets up RLS policies

## What Gets Updated

When you run `update-admin-account.sql`, it will:

1. ✅ Add all new columns if they don't exist
2. ✅ Calculate win percentage based on current wins/losses/draws
3. ✅ Calculate KO percentage based on knockouts and wins
4. ✅ Ensure knockouts is set to 0 if null
5. ✅ Update the admin's profile in the `profiles` table with `role = 'admin'`
6. ✅ Show verification output with all updated values

## Verification

After running the SQL, verify the admin account:

```sql
SELECT 
    fp.name,
    fp.points,
    fp.tier,
    fp.wins,
    fp.losses,
    fp.draws,
    fp.knockouts,
    fp.win_percentage,
    fp.ko_percentage,
    p.role
FROM fighter_profiles fp
JOIN profiles p ON p.id = fp.user_id
WHERE p.email = 'tantalusboxingclub@gmail.com';
```

All columns should have values (0 if no fights yet).

