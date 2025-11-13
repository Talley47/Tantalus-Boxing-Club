# Fix Vercel Build Cache Issue - Missing Image File

## Problem
Vercel build is failing with:
```
Module not found: Error: Can't resolve '../../AdobeStock_567110431.jpeg' in '/vercel/path0/src/components/Auth'
```

## Root Cause
The file `src/AdobeStock_567110431.jpeg` **IS** committed to Git (commit `af0b71c`), but Vercel is building from a cached commit that doesn't have it.

## Solution: Clear Vercel Build Cache

### Method 1: Via Vercel Dashboard (Recommended)

1. **Go to Vercel Dashboard**: https://vercel.com/dashboard
2. **Select your project**: Tantalus-Boxing-Club
3. **Go to Settings** → **Build & Development Settings**
4. **Scroll to "Build Cache"** section
5. **Click "Clear Build Cache"**
6. **Confirm** the action
7. **Go to Deployments** tab
8. **Click "..."** on the latest deployment → **"Redeploy"**
9. **IMPORTANT**: **Uncheck** "Use existing Build Cache"
10. **Click "Redeploy"**

### Method 2: Force Redeploy via Git

1. Make a small change to trigger a new deployment:
   ```bash
   git commit --allow-empty -m "Force Vercel rebuild - clear cache"
   git push origin main
   ```

2. **After push**, go to Vercel Dashboard → **Deployments**
3. **Click "..."** on the new deployment → **"Redeploy"**
4. **Uncheck** "Use existing Build Cache"
5. **Click "Redeploy"**

### Method 3: Via Vercel CLI

```bash
vercel --force
```

## Verification

After redeploying:
1. Check the build logs - should show the image file being found
2. Build should complete successfully
3. The registration page should load with the background image

## Why This Happens

Vercel caches build artifacts to speed up deployments. Sometimes:
- The cache contains an old commit
- File changes aren't detected properly
- Build cache needs to be manually cleared

## Prevention

If this keeps happening:
1. Consider using Vercel's "Ignore Build Step" feature
2. Or add a `.vercelignore` file (though this won't help with build cache)
3. Regularly clear build cache after major file additions

