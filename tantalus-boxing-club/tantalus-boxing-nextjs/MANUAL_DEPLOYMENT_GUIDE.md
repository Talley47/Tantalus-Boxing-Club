# Manual Deployment Guide - Commit Not Showing in Vercel

## Issue
Commit `a55d0a9` is not appearing in Vercel deployments automatically.

## Quick Fix: Manual Deployment

### Option 1: Trigger Deployment from Vercel Dashboard

1. **Go to:** https://vercel.com/dashboard
2. **Select:** Your project (Tantalus-Boxing-Club)
3. **Go to:** Deployments tab
4. **Click:** "Create Deployment" button (top right)
5. **Enter:**
   - **Git Branch:** `main`
   - **Git Commit SHA:** `a55d0a9` (optional, or leave blank for latest)
6. **Click:** "Deploy"

### Option 2: Redeploy Latest with Latest Code

1. **Go to:** Vercel Dashboard → Deployments
2. **Click:** "..." (three dots) on the latest deployment
3. **Click:** "Redeploy"
4. **Uncheck:** "Use existing Build Cache" (to ensure fresh build)
5. **Click:** "Redeploy"

### Option 3: Verify Git Connection and Trigger

1. **Check Git Connection:**
   - Go to: Settings → Git
   - Verify Repository: `Talley47/Tantalus-Boxing-Club`
   - Verify Branch: `main`
   - Verify Auto-deploy is enabled

2. **If Repository is Wrong:**
   - Click "Disconnect"
   - Click "Connect Git Repository"
   - Select: `Talley47/Tantalus-Boxing-Club`
   - Select branch: `main`
   - This will trigger a new deployment

## Verify Commit is on GitHub

Before deploying, verify the commit exists on GitHub:

1. **Go to:** https://github.com/Talley47/Tantalus-Boxing-Club
2. **Check:** Latest commit should show `a55d0a9`
3. **If not there:** The commit wasn't pushed. Run:
   ```bash
   git push origin main
   ```

## Check Vercel Project Settings

The URL you provided shows: `tantalus-kings-projects/tantalus-boxing-club`

This suggests the project might be under a different organization or account. Verify:

1. **Project Name:** Should be "tantalus-boxing-club"
2. **Organization:** Check if it's under "tantalus-kings-projects"
3. **Repository:** Should be connected to `Talley47/Tantalus-Boxing-Club`

## Force Deployment via Git

If auto-deploy isn't working, you can trigger it by:

1. **Make a small change:**
   ```bash
   # Add a comment or whitespace change
   git commit --allow-empty -m "Trigger Vercel deployment"
   git push origin main
   ```

2. **This should trigger Vercel to deploy**

## Verify Deployment After Manual Trigger

1. **Go to:** Deployments tab
2. **Check:** Latest deployment should show:
   - Commit: `a55d0a9` or later
   - Status: "Building..." then "Ready"
3. **Check Build Logs:**
   - Should show: `✓ Compiled /rules`
   - Should show homepage compilation

## Troubleshooting

### If Manual Deployment Fails

1. **Check Build Logs:**
   - Look for errors
   - Verify environment variables are set
   - Check for missing dependencies

2. **Check Root Directory:**
   - Settings → General → Root Directory
   - Should be: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs`

3. **Check Environment Variables:**
   - Settings → Environment Variables
   - Verify `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are set

### If Commit Still Not Showing

1. **Verify GitHub:**
   - Check if commit `a55d0a9` exists on GitHub
   - If not, push it: `git push origin main`

2. **Check Vercel Git Connection:**
   - Settings → Git
   - Verify correct repository
   - Try disconnecting and reconnecting

3. **Check Branch:**
   - Verify you're on `main` branch
   - Verify Vercel is watching `main` branch

## Expected Result

After manual deployment:
- ✅ Deployment shows commit `a55d0a9`
- ✅ Build completes successfully
- ✅ Homepage shows Rules & Guidelines section
- ✅ Rules page accessible at `/rules`

---

**Try Option 1 first (Create Deployment) - it's the quickest way to get the latest code deployed!**

