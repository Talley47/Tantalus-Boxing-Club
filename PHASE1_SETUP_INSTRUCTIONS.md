# 🚀 PHASE 1: Fix Current App - Complete Setup Guide

This guide will help you set up the existing Create React App to work properly with Supabase.

## Prerequisites

- Node.js 16+ installed
- A Supabase account (free tier is fine)
- Git installed

## Step 1: Create Supabase Project

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Fill in the details:
   - **Name**: Tantalus Boxing Club
   - **Database Password**: (save this securely)
   - **Region**: Choose closest to your location
4. Wait for the project to be created (takes ~2 minutes)

## Step 2: Get Supabase Credentials

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy these two values:
   - **Project URL** (e.g., `https://xxxxxxxxxxxxx.supabase.co`)
   - **anon/public key** (the long string under "Project API keys")

## Step 3: Create .env.local File

1. In the `tantalus-boxing-club` directory, create a file named `.env.local`
2. Add the following content (replace with your actual values):

```env
REACT_APP_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
REACT_APP_SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE
```

**Example:**
```env
REACT_APP_SUPABASE_URL=https://abcdefghijklmnop.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

3. Save the file

## Step 4: Set Up Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Open the file `tantalus-boxing-club/database/schema-fixed.sql`
4. Copy the entire contents
5. Paste into the Supabase SQL Editor
6. Click "Run" to execute the schema

**Alternative:** Upload the SQL file directly:
- In Supabase dashboard → SQL Editor → Import SQL
- Select `schema-fixed.sql`
- Run the import

## Step 5: Create Admin Account

1. Open a terminal in the `tantalus-boxing-club` directory
2. Run the admin creation script:

```bash
node create-admin.js
```

3. You should see: `✓ Admin account created successfully!`

**Default Admin Credentials:**
- **Email**: `admin@tantalusboxing.com`
- **Password**: `TantalusAdmin2025!`

## Step 6: Install Dependencies

If you haven't already, install all dependencies:

```bash
cd tantalus-boxing-club
npm install
```

## Step 7: Start the Development Server

```bash
npm start
```

The app should now open at `http://localhost:3000`

## Step 8: Test the Application

### 8.1 Test Admin Login
1. Go to `http://localhost:3000`
2. Click "Login"
3. Enter:
   - Email: `admin@tantalusboxing.com`
   - Password: `TantalusAdmin2025!`
4. You should be redirected to the dashboard

### 8.2 Test Registration Flow
1. Click "Logout" (if logged in)
2. Click "Register" or "Sign Up"
3. Fill in the registration form:
   - **Full Name**: Test User
   - **Email**: test@example.com
   - **Password**: TestUser2025!
   - **Confirm Password**: TestUser2025!
4. Fill in the Fighter Profile:
   - **Fighter Name**: Test Fighter
   - **Birthday**: (select a date making you 18-50 years old)
   - **Hometown**: Your City
   - **Stance**: Orthodox/Southpaw/Switch
   - **Height**: e.g., 6 feet 0 inches
   - **Reach**: e.g., 72 inches
   - **Weight**: e.g., 170 lbs
   - **Weight Class**: (select appropriate class)
   - **Trainer**: Test Trainer (optional)
   - **Gym/Team**: Test Gym (optional)
5. Click "Create Account"
6. You should be redirected to the fighter dashboard

## Troubleshooting

### Issue: "Cannot connect to Supabase"
- **Solution**: Verify your `.env.local` file has the correct credentials
- Restart the development server after creating/updating `.env.local`

### Issue: "Admin account already exists"
- **Solution**: This is fine! The admin account was already created
- Try logging in with the credentials

### Issue: "Registration loops back to registration screen"
- **Solution**: 
  1. Check browser console for errors
  2. Verify database schema was created properly
  3. Ensure `fighter_profiles` table exists in Supabase
  4. Check that the weight field is being saved correctly

### Issue: "Database connection test fails"
- **Solution**:
  1. Verify Supabase project is active (not paused)
  2. Check that your API keys are correct
  3. Ensure no typos in the `.env.local` file
  4. Try regenerating the anon key in Supabase dashboard

## Verification Checklist

- [ ] `.env.local` file created with actual Supabase credentials
- [ ] Database schema created in Supabase
- [ ] Admin account created successfully
- [ ] Can log in as admin
- [ ] Can create a new user account
- [ ] Can create a fighter profile
- [ ] Redirected to dashboard after registration
- [ ] No console errors

## What's Next?

Once Phase 1 is complete and the current app is working:
- **Phase 2**: Migrate to Next.js 15 with production-ready architecture
- Deploy to Vercel with CI/CD
- Implement advanced features and monitoring

## Need Help?

If you encounter issues:
1. Check the browser console for error messages
2. Check the terminal where `npm start` is running for errors
3. Verify your Supabase project is not paused (free tier pauses after inactivity)
4. Ensure all dependencies are installed (`npm install`)

---

**Important Files:**
- `.env.local` - Your Supabase credentials (DO NOT COMMIT)
- `create-admin.js` - Script to create admin account
- `database/schema-fixed.sql` - Database schema
- `SUPABASE_SETUP.md` - Detailed Supabase setup guide


