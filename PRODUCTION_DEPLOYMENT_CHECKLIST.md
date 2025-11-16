# 🚀 PRODUCTION DEPLOYMENT CHECKLIST
## Tantalus Boxing Club - Next.js Application

**Last Updated:** 2025-01-16  
**Status:** ⚠️ **NOT READY** - Complete all critical items before deployment

---

## 📋 **QUICK STATUS OVERVIEW**

| Category | Status | Priority |
|----------|--------|----------|
| Environment Variables | ❌ **MISSING** | 🔴 **CRITICAL** |
| Database Schema | ⚠️ **NEEDS VERIFICATION** | 🔴 **CRITICAL** |
| Security Configuration | ⚠️ **INCOMPLETE** | 🔴 **CRITICAL** |
| Build & Testing | ⚠️ **NOT TESTED** | 🟡 **HIGH** |
| Monitoring & Logging | ✅ **CONFIGURED** | 🟢 **MEDIUM** |

---

## 🔴 **CRITICAL ITEMS (Must Complete Before Deployment)**

### **1. Environment Variables Configuration** ❌ **BLOCKING**

#### **For Next.js App (Production):**

The Next.js app uses different environment variable names than the React app:

**Required Variables in Vercel Dashboard:**
- `NEXT_PUBLIC_SUPABASE_URL` (NOT `REACT_APP_SUPABASE_URL`)
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (NOT `REACT_APP_SUPABASE_ANON_KEY`)
- `SUPABASE_SERVICE_ROLE_KEY` (Server-side only)
- `UPSTASH_REDIS_REST_URL` (For rate limiting)
- `UPSTASH_REDIS_REST_TOKEN` (For rate limiting)
- `NEXT_PUBLIC_SENTRY_DSN` (Optional - error tracking)
- `NEXT_PUBLIC_POSTHOG_KEY` (Optional - analytics)

**Action Required:**
1. Go to: https://vercel.com/dashboard
2. Select project: **Tantalus-Boxing-Club**
3. Navigate to: **Settings → Environment Variables**
4. Add all required variables above
5. **Important:** Use `NEXT_PUBLIC_*` prefix for client-side variables
6. Redeploy after adding variables

**Values to Use:**
```
NEXT_PUBLIC_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
```

**⚠️ CRITICAL:** Without these, the app will not function in production!

---

### **2. Database Schema Verification** ⚠️ **BLOCKING**

#### **Schema Files Available:**
- ✅ `database/schema-fixed.sql` - **RECOMMENDED** (33 tables, comprehensive)
- ✅ `database/COMPLETE_WORKING_SCHEMA.sql` - Minimal version (2 tables only)
- ✅ `database/minimal-schema.sql` - Quick start (2 tables only)

#### **Action Required:**

**Option A: Full Schema (Recommended for Production)**
1. Go to: https://supabase.com/dashboard/project/andmtvsqqomgwphotdwf/sql/new
2. Open: `database/schema-fixed.sql`
3. Copy entire file (Ctrl+A, Ctrl+C)
4. Paste into Supabase SQL Editor
5. Click **"Run"**
6. Wait for "Success" message

**Option B: Verify Existing Schema**
1. Go to: Supabase Dashboard → **Database → Tables**
2. Verify these critical tables exist:
   - ✅ `profiles`
   - ✅ `fighter_profiles`
   - ✅ `fight_records`
   - ✅ `matchmaking_requests`
   - ✅ `tournaments`
   - ✅ `tournament_participants`
   - ✅ `notifications`
   - ✅ `disputes`
   - ✅ `training_camps`
   - ✅ `media_assets`

**If tables are missing, run Option A above.**

---

### **3. Row Level Security (RLS) Verification** ⚠️ **CRITICAL**

#### **Action Required:**
1. Go to: Supabase Dashboard → **SQL Editor**
2. Run: `database/verify-rls-security.sql`
3. Verify output shows:
   - ✅ All tables have RLS enabled
   - ✅ No tables without RLS policies
   - ✅ Critical tables have proper policies

**Critical Tables to Verify:**
- `fighter_profiles` - Users can only edit their own
- `fight_records` - Users can only add records for themselves
- `disputes` - Users can only see disputes they're involved in
- `notifications` - Users can only see their own notifications
- `matchmaking_requests` - Users can only see their requests
- `training_camp_invitations` - Users can only see their invitations

**If RLS is not enabled, run:**
```sql
ALTER TABLE [table_name] ENABLE ROW LEVEL SECURITY;
```

---

### **4. Supabase Authentication Settings** ⚠️ **REQUIRED**

#### **Action Required:**
In **Supabase Dashboard → Authentication → Settings**:

- [ ] **Enable Email Confirmations**: ON (for production)
- [ ] **Minimum Password Length**: 8
- [ ] **Password Requirements**:
  - [ ] Require uppercase: Yes
  - [ ] Require lowercase: Yes
  - [ ] Require numbers: Yes
  - [ ] Require special characters: Yes (recommended)

---

### **5. Rate Limiting Configuration** ⚠️ **REQUIRED**

#### **Action Required:**
1. **Upstash Redis Setup** (For Next.js rate limiting):
   - Create account: https://upstash.com
   - Create Redis database
   - Copy `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`
   - Add to Vercel environment variables

2. **Supabase Rate Limiting**:
   - Go to: Supabase Dashboard → **Settings → API**
   - Enable Rate Limiting
   - Set limits:
     - Anonymous requests: 100/minute
     - Authenticated requests: 200/minute
     - File uploads: 10/minute

---

### **6. Production Build Test** ⚠️ **REQUIRED**

#### **Action Required:**
```bash
cd tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
npm ci
npm run build
```

**Verify:**
- [ ] Build completes without errors
- [ ] No TypeScript errors
- [ ] No missing dependencies
- [ ] Build output exists in `.next` folder

**Test Production Build Locally:**
```bash
npm start
# Visit http://localhost:3000
```

**Check:**
- [ ] App loads correctly
- [ ] No console errors
- [ ] Login page accessible
- [ ] API routes respond

---

### **7. Vercel Configuration** ⚠️ **REQUIRED**

#### **Current Issue:**
The `vercel.json` file is configured for the **React app**, not the **Next.js app**.

#### **Action Required:**

**For Next.js App:**
- Next.js auto-detects configuration
- Remove or update `vercel.json` if it conflicts
- Next.js uses `next.config.ts` for configuration

**Verify Vercel Project Settings:**
1. Go to: Vercel Dashboard → **Settings → General**
2. Verify:
   - **Framework Preset**: Next.js
   - **Build Command**: `npm run build` (or auto-detected)
   - **Output Directory**: `.next` (auto-detected)
   - **Install Command**: `npm ci` (or auto-detected)

**If deploying Next.js app:**
- Ensure Vercel is pointing to: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs`
- NOT: `tantalus-boxing-club` (that's the React app)

---

## 🟡 **HIGH PRIORITY ITEMS**

### **8. Security Headers** ✅ **CONFIGURED**

Security headers are configured in `vercel.json` (for React app) or should be in `next.config.ts` (for Next.js app).

**Verify after deployment:**
```bash
curl -I https://your-domain.vercel.app
```

**Check for:**
- ✅ `X-Frame-Options: DENY`
- ✅ `X-Content-Type-Options: nosniff`
- ✅ `Strict-Transport-Security`
- ✅ `Content-Security-Policy`

---

### **9. Dependency Security Audit** ⚠️ **REQUIRED**

#### **Action Required:**
```bash
cd tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
npm audit
npm audit fix
```

**Verify:**
- [ ] No **critical** vulnerabilities
- [ ] No **high** vulnerabilities (fix if possible)
- [ ] Review and fix **medium** vulnerabilities

---

### **10. Error Tracking Setup** ✅ **OPTIONAL**

Sentry is configured but requires:
- `NEXT_PUBLIC_SENTRY_DSN` environment variable
- Sentry account setup

**Action (Optional):**
1. Create Sentry account: https://sentry.io
2. Create project
3. Copy DSN
4. Add to Vercel environment variables

---

### **11. Analytics Setup** ✅ **OPTIONAL**

PostHog is configured but requires:
- `NEXT_PUBLIC_POSTHOG_KEY` environment variable
- PostHog account setup

**Action (Optional):**
1. Create PostHog account: https://posthog.com
2. Get API key
3. Add to Vercel environment variables

---

## 🟢 **MEDIUM PRIORITY ITEMS**

### **12. Domain Configuration** ⚠️ **OPTIONAL**

- [ ] Configure custom domain in Vercel
- [ ] Update DNS records
- [ ] Verify SSL certificate (automatic on Vercel)

---

### **13. Monitoring & Alerts** ✅ **CONFIGURED**

- ✅ Sentry configured (if DSN provided)
- ✅ PostHog configured (if key provided)
- ✅ Structured logging implemented

**Action (Optional):**
- [ ] Set up Sentry alerts
- [ ] Set up PostHog dashboards
- [ ] Configure uptime monitoring

---

### **14. Backup Strategy** ⚠️ **RECOMMENDED**

**Action Required:**
- [ ] Enable Supabase backups (Pro plan)
- [ ] Or set up manual backup schedule
- [ ] Document backup restoration process

---

## 📋 **PRE-DEPLOYMENT TESTING CHECKLIST**

### **Local Testing:**
- [ ] Production build succeeds
- [ ] App runs locally with `npm start`
- [ ] Login flow works
- [ ] Registration flow works
- [ ] Database queries work
- [ ] No console errors
- [ ] No TypeScript errors

### **Feature Testing:**
- [ ] User authentication
- [ ] Fighter profile creation
- [ ] Rankings display
- [ ] Matchmaking system
- [ ] Tournament creation
- [ ] Fight record entry
- [ ] Admin panel access

### **Security Testing:**
- [ ] RLS policies prevent unauthorized access
- [ ] Rate limiting works
- [ ] Input validation works
- [ ] Error messages don't expose sensitive info

---

## 🚀 **DEPLOYMENT STEPS**

### **Step 1: Complete All Critical Items Above**
- [ ] Environment variables set
- [ ] Database schema verified
- [ ] RLS policies verified
- [ ] Production build tested

### **Step 2: Deploy to Vercel**

**Option A: Git Integration (Recommended)**
1. Push code to Git repository
2. Vercel auto-deploys on push
3. Monitor deployment in Vercel dashboard

**Option B: Vercel CLI**
```bash
cd tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
npm install -g vercel
vercel --prod
```

### **Step 3: Verify Deployment**
- [ ] Site loads at Vercel URL
- [ ] HTTPS is active
- [ ] Environment variables loaded
- [ ] Database connection works
- [ ] Login/registration works
- [ ] No console errors

### **Step 4: Post-Deployment Verification**
- [ ] Security headers present
- [ ] Rate limiting active
- [ ] Error tracking working (if configured)
- [ ] Analytics working (if configured)
- [ ] All features functional

---

## ⚠️ **KNOWN ISSUES & BLOCKERS**

### **Current Blockers:**
1. ❌ **Environment Variables Not Set** - App won't function without these
2. ⚠️ **Database Schema May Be Incomplete** - Needs verification
3. ⚠️ **Vercel Configuration** - May be pointing to wrong app (React vs Next.js)
4. ⚠️ **RLS Policies** - Need verification

### **Non-Blocking Issues:**
- ⚠️ Mobile app is only 5% complete (separate project)
- ⚠️ Some optional services (Sentry, PostHog) not configured

---

## 📚 **REFERENCE DOCUMENTATION**

- **Environment Variables**: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs/env.example`
- **Database Schema**: `tantalus-boxing-club/database/schema-fixed.sql`
- **RLS Verification**: `tantalus-boxing-club/database/verify-rls-security.sql`
- **Security Checklist**: `tantalus-boxing-club/PRODUCTION_SECURITY_CHECKLIST.md`
- **Deployment Guide**: `tantalus-boxing-club/DEPLOYMENT_READINESS.md`

---

## ✅ **FINAL CHECKLIST**

Before marking as "Ready for Production":

- [ ] All critical items completed
- [ ] All high priority items completed
- [ ] Production build tested locally
- [ ] Database schema verified
- [ ] RLS policies verified
- [ ] Environment variables set in Vercel
- [ ] Security audit passed
- [ ] All features tested
- [ ] Deployment successful
- [ ] Post-deployment verification passed

---

## 🎯 **ESTIMATED TIME TO PRODUCTION-READY**

- **Critical Items**: 1-2 hours
- **High Priority Items**: 30-60 minutes
- **Testing**: 30-60 minutes
- **Total**: **2-4 hours** of focused work

---

## 📞 **SUPPORT & HELP**

If you encounter issues:
1. Check error logs in Vercel dashboard
2. Check Supabase logs
3. Review this checklist for missed items
4. Check browser console for client-side errors
5. Verify environment variables are set correctly

---

**Status**: ⚠️ **NOT READY FOR PRODUCTION**  
**Last Updated**: 2025-01-16  
**Next Review**: After completing critical items

