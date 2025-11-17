# 🔧 Vercel Root Directory Configuration Fix

## ⚠️ **Problem: Rules Page Not Showing in Production**

The Rules page exists in git and is committed, but it's not appearing on Vercel. This is **most likely** a **Root Directory** configuration issue.

## 📁 **Your Repository Structure**

Your repository has this structure:
```
Tantalus-Boxing-Club/ (GitHub repo root)
  ├── tantalus-boxing-club/
  │   └── tantalus-boxing-nextjs/  ← Next.js app is HERE
  │       ├── src/
  │       │   └── app/
  │       │       └── rules/
  │       │           └── page.tsx  ← Rules page is here
  │       ├── package.json
  │       ├── next.config.ts
  │       └── ...
  └── other-files...
```

## ✅ **Solution: Configure Vercel Root Directory**

### **Step 1: Go to Vercel Dashboard**

1. Visit: https://vercel.com/dashboard
2. Click on your project: **Tantalus-Boxing-Club**
3. Click **"Settings"** tab (top navigation)
4. Click **"General"** (left sidebar)

### **Step 2: Set Root Directory**

1. Scroll down to **"Root Directory"** section
2. **Current setting might be:** `.` (root of repo) ❌
3. **Change it to:** `tantalus-boxing-club/tantalus-boxing-nextjs` ✅
4. Click **"Save"**

### **Step 3: Verify Build Settings**

While you're in Settings, verify these settings:

**Settings → General:**
- ✅ **Framework Preset:** Next.js
- ✅ **Root Directory:** `tantalus-boxing-club/tantalus-boxing-nextjs`

**Settings → Build & Development Settings:**
- ✅ **Build Command:** `npm run build` (or auto-detected)
- ✅ **Output Directory:** `.next` (or auto-detected)
- ✅ **Install Command:** `npm install` (or auto-detected)

### **Step 4: Redeploy**

After changing Root Directory:

1. Go to **"Deployments"** tab
2. Click **"..."** on the latest deployment
3. Click **"Redeploy"**
4. **Uncheck:** "Use existing Build Cache"
5. Click **"Redeploy"**

### **Step 5: Verify Deployment**

1. Wait 2-3 minutes for build to complete
2. Check **Build Logs**:
   - Should show: `✓ Compiled /rules`
   - Should show route list with `/rules`
3. Test URL: https://tantalus-boxing-club.vercel.app/rules
   - Should return 200 OK
   - Should display Rules page

## 🔍 **How to Verify Root Directory is Correct**

### **Check 1: Build Logs**

After redeploying, check Build Logs for:
```
> Building...
> Installing dependencies...
> Running "npm run build"
> 
> Route (app)                              Size     First Load JS
> ├ ○ /                                     XX kB         XX kB
> ├ ○ /login                               XX kB         XX kB
> ├ ○ /rules                               XX kB         XX kB  ← Should be here
> ...
```

If `/rules` is **NOT** in the route list, Root Directory is wrong.

### **Check 2: File Structure in Build**

Build logs should show:
```
> Collecting page data...
> Generating static pages...
> ✓ Compiled /rules in XXXms
```

If you see errors like:
```
> Error: Cannot find module './src/app/rules/page'
```
Then Root Directory is wrong.

## 📋 **Alternative: If Root Directory Doesn't Work**

If setting Root Directory doesn't work, you might need to:

### **Option 1: Move Next.js App to Repo Root**

Move the Next.js app to the root of the repository:

```bash
# This would require restructuring your repo
# Only do this if Root Directory setting doesn't work
```

### **Option 2: Create Separate Vercel Project**

Create a separate Vercel project that points directly to the Next.js app directory.

## ✅ **Verification Checklist**

After configuring Root Directory:

- [ ] Root Directory set to: `tantalus-boxing-club/tantalus-boxing-nextjs`
- [ ] Build completed successfully
- [ ] Build logs show `/rules` route compiled
- [ ] Direct URL `/rules` returns 200 (not 404)
- [ ] Rules page content displays correctly
- [ ] Homepage shows "Rules & Guidelines" button
- [ ] Navigation shows "Rules" link (when logged in)

## 🚨 **If Still Not Working**

### **Check 1: Verify Git Connection**

1. Vercel Dashboard → Settings → Git
2. Verify:
   - ✅ Repository: `Talley47/Tantalus-Boxing-Club`
   - ✅ Production Branch: `main`
   - ✅ Auto-deploy: Enabled

### **Check 2: Verify Latest Commit**

1. Vercel Dashboard → Deployments
2. Latest deployment should show commit: `783aeb7` or later
3. If it shows older commit, manually redeploy from latest

### **Check 3: Check for Build Errors**

1. Vercel Dashboard → Latest Deployment → Build Logs
2. Look for:
   - ❌ TypeScript errors
   - ❌ Module not found errors
   - ❌ Missing file errors
   - ❌ Build failures

### **Check 4: Test Locally**

```bash
cd tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
npm run build
npm run start
# Visit http://localhost:3000/rules
```

If it works locally but not on Vercel:
- Root Directory is definitely the issue
- Follow Step 2 above to fix it

## 📞 **Quick Reference**

- **Vercel Dashboard**: https://vercel.com/dashboard
- **Project Settings**: https://vercel.com/dashboard → Your Project → Settings
- **Root Directory Setting**: Settings → General → Root Directory
- **Production URL**: https://tantalus-boxing-club.vercel.app
- **Rules Page URL**: https://tantalus-boxing-club.vercel.app/rules

## 🎯 **Most Likely Fix**

**90% chance this is the issue:** Vercel Root Directory is set to `.` (repo root) instead of `tantalus-boxing-club/tantalus-boxing-nextjs`.

**Fix:** Set Root Directory to `tantalus-boxing-club/tantalus-boxing-nextjs` in Vercel Dashboard → Settings → General.

