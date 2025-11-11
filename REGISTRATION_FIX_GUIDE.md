# Registration Fix Guide

## 🚨 CRITICAL ISSUE: Supabase Not Configured

The fighter profile creation is failing because Supabase environment variables are not set up.

## ✅ IMMEDIATE FIX REQUIRED

### Step 1: Create Environment File
Create a file named `.env.local` in the `tantalus-boxing-club` directory with your Supabase credentials:

```
REACT_APP_SUPABASE_URL=https://your-project-id.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here
```

### Step 2: Get Your Supabase Credentials
1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** → **API**
4. Copy the following:
   - **Project URL** → Use as `REACT_APP_SUPABASE_URL`
   - **anon public** key → Use as `REACT_APP_SUPABASE_ANON_KEY`

### Step 3: Set Up Database Schema
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `database/schema-fixed.sql`
4. Click **Run** to execute the schema

### Step 4: Restart Development Server
1. Stop the current server (Ctrl+C in terminal)
2. Run `npm start` again
3. Go to `http://localhost:3000/register`

## 🔍 DEBUGGING STEPS

### Check Console Errors
1. Open browser developer tools (F12)
2. Go to Console tab
3. Try to register a fighter
4. Look for error messages

### Common Error Messages:
- **"Supabase not configured"** → Environment variables missing
- **"Invalid API key"** → Wrong Supabase credentials
- **"Failed to create account"** → Database connection issue
- **"duplicate key value violates unique constraint"** → Email already exists

## 🛠️ TROUBLESHOOTING

### If Registration Still Loops:
1. Check browser console for errors
2. Verify Supabase project is active
3. Ensure database schema is properly set up
4. Check that RLS policies are enabled

### If Database Errors Occur:
1. Verify all tables exist in Supabase
2. Check that RLS policies are configured
3. Ensure user has proper permissions

## 📋 TESTING CHECKLIST

- [ ] Environment variables configured
- [ ] Database schema executed
- [ ] Development server running on port 3000
- [ ] No console errors
- [ ] Registration form loads properly
- [ ] Fighter profile creation succeeds
- [ ] User redirected to home page after registration

## 🚀 EXPECTED BEHAVIOR

After proper setup:
1. Fill out registration form
2. Complete both steps (Account + Fighter Profile)
3. Fighter profile created in database
4. User automatically logged in
5. Redirected to home page
6. Navigation menu appears

## 📞 SUPPORT

If issues persist:
1. Check browser console for specific error messages
2. Verify Supabase project is active and accessible
3. Ensure database permissions are properly configured
4. Test with a simple email/password combination

