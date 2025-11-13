# 🚨 URGENT: Rotate Supabase Service Role Key NOW

## ⚠️ **CRITICAL SECURITY ALERT**

Your Supabase Service Role Key was exposed in `UPDATE_ENV_LOCAL.md` and has been detected as a public leak.

**Exposed Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...c78wDF-n_e3BlPdyOLlEkK-U35GPYwLZYzWmptf4fbc`

---

## 🔴 **IMMEDIATE ACTIONS REQUIRED**

### **Step 1: Rotate the Key in Supabase** (5 minutes)

1. **Go to:** https://supabase.com/dashboard
2. **Select project:** `andmtvsqqomgwphotdwf`
3. **Navigate to:** Settings → API
4. **Find:** "Service role secret" section
5. **Click:** "Reset service role key" or "Regenerate JWT secret"
6. **⚠️ WARNING:** This will invalidate ALL existing keys (anon + service role)
7. **Copy the NEW service role key** - you'll need it

---

### **Step 2: Update Local Environment** (2 minutes)

1. **Open:** `tantalus-boxing-club/.env.local`
2. **Update:**
   ```env
   SUPABASE_SERVICE_ROLE_KEY=your-NEW-service-role-key-here
   ```
3. **Also update anon key** (if JWT secret was regenerated):
   ```env
   REACT_APP_SUPABASE_ANON_KEY=your-NEW-anon-key-here
   ```
4. **Save** the file

---

### **Step 3: Update Vercel Environment Variables** (5 minutes)

1. **Go to:** https://vercel.com/dashboard
2. **Select project:** Tantalus-Boxing-Club
3. **Navigate to:** Settings → Environment Variables
4. **Update:**
   - `REACT_APP_SUPABASE_ANON_KEY` = (your new anon key)
   - **DO NOT add** `SUPABASE_SERVICE_ROLE_KEY` (server-side only)
5. **Redeploy** your project

---

### **Step 4: Remove from Git History** (10 minutes)

The exposed key is still in Git history. Remove it:

```powershell
cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club

# Remove UPDATE_ENV_LOCAL.md from Git history
$env:FILTER_BRANCH_SQUELCH_WARNING=1
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch UPDATE_ENV_LOCAL.md" --prune-empty --tag-name-filter cat -- --all

# Force push to rewrite history
git push origin main --force
```

**⚠️ WARNING:** This rewrites Git history. Make sure you've rotated the key first!

---

## ✅ **What Was Fixed**

- ✅ Removed exposed key from `UPDATE_ENV_LOCAL.md`
- ✅ Replaced with placeholder text
- ✅ Added security warning

---

## 🔍 **Check for Other Exposures**

Run this to check if the key appears elsewhere:

```powershell
cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
git log --all --full-history -p | Select-String -Pattern "c78wDF-n_e3BlPdyOLlEkK"
```

---

## 📋 **Verification Checklist**

- [ ] Rotated service role key in Supabase
- [ ] Updated `.env.local` with new key
- [ ] Updated Vercel environment variables
- [ ] Removed key from Git history
- [ ] Tested application still works
- [ ] Verified old key no longer works

---

## 🚨 **Why This Matters**

The Service Role Key has **full database access** and **bypasses Row Level Security**. Anyone with this key can:
- Read/write/delete any data
- Modify user accounts
- Access sensitive information
- Bypass all security policies

**Rotate it immediately!**

