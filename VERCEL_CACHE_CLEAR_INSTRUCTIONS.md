# CRITICAL: Clear Vercel Build Cache NOW

## Problem
Vercel is building from a **cached old commit** that still has the old import path `../../AdobeStock_567110431.jpeg`.

## Current Status
✅ Code is correct: Uses `const backgroundImage = '/AdobeStock_567110431.jpeg';`  
✅ File exists: `public/AdobeStock_567110431.jpeg` is committed  
✅ Latest commit: `8e87343` (or newer)

## Solution: Clear Vercel Build Cache

### Step 1: Go to Vercel Dashboard
1. Visit: https://vercel.com/dashboard
2. Select your project: **Tantalus-Boxing-Club**

### Step 2: Clear Build Cache
1. Click **Settings** (gear icon)
2. Click **Build & Development Settings**
3. Scroll down to **"Build Cache"** section
4. Click **"Clear Build Cache"** button
5. **Confirm** the action

### Step 3: Redeploy WITHOUT Cache
1. Go to **Deployments** tab
2. Find the latest deployment (should show commit `8e87343` or newer)
3. Click **"..."** (three dots) → **"Redeploy"**
4. **CRITICAL**: **UNCHECK** ✅ "Use existing Build Cache"
5. Click **"Redeploy"**

### Step 4: Verify
After deployment completes:
- ✅ Build should succeed
- ✅ No "Module not found" errors
- ✅ Registration page should load with background image

## Why This Happens

Vercel caches build artifacts to speed up deployments. Sometimes:
- The cache contains an old commit
- File changes aren't detected
- Build cache needs manual clearing

## Prevention

After clearing cache, future deployments should work correctly. If this happens again:
1. Clear build cache
2. Redeploy without cache
3. Consider using Vercel's "Ignore Build Step" feature if needed

---

## Alternative: Force New Deployment

If clearing cache doesn't work, force a new deployment:

```bash
git commit --allow-empty -m "Force Vercel rebuild"
git push origin main
```

Then follow Steps 2-4 above.

