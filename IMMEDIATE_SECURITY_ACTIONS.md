# 🚨 IMMEDIATE SECURITY ACTIONS - Step by Step

## ⚠️ **CRITICAL: Do These NOW**

Follow these steps in order to secure your application.

---

## 🔴 **STEP 1: Rotate Supabase Service Role Key** (5 minutes)

### **Action Required:**

1. **Go to Supabase Dashboard:**
   - Visit: https://supabase.com/dashboard
   - Sign in to your account

2. **Navigate to API Settings:**
   - Select your project: `andmtvsqqomgwphotdwf`
   - Click: **Settings** (gear icon in sidebar)
   - Click: **API** tab

3. **Reset Service Role Key:**
   - Scroll to **"Service role"** section
   - Click **"Reset service role key"** button
   - **⚠️ WARNING:** This will invalidate the old key immediately
   - **Copy the new key** - you'll need it for Step 2

4. **Save the New Key Securely:**
   - Open: `tantalus-boxing-club/.env.local`
   - Update this line:
     ```env
     SUPABASE_SERVICE_ROLE_KEY=your-new-key-here
     ```
   - Save the file
   - **DO NOT commit this file to Git!**

**✅ Done when:** Old key is revoked and new key is saved locally

---

## 🔴 **STEP 2: Remove Secret from Git History** (10 minutes)

### **Why This Matters:**
The exposed key is still visible in your Git history on GitHub. Anyone can see it by looking at past commits.

### **Action Required:**

Run these commands in PowerShell:

```powershell
# Navigate to your repository
cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club

# Remove the secret from ALL Git history
$env:FILTER_BRANCH_SQUELCH_WARNING=1
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch test-registration-flow.js test-real-registration.js test-admin-login.js check-users.js create-admin-proper.js ENV_TEMPLATE.txt SKIP_TO_NEXTJS.md CURRENT_STATUS.md" --prune-empty --tag-name-filter cat -- --all

# Force push to GitHub (this rewrites history)
git push origin main --force
```

**⚠️ WARNING:** 
- This rewrites Git history
- Make sure you've completed Step 1 first (rotated the key)
- This will update GitHub with cleaned history

**✅ Done when:** Git history is cleaned and pushed to GitHub

---

## 🔴 **STEP 3: Set Environment Variables in Vercel** (5 minutes)

### **After Your Build Completes:**

1. **Go to Vercel Dashboard:**
   - Visit: https://vercel.com/dashboard
   - Sign in

2. **Navigate to Your Project:**
   - Find: `Tantalus-Boxing-Club` project
   - Click on it

3. **Go to Settings:**
   - Click: **Settings** tab
   - Click: **Environment Variables** in sidebar

4. **Add These Variables:**

   **Variable 1:**
   - Name: `REACT_APP_SUPABASE_URL`
   - Value: `https://andmtvsqqomgwphotdwf.supabase.co`
   - Environment: ✅ Production, ✅ Preview, ✅ Development
   - Click: **Save**

   **Variable 2:**
   - Name: `REACT_APP_SUPABASE_ANON_KEY`
   - Value: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzNDYwNTIsImV4cCI6MjA3NjkyMjA1Mn0.qIGPbceA5xPchQb3wtQu3OU0ngoMc7TjcTCxUQo9C5o`
   - Environment: ✅ Production, ✅ Preview, ✅ Development
   - Click: **Save**

   **⚠️ DO NOT add:**
   - ❌ `SUPABASE_SERVICE_ROLE_KEY` - This is server-side only and should NEVER be in client-side code

5. **Redeploy:**
   - Go to: **Deployments** tab
   - Click: **"..."** on latest deployment
   - Click: **"Redeploy"**
   - This applies the new environment variables

**✅ Done when:** Environment variables are set and deployment is redeployed

---

## 🔍 **STEP 4: Verify Security** (5 minutes)

### **Check These:**

1. **Verify Old Key Doesn't Work:**
   - Try using the old key in a test script
   - It should fail/be rejected

2. **Check GitHub:**
   - Visit: https://github.com/Talley47/Tantalus-Boxing-Club
   - Search for the old key - it should NOT be found
   - Check commit history - secret should be removed

3. **Check Supabase Logs:**
   - Go to: Supabase Dashboard → Logs → Auth Logs
   - Look for any suspicious activity
   - Check API Logs for unusual requests

4. **Test Your App:**
   - Visit your Vercel deployment URL
   - Verify login/registration works
   - Check browser console for errors

**✅ Done when:** All checks pass

---

## 📋 **Quick Checklist**

- [ ] **Step 1:** Rotated Supabase Service Role Key
- [ ] **Step 1:** Updated `.env.local` with new key
- [ ] **Step 2:** Removed secret from Git history
- [ ] **Step 2:** Force pushed cleaned history to GitHub
- [ ] **Step 3:** Added environment variables to Vercel
- [ ] **Step 3:** Redeployed Vercel with new variables
- [ ] **Step 4:** Verified old key doesn't work
- [ ] **Step 4:** Checked GitHub for exposed secrets
- [ ] **Step 4:** Reviewed Supabase logs
- [ ] **Step 4:** Tested deployed app

---

## 🆘 **If You Need Help**

### **Rotating Key:**
- Supabase Docs: https://supabase.com/docs/guides/platform/security
- Support: https://supabase.com/support

### **Git History:**
- See: `SECURITY_REMEDIATION.md` for detailed commands
- Git Docs: https://git-scm.com/docs/git-filter-branch

### **Vercel Environment Variables:**
- Vercel Docs: https://vercel.com/docs/concepts/projects/environment-variables
- Support: https://vercel.com/support

---

## ⚠️ **IMPORTANT REMINDERS**

1. **Never commit secrets** to Git
2. **Always use environment variables** for sensitive data
3. **Rotate keys regularly** (every 90 days)
4. **Use different keys** for dev/prod
5. **Monitor logs** for suspicious activity

---

**Status:** ⚠️ **ACTION REQUIRED** - Complete all steps above

**Estimated Time:** 25-30 minutes total

**Priority:** 🔴 **CRITICAL** - Do this immediately

