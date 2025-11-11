# 🔧 Login Troubleshooting Guide

## Issue: Login button just renders / nothing happens

This usually means:
1. Supabase connection issue
2. Admin account doesn't exist
3. Database schema not set up
4. Browser console has errors

---

## 🔍 DIAGNOSTIC STEPS

### Step 1: Check Diagnostic Page

The app now has a built-in diagnostic page!

1. Make sure the React app is running (`npm start`)
2. Go to: **http://localhost:3000/diagnostic**
3. This page will show you:
   - ✅ Environment variables status
   - ✅ Supabase connection status
   - ✅ Admin account status
   - ❌ Any errors

### Step 2: Check Browser Console

1. Open the app at http://localhost:3000
2. Press **F12** to open Developer Tools
3. Click **Console** tab
4. Try to login
5. Look for error messages (usually in red)

Common errors:
- "Invalid login credentials" → Admin account doesn't exist
- "Network error" → Supabase connection issue
- "Database error" → Schema not set up

---

## 🛠️ SOLUTIONS

### Solution 1: Create Admin Account Manually (EASIEST)

1. Go to: https://supabase.com/dashboard/project/andmtvsqqomgwphotdwf/auth/users
2. Click **"Add user"** → **"Create new user"**
3. Enter:
   ```
   Email: admin@tantalusboxing.com
   Password: TantalusAdmin2025!
   ```
4. ✅ **CHECK "Auto Confirm User"** (very important!)
5. Click **"Create user"**

### Solution 2: Run Database Schema

If you haven't already:

1. Go to: https://supabase.com/dashboard/project/andmtvsqqomgwphotdwf/sql/new
2. Open the file: `tantalus-boxing-club/database/schema-fixed.sql`
3. Copy **ALL** contents
4. Paste into SQL Editor
5. Click **"Run"**
6. Wait for "Success" message

### Solution 3: Check Supabase Email Settings

1. Go to: https://supabase.com/dashboard/project/andmtvsqqomgwphotdwf/auth/providers
2. Click on **"Email"**
3. Make sure:
   - ✅ "Enable Email provider" is **ON**
   - ❌ "Confirm email" is **OFF** (for development)
4. Click **"Save"**

### Solution 4: Verify Supabase Project is Active

1. Go to: https://supabase.com/dashboard/project/andmtvsqqomgwphotdwf
2. Check if project status shows "Active" (green)
3. If "Paused", click "Restore" (free tier auto-pauses after inactivity)

---

## ✅ QUICK TEST

Once admin account is created, test it:

1. Go to: http://localhost:3000/login
2. Enter:
   - Email: `admin@tantalusboxing.com`
   - Password: `TantalusAdmin2025!`
3. Click "Login"
4. Should redirect to dashboard

---

## 🐛 Still Not Working?

### Check These:

1. **Browser Console** (F12 → Console tab)
   - Look for error messages
   - Check for network errors

2. **Network Tab** (F12 → Network tab)
   - Filter by "Fetch/XHR"
   - Try login
   - Look for failed requests (red)
   - Click on failed request to see error details

3. **Supabase Logs**
   - Go to: https://supabase.com/dashboard/project/andmtvsqqomgwphotdwf/logs/edge-logs
   - Try to login
   - Check for authentication errors

---

## 📋 Checklist

- [ ] React app is running (`npm start`)
- [ ] Go to http://localhost:3000/diagnostic - all checks green?
- [ ] Supabase project is active (not paused)
- [ ] Database schema has been run
- [ ] Admin user created in Supabase → Authentication → Users
- [ ] Email provider is enabled
- [ ] Browser console shows no errors

---

## 🚀 Next Steps

Once login works:
1. Test registration flow
2. Configure Next.js app
3. Complete migration

**Please check http://localhost:3000/diagnostic and let me know what you see!** 🔍


