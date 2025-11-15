# Sign Out Error Fix

## Problem
Production is showing 403 errors when signing out:
```
POST .../auth/v1/logout?scope=global 403 (Forbidden)
AuthSessionMissingError: Auth session missing!
```

## Root Cause
The production build is using old code that defaults to `scope=global`, which requires a valid refresh token. When the session is already expired/missing, this causes 403 errors.

## Solution Applied

### 1. Updated Sign Out Function (`src/contexts/AuthContext.tsx`)
- ✅ Checks for active session before attempting sign out
- ✅ Uses `scope: 'local'` instead of `scope: 'global'` (no refresh token needed)
- ✅ Handles 403 and session missing errors gracefully
- ✅ Clears localStorage as fallback
- ✅ Never blocks UI, always redirects to login

### 2. Enhanced Error Suppression (`src/services/supabase.ts`)
- ✅ Suppresses all `AuthSessionMissingError` errors
- ✅ Suppresses 403 errors from logout endpoints
- ✅ Suppresses errors from `GoTrueAdminApi.ts` during sign out
- ✅ Catches old error message patterns ("Sign out error", "Error signing out")

### 3. Updated Helper Function (`src/services/supabase.ts`)
- ✅ `signOut()` helper also uses `scope: 'local'`
- ✅ Checks for session before attempting sign out

## Next Steps - REQUIRED

**The production build must be rebuilt and redeployed:**

```bash
cd tantalus-boxing-club
npm run build
```

Then deploy the new build to your hosting service.

## Why It Works in Development But Not Production

- **Development**: Has the updated code with `scope: 'local'`
- **Production**: Still has old code with default `scope: 'global'`

The error suppression will hide the errors temporarily, but the proper fix is deploying the new build.

## Testing After Deployment

1. Clear browser cache or use incognito mode
2. Sign in to the app
3. Sign out - should work without errors
4. Check browser console - no 403 or AuthSessionMissingError should appear

## What Changed

**Before:**
```typescript
await supabase.auth.signOut(); // Defaults to scope: 'global'
```

**After:**
```typescript
const { data: { session } } = await supabase.auth.getSession();
if (!session) {
  // Already logged out, just clear local state
  return;
}
await supabase.auth.signOut({ scope: 'local' }); // No refresh token needed
```

## Error Suppression

Even if old code is still running, the enhanced error suppression will:
- Hide `AuthSessionMissingError` errors
- Hide 403 errors from logout endpoints
- Hide "Sign out error" messages with session errors

But the **proper fix** is to rebuild and deploy the new code.

