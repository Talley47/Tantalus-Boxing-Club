# ⚡ QUICK SECURITY FIX - Copy & Paste

## 🚨 **DO THESE 3 THINGS NOW**

---

### **1️⃣ Rotate Supabase Key** (5 min)

**Go to:** https://supabase.com/dashboard → Your Project → Settings → API

**Click:** "Reset service role key"

**Update:** `tantalus-boxing-club/.env.local`
```env
SUPABASE_SERVICE_ROLE_KEY=your-new-key-here
```

---

### **2️⃣ Remove Secret from Git** (2 min)

**Run this script:**
```powershell
cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
.\remove-secret-from-history.ps1
```

**Or manually:**
```powershell
cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
$env:FILTER_BRANCH_SQUELCH_WARNING=1
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch test-registration-flow.js test-real-registration.js test-admin-login.js check-users.js create-admin-proper.js ENV_TEMPLATE.txt SKIP_TO_NEXTJS.md CURRENT_STATUS.md" --prune-empty --tag-name-filter cat -- --all
git push origin main --force
```

---

### **3️⃣ Set Vercel Environment Variables** (5 min)

**After build completes:**

1. Go to: https://vercel.com/dashboard → Your Project → Settings → Environment Variables

2. **Add these:**
   - `REACT_APP_SUPABASE_URL` = `https://andmtvsqqomgwphotdwf.supabase.co`
   - `REACT_APP_SUPABASE_ANON_KEY` = `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzNDYwNTIsImV4cCI6MjA3NjkyMjA1Mn0.qIGPbceA5xPchQb3wtQu3OU0ngoMc7TjcTCxUQo9C5o`

3. **Redeploy** your project

---

## ✅ **DONE!**

Total time: ~12 minutes

See `IMMEDIATE_SECURITY_ACTIONS.md` for detailed steps.

