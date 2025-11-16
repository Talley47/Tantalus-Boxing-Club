# CSP Fix Verification Guide

## ✅ **CSP Updated in Both Locations**

The Content Security Policy has been updated in:
1. ✅ `middleware.ts` - Primary CSP (used by Next.js middleware)
2. ✅ `lib/security.ts` - Secondary CSP (if used elsewhere)

Both now include:
- ✅ `script-src-elem` explicitly set with Supabase domains
- ✅ `script-src-attr` for inline event handlers
- ✅ All Supabase domains (`https://*.supabase.co`)
- ✅ WebSocket support (`wss://*.supabase.co`)
- ✅ Vercel domains for Live and Analytics

---

## 🔄 **If You're Still Seeing the Error**

### **1. Clear Browser Cache**
The CSP might be cached. Try:
- **Hard Refresh:** `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)
- **Clear Cache:** DevTools → Application → Clear Storage → Clear site data

### **2. Verify Deployment**
If testing on Vercel:
- ✅ Check that the latest code is deployed
- ✅ Verify the deployment includes the updated `middleware.ts`
- ✅ Check Vercel deployment logs for any errors

### **3. Check Browser Console**
Look for the exact CSP violation:
1. Open DevTools (F12)
2. Go to Console tab
3. Find the CSP error
4. Check which directive is being violated
5. Verify which resource is being blocked

### **4. Test CSP Locally**
```bash
cd tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
npm run dev
```
Then check the Network tab → Headers → Response Headers → `Content-Security-Policy`

---

## 📋 **Current CSP Configuration**

```javascript
const csp = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://vercel.live https://*.vercel.live https://*.vercel-insights.com https://*.supabase.co",
  "script-src-elem 'self' 'unsafe-inline' https://*.supabase.co https://vercel.live https://*.vercel.live https://*.vercel-insights.com",
  "script-src-attr 'self' 'unsafe-inline'",
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  "font-src 'self' https://fonts.gstatic.com",
  "img-src 'self' data: https: blob:",
  "media-src 'self' data: https: blob:",
  "connect-src 'self' https://*.supabase.co wss://*.supabase.co https://*.upstash.io https://vercel.live https://*.vercel.live https://*.vercel-insights.com",
  "frame-src 'self' https://vercel.live https://*.vercel.live https://*.supabase.co",
  "frame-ancestors 'none'",
  "worker-src 'self' blob:",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'"
].join('; ')
```

---

## 🔍 **Troubleshooting Steps**

### **Step 1: Verify CSP Header**
1. Open DevTools → Network tab
2. Reload the page
3. Click on the main document request
4. Check Response Headers
5. Look for `Content-Security-Policy` header
6. Verify it includes `script-src-elem`

### **Step 2: Check for Conflicting CSPs**
If you see multiple CSP headers:
- Check if `vercel.json` also sets CSP (for old React app)
- Check if there's a meta tag in HTML
- Only the middleware CSP should be active for Next.js app

### **Step 3: Test Specific Supabase Script**
If a specific Supabase script is blocked:
1. Check the console error message
2. Note the exact URL being blocked
3. Verify it matches `https://*.supabase.co` pattern
4. If not, add the specific domain to CSP

---

## ✅ **Expected Result**

After the fix:
- ✅ No CSP errors in console
- ✅ Supabase scripts load successfully
- ✅ Authentication works
- ✅ All Supabase features function correctly

---

## 🚨 **If Error Persists**

If you're still seeing the error after:
1. ✅ Clearing cache
2. ✅ Verifying deployment
3. ✅ Checking CSP header

Then:
1. **Copy the exact error message** from console
2. **Check which resource is blocked** (exact URL)
3. **Verify the CSP header** in Network tab
4. **Share the details** so we can add the specific domain if needed

---

**Last Updated:** 2025-01-16

