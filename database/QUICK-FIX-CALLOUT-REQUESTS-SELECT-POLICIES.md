# Quick Fix: Multiple Permissive Policies on callout_requests (authenticated SELECT)

## Issue
Your security scanner is reporting:
- **Table**: `public.callout_requests`
- **Role**: `authenticated`
- **Action**: `SELECT`
- **Conflicting Policies**: 
  - "Admins can view all callouts"
  - "Authenticated users can view callouts"

## Solution
Consolidate these two policies into a single policy that handles both cases.

## Quick Steps

1. **Open Supabase SQL Editor**
   - Go to: https://supabase.com/dashboard → Your Project → SQL Editor

2. **Run the Fix Script**
   - Open: `database/FIX-MULTIPLE-PERMISSIVE-POLICIES-CALLOUT-REQUESTS-SELECT-CONSOLIDATE-NOW.sql`
   - Copy ALL content (Ctrl+A, Ctrl+C)
   - Paste into SQL Editor (Ctrl+V)
   - Click "Run" button (or press Ctrl+Enter)

3. **Review Output**
   - Check the verification section
   - Should show: "✅ CONSOLIDATION SUCCESSFUL!"

4. **Wait for Scanner Cache**
   - Wait 5-10 minutes for security scanner cache to refresh

5. **Re-run Security Scanner**
   - The warning should be resolved ✅

## What the Script Does

1. **Drops** the two conflicting policies:
   - "Admins can view all callouts"
   - "Authenticated users can view callouts"

2. **Creates** a single consolidated policy:
   - "Authenticated users can view callouts"
   - This policy handles:
     - Admins can view all callouts
     - Fighters can view callouts where they are caller or target
     - All authenticated users can view scheduled callouts

3. **Preserves** all functionality while improving performance

## Verification

After running the script, you should see:
- ✅ Authenticated SELECT Policies Count: 1
- ✅ "Admins can view all callouts" policy exists: NO
- ✅ "Authenticated users can view callouts" policy exists: YES

## Notes

- The script uses a transaction, so if anything fails, all changes are rolled back
- All functionality is preserved - admins and fighters can still access callouts as before
- Performance improves because only 1 policy is evaluated instead of 2+

