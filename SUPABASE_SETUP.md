# Supabase Setup Guide

## Issue: Registration Loop Back to Registration Screen

The registration is failing because Supabase environment variables are not configured.

## Solution: Configure Supabase Environment Variables

### Step 1: Create Environment File
Create a file named `.env.local` in the `tantalus-boxing-club` directory with the following content:

```
REACT_APP_SUPABASE_URL=https://your-project-id.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here
```

### Step 2: Get Your Supabase Credentials
1. Go to your Supabase project dashboard
2. Navigate to Settings > API
3. Copy the following values:
   - **Project URL** → Use as `REACT_APP_SUPABASE_URL`
   - **anon/public key** → Use as `REACT_APP_SUPABASE_ANON_KEY`

### Step 3: Update the Environment File
Replace the placeholder values in `.env.local` with your actual Supabase credentials.

### Step 4: Restart the Development Server
After updating the environment variables:
1. Stop the current development server (Ctrl+C)
2. Run `npm start` again

### Step 5: Test Registration
1. Go to `http://localhost:3000/register`
2. Fill out the registration form
3. The fighter profile should now be created successfully

## Database Schema
Make sure you have run the database schema from `database/schema-fixed.sql` in your Supabase SQL editor.

## Troubleshooting
- Check the browser console for any error messages
- Verify your Supabase project is active and accessible
- Ensure the database tables exist (run the schema script)
- Check that RLS policies are properly configured

