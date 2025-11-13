# 🔧 Fix: react-scripts command not found

## ⚠️ **Problem**

Vercel can't find `react-scripts` because dependencies aren't being installed before the build runs.

---

## ✅ **Solution: Configure Build Settings in Vercel Dashboard**

### **Step 1: Go to Vercel Project Settings**

1. **Go to:** https://vercel.com/dashboard
2. **Click:** Your Project (`Tantalus-Boxing-Club`)
3. **Click:** **"Settings"** tab
4. **Click:** **"Build & Development Settings"** (left sidebar)

---

### **Step 2: Configure Build Settings**

Set these values:

**Framework Preset:**
- Select: **"Create React App"**

**Build Command:**
```
npm ci && npm run build
```

**Output Directory:**
```
build
```

**Install Command:**
```
npm ci
```

**Root Directory:**
```
(leave empty or set to `./` if needed)
```

---

### **Step 3: Save and Redeploy**

1. **Click:** **"Save"** button
2. **Go to:** **"Deployments"** tab
3. **Click:** **"..."** on latest deployment
4. **Click:** **"Redeploy"**
5. **Uncheck:** "Use existing Build Cache"
6. **Click:** **"Redeploy"**

---

## 🔍 **Why This Works**

- **`npm ci`** - Installs dependencies from `package-lock.json` (more reliable than `npm install`)
- **Framework Preset** - Tells Vercel this is a Create React App
- **Build Command** - Ensures dependencies install before building
- **Output Directory** - Tells Vercel where the build output is

---

## 📋 **Alternative: Check Vercel Auto-Detection**

Vercel should auto-detect Create React App, but if it doesn't:

1. **Check:** Settings → Build & Development Settings
2. **Verify:** Framework Preset shows "Create React App"
3. **If not:** Manually set it (see Step 2 above)

---

## ✅ **Expected Result**

After configuring:

1. **Build logs should show:**
   ```
   Installing dependencies...
   npm ci
   [dependencies installing...]
   Building...
   npm run build
   react-scripts build
   [build output...]
   ```

2. **Build should complete successfully**

3. **No "react-scripts: command not found" error**

---

## 🆘 **If Still Failing**

### **Check These:**

1. **package-lock.json exists:**
   - Should be in root directory
   - Should be committed to Git

2. **Node version:**
   - Vercel Settings → Build & Development Settings
   - Node.js Version should be set (or auto)
   - Create React App needs Node 14+ (Vercel defaults to 18.x)

3. **Build logs:**
   - Check if `npm ci` is running
   - Check if dependencies are installing
   - Look for any error messages

---

## 📝 **Quick Fix Summary**

**In Vercel Dashboard:**
- Framework: Create React App
- Build Command: `npm ci && npm run build`
- Install Command: `npm ci`
- Output Directory: `build`

**Then:** Redeploy without cache

---

**Status:** 🔧 **CONFIGURATION FIX** - Update Vercel dashboard settings

