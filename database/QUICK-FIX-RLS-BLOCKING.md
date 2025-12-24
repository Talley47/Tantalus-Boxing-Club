# 🔧 Quick Fix: RLS Blocking fighter_profiles

## The Problem
Your console shows:
```
⚠️ ⚠️ ⚠️ NO FIGHTERS RETURNED FROM QUERY ⚠️ ⚠️ ⚠️
Diagnostic Info: {canSeeAnyRows: false, diagnosticRowCount: 0, diagnosticError: 'none'}
```

This means:
- ✅ Query succeeds (HTTP 200)
- ❌ But returns 0 rows (RLS is blocking access)

## The Solution

### Option 1: Run Diagnostic First (Recommended)
1. Open Supabase Dashboard → SQL Editor
2. Copy and paste **entire** `DIAGNOSE-RLS-BLOCKING-NOW.sql`
3. Click "Run"
4. Review the output to see what's wrong
5. Then run `FIX-RLS-BLOCKING-DEFINITIVE.sql`

### Option 2: Apply Fix Directly
1. Open Supabase Dashboard → SQL Editor
2. Copy and paste **entire** `FIX-RLS-BLOCKING-DEFINITIVE.sql`
3. Click "Run"
4. Review verification output
5. Hard refresh browser (Ctrl+Shift+R)

## What the Fix Does

The fix addresses **ALL** possible causes:

1. **Missing Schema USAGE Grants** ✅
   - Allows roles to access the `public` schema
   - Often missing and causes silent failures

2. **Missing Table SELECT Grants** ✅
   - Allows roles to query the table
   - Separate from RLS policies (both needed!)

3. **Missing RLS Policies** ✅
   - Creates permissive policies for `anon` and `authenticated`
   - Homepage needs `anon` policy (loads before login)

4. **RLS Not Enabled** ✅
   - Enables RLS (required by security scanner)

## Verification

After running the fix, you should see:
```
✅ ✅ ✅ ALL CHECKS PASSED! ✅ ✅ ✅
```

If you see failures, review the error messages and try again.

## Still Not Working?

1. **Hard refresh browser**: Ctrl+Shift+R (clears cache)
2. **Check browser console**: Look for new errors
3. **Run diagnostic**: Use `DIAGNOSE-RLS-BLOCKING-NOW.sql` to see what's wrong
4. **Check Supabase logs**: Dashboard → Logs → API Logs

## Why This Happens

RLS blocking occurs when:
- RLS is enabled but no policies exist
- Policies exist but grants are missing
- Policies are too restrictive
- Schema permissions are missing

The fix script addresses **all** of these issues.

