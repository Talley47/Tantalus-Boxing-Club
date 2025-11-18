# Deploy Without Commit SHA - Fix Vercel Error

## Problem
Vercel error: "The provided GitHub repository reportedly has the commit reference but not for given branch name."

## Root Cause
Even though commit `a55d0a9` exists on `main` branch, Vercel might have issues finding it when you specify the commit SHA directly, especially with nested directory structures.

## ✅ Solution: Deploy Latest from Branch (No Commit SHA)

### Step 1: Create Deployment Without Commit SHA

1. **Go to:** https://vercel.com/dashboard
2. **Select:** Your project (Tantalus-Boxing-Club)
3. **Go to:** Deployments tab
4. **Click:** "Create Deployment" button (top right)
5. **In the deployment form:**
   - **Git Branch:** Select `main` from dropdown
   - **Git Commit SHA:** **LEAVE THIS BLANK** (don't enter `a55d0a9`)
   - This will deploy the **latest commit** from the `main` branch
6. **Click:** "Deploy"

### Why This Works
- Vercel will fetch the latest commit from `main` branch
- Since `a55d0a9` is the latest commit, it will be deployed
- No need to specify the commit SHA manually

## Alternative: Use "Redeploy" Instead

If "Create Deployment" still has issues:

1. **Go to:** Deployments tab
2. **Find:** Any previous successful deployment
3. **Click:** "..." (three dots) → "Redeploy"
4. **Uncheck:** "Use existing Build Cache"
5. **Click:** "Redeploy"

This will redeploy using the latest code from the connected branch.

## Verify Commit is Latest

The commit `a55d0a9` is confirmed to be:
- ✅ Latest commit on `main` branch
- ✅ Synced with `origin/main`
- ✅ Accessible on GitHub: https://github.com/Talley47/Tantalus-Boxing-Club

## Important: Root Directory Configuration

Before deploying, make sure Root Directory is set:

1. **Go to:** Settings → General
2. **Check:** Root Directory
3. **Should be:** `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs`
4. **If not set:** Set it and save before deploying

## Step-by-Step Deployment

### Option A: Deploy Latest (Recommended)

1. **Vercel Dashboard** → **Deployments**
2. **Click:** "Create Deployment"
3. **Branch:** `main`
4. **Commit SHA:** **Leave blank**
5. **Click:** "Deploy"
6. **Wait:** 2-3 minutes

### Option B: Redeploy Latest

1. **Vercel Dashboard** → **Deployments**
2. **Click:** "..." on any deployment
3. **Click:** "Redeploy"
4. **Uncheck:** "Use existing Build Cache"
5. **Click:** "Redeploy"

## Verification

After deployment:

1. **Check Deployment:**
   - Should show commit `a55d0a9` (or latest)
   - Status: "Ready" (green checkmark)

2. **Check Build Logs:**
   - Should show: `✓ Compiled /rules`
   - Should show homepage compilation

3. **Test Homepage:**
   - Visit: https://tantalus-boxing-club.vercel.app/
   - Should show Rules & Guidelines section

## Why Not Specify Commit SHA?

When you specify a commit SHA:
- Vercel tries to find that exact commit
- With nested directories, this can cause issues
- Branch-based deployment is more reliable

When you leave it blank:
- Vercel uses the latest commit from the branch
- More reliable with complex repository structures
- Automatically gets the latest code

## Troubleshooting

### If Deployment Still Fails

1. **Check Root Directory:**
   - Settings → General → Root Directory
   - Must be: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs`

2. **Check Branch:**
   - Settings → Git → Production Branch
   - Must be: `main`

3. **Check Environment Variables:**
   - Settings → Environment Variables
   - Must have: `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`

4. **Check Build Logs:**
   - Look for specific errors
   - Share error messages if deployment fails

---

**The key is to deploy from `main` branch WITHOUT specifying the commit SHA - this will automatically use the latest commit (which is `a55d0a9`).**

