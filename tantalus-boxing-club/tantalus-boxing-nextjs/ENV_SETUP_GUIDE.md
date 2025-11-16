# 🔐 Environment Variables Setup Guide
## For Local Development and Vercel Deployment

---

## 📋 **Required Environment Variables**

### **For Next.js App (Use `NEXT_PUBLIC_*` prefix)**

Create a file named `.env.local` in this directory (`tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs/`) with:

```env
# Supabase Configuration (REQUIRED)
NEXT_PUBLIC_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo

# Optional: Service Role Key (for server-side admin operations)
# Get from Supabase Dashboard → Settings → API → service_role key
# SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Optional: Upstash Redis (for rate limiting)
# Create account at https://upstash.com and create a Redis database
# UPSTASH_REDIS_REST_URL=https://your-redis-url.upstash.io
# UPSTASH_REDIS_REST_TOKEN=your-redis-token

# Optional: Sentry (for error tracking)
# NEXT_PUBLIC_SENTRY_DSN=your_sentry_dsn_here

# Optional: PostHog (for analytics)
# NEXT_PUBLIC_POSTHOG_KEY=your_posthog_key_here
# NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com

# Application Configuration
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

---

## 🚀 **Quick Setup Steps**

### **Step 1: Create .env.local File**

**Windows PowerShell:**
```powershell
cd tantalus-boxing-club\tantalus-boxing-club\tantalus-boxing-nextjs
New-Item -Path .env.local -ItemType File -Force
```

**Or manually:**
1. Navigate to: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs/`
2. Create a new file named `.env.local`
3. Copy the content above into it
4. Save the file

### **Step 2: Verify File Created**

```powershell
# Check if file exists
Test-Path .env.local
# Should return: True
```

### **Step 3: Test Build**

```powershell
npm run build
```

If build succeeds, you're ready to run!

### **Step 4: Run Development Server**

```powershell
npm run dev
```

Visit: http://localhost:3000

---

## 🌐 **For Vercel Deployment**

### **Step 1: Go to Vercel Dashboard**

1. Visit: https://vercel.com/dashboard
2. Sign in
3. Select your project: **Tantalus-Boxing-Club**

### **Step 2: Add Environment Variables**

1. Click: **Settings** tab
2. Click: **Environment Variables** (left sidebar)
3. Click: **"Add New"** button

**Add Variable 1:**
- **Key:** `NEXT_PUBLIC_SUPABASE_URL`
- **Value:** `https://andmtvsqqomgwphotdwf.supabase.co`
- **Environment:** ✅ Production, ✅ Preview, ✅ Development
- Click: **Save**

**Add Variable 2:**
- **Key:** `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
- **Environment:** ✅ Production, ✅ Preview, ✅ Development
- Click: **Save**

### **Step 3: Redeploy**

1. Go to: **Deployments** tab
2. Click: **"..."** (three dots) on latest deployment
3. Click: **"Redeploy"**
4. Uncheck: **"Use existing Build Cache"** (important!)
5. Click: **"Redeploy"**

Wait 2-3 minutes for deployment to complete.

---

## ⚠️ **Important Notes**

### **Variable Name Differences:**

- **React App (old):** Uses `REACT_APP_*` prefix
- **Next.js App (new):** Uses `NEXT_PUBLIC_*` prefix

**⚠️ CRITICAL:** Make sure you use `NEXT_PUBLIC_*` for the Next.js app!

### **Optional Variables:**

- **Upstash Redis:** App will work without it (rate limiting disabled gracefully)
- **Sentry:** Optional error tracking
- **PostHog:** Optional analytics

### **Never Commit .env.local:**

The `.env.local` file is already in `.gitignore` - never commit it to Git!

---

## ✅ **Verification**

After setting up environment variables:

1. **Local Development:**
   ```powershell
   npm run dev
   # Should start without errors
   # Visit http://localhost:3000
   ```

2. **Production Build:**
   ```powershell
   npm run build
   # Should complete successfully
   ```

3. **Vercel Deployment:**
   - Check deployment logs for errors
   - Visit your Vercel URL
   - Test login/registration
   - Check browser console (F12) for errors

---

## 🔍 **Troubleshooting**

### **Build Fails with "Missing Supabase environment variables":**
- ✅ Check `.env.local` file exists
- ✅ Verify variable names start with `NEXT_PUBLIC_`
- ✅ Check for typos in variable names
- ✅ Restart dev server after creating `.env.local`

### **App Works Locally but Not on Vercel:**
- ✅ Verify variables are set in Vercel dashboard
- ✅ Check you selected all environments (Production, Preview, Development)
- ✅ Redeploy after adding variables
- ✅ Uncheck "Use existing Build Cache" when redeploying

### **"Invalid API key" Error:**
- ✅ Verify you copied the correct anon key
- ✅ Check for extra spaces when pasting
- ✅ Make sure variable name is exactly: `NEXT_PUBLIC_SUPABASE_ANON_KEY`

---

**Last Updated:** 2025-01-16

