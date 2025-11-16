# CSP Deployment Fix - Vercel Live Script Error

## 🔴 **Current Error**

```
Loading the script 'https://vercel.live/_next-live/feedback/feedback.js' violates the following Content Security Policy directive: "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.supabase.co". Note that 'script-src-elem' was not explicitly set, so 'script-src' is used as a fallback.
```

## ✅ **Root Cause**

The error shows the **old CSP** is still active:
- ❌ Missing `https://vercel.live` in `script-src`
- ❌ Missing `script-src-elem` directive
- ✅ The fix is already in `middleware.ts` but **not deployed yet**

---

## 🚀 **Solution: Deploy the Changes**

### **Step 1: Verify Changes Are Committed**

```bash
cd tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
git status
```

You should see `middleware.ts` and `lib/security.ts` as modified.

### **Step 2: Commit and Push**

```bash
git add middleware.ts lib/security.ts
git commit -m "Fix CSP: Add script-src-elem and Vercel domains for Vercel Live"
git push
```

### **Step 3: Wait for Vercel Deployment**

1. Go to your Vercel dashboard
2. Wait for the deployment to complete
3. Check deployment logs for any errors

### **Step 4: Clear Browser Cache**

After deployment:
1. **Hard Refresh:** `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)
2. Or use **Incognito/Private Mode** to test
3. Or **Clear Cache:** DevTools → Application → Clear Storage → Clear site data

---

## 🔍 **Verify the Fix**

### **Method 1: Check Response Headers**

1. Open DevTools (F12) → **Network** tab
2. Reload the page
3. Click on the main document request (usually `(index)` or your domain)
4. Check **Response Headers**
5. Look for `Content-Security-Policy` header
6. Verify it includes:
   - ✅ `script-src-elem 'self' 'unsafe-inline' https://*.supabase.co https://vercel.live https://*.vercel.live https://*.vercel-insights.com`
   - ✅ `script-src` includes `https://vercel.live https://*.vercel.live https://*.vercel-insights.com`

### **Method 2: Check Console**

After deployment and cache clear:
- ✅ No CSP errors should appear
- ✅ Vercel Live feedback script should load
- ✅ Supabase scripts should work

---

## 📋 **Current CSP Configuration (in middleware.ts)**

The correct CSP is already in the code:

```javascript
const csp = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://vercel.live https://*.vercel.live https://*.vercel-insights.com https://*.supabase.co",
  "script-src-elem 'self' 'unsafe-inline' https://*.supabase.co https://vercel.live https://*.vercel.live https://*.vercel-insights.com",
  "script-src-attr 'self' 'unsafe-inline'",
  // ... rest of CSP
].join('; ')
```

---

## ⚠️ **If Error Persists After Deployment**

### **Check 1: Verify Middleware is Running**

The middleware should run for all routes. Check:
- ✅ `middleware.ts` exists in the Next.js app root
- ✅ `matcher` config is not commented out
- ✅ No errors in Vercel deployment logs

### **Check 2: Check for Conflicting CSPs**

If `vercel.json` in the root directory has CSP headers, it might conflict:
- The root `vercel.json` is for the **old React app**
- The Next.js app should use **middleware.ts** for CSP
- If both are active, the `vercel.json` might override

**Solution:** Either:
1. Remove CSP from root `vercel.json` (if not needed)
2. Or ensure Next.js app is in a subdirectory and has its own `vercel.json`

### **Check 3: Browser Cache**

Sometimes browsers cache CSP headers aggressively:
1. Use **Incognito/Private Mode**
2. Or **Clear All Site Data:**
   - DevTools → Application → Storage → Clear site data
3. Or **Disable Cache** in DevTools Network tab (while DevTools is open)

---

## 🎯 **Quick Test**

After deployment, test in incognito mode:
1. Open incognito/private window
2. Navigate to your Vercel URL
3. Open DevTools → Console
4. Check for CSP errors
5. If no errors → ✅ Fix is working!

---

## 📝 **Summary**

- ✅ **Code is fixed** - `middleware.ts` has correct CSP
- ⏳ **Needs deployment** - Changes must be pushed to Vercel
- 🔄 **Clear cache** - After deployment, clear browser cache
- ✅ **Verify** - Check Response Headers to confirm new CSP is active

---

**Last Updated:** 2025-01-16

