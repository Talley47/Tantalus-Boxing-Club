# 🔐 Supabase Service Role Key Rotation Guide

## ⚠️ **Current Situation**

Supabase has updated their API key management system. The service role key is now managed through **JWT secrets** rather than individual key rotation.

---

## 🔍 **Understanding Your Supabase Setup**

### **What You're Seeing:**

1. **anon public key** - ✅ Safe to expose (this is your `REACT_APP_SUPABASE_ANON_KEY`)
2. **service_role secret** - 🔴 This is the exposed key (shows as `**** **** **** ****`)
3. **"Disable legacy API keys"** option - This is the new way to manage keys

---

## ✅ **Solution: Regenerate JWT Secret**

Since you can't directly reset the service role key, you need to **regenerate the JWT secret**, which will invalidate ALL keys (anon and service role).

### **Step 1: Generate New JWT Secret**

1. **Go to:** Supabase Dashboard → Settings → API
2. **Scroll down** to find **"JWT Settings"** or **"JWT Secret"** section
3. **Click:** "Generate new JWT secret" or "Reset JWT secret"
4. **⚠️ WARNING:** This will invalidate ALL existing keys (anon and service role)
5. **Copy the new JWT secret** - you'll need it

### **Step 2: Get New API Keys**

After regenerating the JWT secret:

1. **New anon key** will be generated automatically
2. **New service role key** will be generated automatically
3. **Copy both keys** from the API settings page

### **Step 3: Update Your Environment Variables**

**Update `.env.local`:**
```env
REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-new-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-new-service-role-key-here
```

**Update Vercel Environment Variables:**
- `REACT_APP_SUPABASE_URL` = `https://andmtvsqqomgwphotdwf.supabase.co`
- `REACT_APP_SUPABASE_ANON_KEY` = (your new anon key)

---

## 🔄 **Alternative: Use Secret API Keys (Recommended)**

Supabase now recommends using **Secret API keys** instead of legacy JWT-based keys.

### **How to Set Up Secret API Keys:**

1. **Go to:** Supabase Dashboard → Settings → API
2. **Look for:** "Secret API Keys" section (might be under "API Keys")
3. **Create a new secret key:**
   - Name: `Production Service Key`
   - Permissions: Select appropriate scopes
   - Click "Create"
4. **Copy the new secret key** - this replaces your service role key

### **Update Your Code:**

If using Secret API keys, update your scripts to use:
```javascript
const supabaseServiceRoleKey = process.env.SUPABASE_SECRET_KEY; // Instead of SUPABASE_SERVICE_ROLE_KEY
```

---

## 🚨 **If You Can't Find JWT Settings**

### **Option 1: Contact Supabase Support**

1. Go to: https://supabase.com/support
2. Explain: "I need to rotate my service role key because it was exposed in a public repository"
3. They can help you regenerate it

### **Option 2: Check Project Settings**

1. Go to: **Settings** → **General**
2. Look for: **"JWT Secret"** or **"API Keys"** section
3. There might be a "Regenerate" button there

### **Option 3: Disable Legacy Keys (If Safe)**

If you're ready to migrate to Secret API keys:

1. **First:** Set up new Secret API keys
2. **Update:** All your code to use Secret API keys
3. **Then:** Click "Disable legacy API keys"
4. **This will:** Invalidate all old JWT-based keys

---

## 📋 **What Happens When You Regenerate JWT Secret**

- ✅ **All old keys become invalid** (including the exposed one)
- ✅ **New anon key generated** (update your code/Vercel)
- ✅ **New service role key generated** (update your `.env.local`)
- ⚠️ **Your app will break** until you update the keys
- ⚠️ **All users will need to re-authenticate** (if using JWT)

---

## ✅ **Recommended Approach**

### **For Immediate Security:**

1. **Regenerate JWT Secret** (invalidates exposed key immediately)
2. **Get new keys** from API settings
3. **Update `.env.local`** with new service role key
4. **Update Vercel** with new anon key
5. **Redeploy** your application

### **For Long-term:**

1. **Migrate to Secret API Keys** (more secure, better management)
2. **Disable legacy JWT-based keys**
3. **Update all scripts** to use Secret API keys
4. **Set up key rotation schedule** (every 90 days)

---

## 🔍 **Verify Old Key is Invalid**

After regenerating:

1. **Try using old key** in a test script
2. **Should get:** Authentication error or "Invalid API key"
3. **Check Supabase logs** - old key should show as rejected

---

## 📚 **Resources**

- **Supabase API Keys Docs:** https://supabase.com/docs/guides/platform/api-keys
- **JWT Secret Management:** https://supabase.com/docs/guides/platform/security
- **Support:** https://supabase.com/support

---

## ⚠️ **Important Notes**

1. **Regenerating JWT secret** affects ALL keys (anon + service role)
2. **Update both** your local `.env.local` AND Vercel environment variables
3. **Test your app** after updating keys
4. **Keep new keys secure** - never commit to Git

---

**Status:** 🔴 **ACTION REQUIRED** - Regenerate JWT secret to invalidate exposed key

