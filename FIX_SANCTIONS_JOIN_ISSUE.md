# Fix for Fighters Unable to Join Boxing Sanctions

## Problem

Fighters are unable to join Boxing Sanctions. The join button may not work or show an error.

## Common Causes

1. **Database Table Not Created**: The `fighter_sanctions` table doesn't exist
2. **RLS Policy Issues**: Row Level Security policies are blocking the insert
3. **Missing Fighter Profile**: User doesn't have a fighter profile
4. **Authentication Issues**: User is not properly authenticated

## Solution

### Step 1: Verify Table Exists

Run this in Supabase SQL Editor to check:

```sql
-- File: database/verify-fighter-sanctions-setup.sql
```

This will show you:
- If the table exists
- If RLS is enabled
- What policies are configured
- What indexes exist

### Step 2: Create/Fix the Table

If the table doesn't exist, run:

```sql
-- File: database/create-fighter-sanctions-table.sql
```

### Step 3: Fix RLS Policies

If the table exists but joining still fails, run:

```sql
-- File: database/fix-fighter-sanctions-join-issue.sql
```

This script:
- Recreates all RLS policies with proper permissions
- Ensures fighters can insert their own sanctions
- Verifies all policies are correct

## Troubleshooting

### Error: "Fighter profile not found"
- **Solution**: User must complete their fighter profile first
- Go to My Profile and fill out all required fields

### Error: "Permission denied" or "Policy violation"
- **Solution**: Run the fix script above
- Check that user is logged in (auth.uid() is not null)
- Verify RLS policies are correct

### Error: "Table does not exist"
- **Solution**: Run `create-fighter-sanctions-table.sql`
- Verify in Supabase Dashboard → Database → Tables

### Error: "Already joined this sanction"
- **Solution**: This is expected if already a member
- Check the "View Fighters" button to see your membership

## Verification

After applying fixes, test by:

1. Log in as a fighter with a complete profile
2. Navigate to Home Page → Boxing Sanctions tab
3. Click "Join" on any sanction
4. Should see success (button changes to "View Fighters" and "Leave")

## Error Messages

The service now provides better error messages:
- "Fighter profile not found. Please complete your fighter profile first."
- "Permission denied. Please ensure you are logged in and have a fighter profile."
- "Sanctions feature not available yet. Please contact admin to set up the database."
- "You have already joined this sanction"

## Still Having Issues?

1. Check browser console for detailed error messages
2. Verify user is authenticated (logged in)
3. Verify fighter profile exists and is complete
4. Run the verification script to check database setup
5. Contact admin if table needs to be created

