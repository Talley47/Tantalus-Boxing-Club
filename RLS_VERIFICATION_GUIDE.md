# 🔒 RLS Verification Step-by-Step Guide

Complete guide to verify Row Level Security (RLS) in your Supabase database.

---

## ⏱️ **TIME ESTIMATE: 30 minutes**

---

## 📋 **STEP 1: Access Supabase SQL Editor (2 minutes)**

1. **Go to Supabase Dashboard**:
   - Visit: https://supabase.com/dashboard
   - Sign in to your account

2. **Select Your Project**:
   - Find and click: **`andmtvsqqomgwphotdwf`**

3. **Open SQL Editor**:
   - Click **SQL Editor** in the left sidebar
   - Click **New Query** button (top right)

---

## 📋 **STEP 2: Run Verification Script (5 minutes)**

1. **Open the Verification Script**:
   - File: `database/COMPLETE_RLS_VERIFICATION.sql`
   - Open it in your code editor

2. **Copy the Entire Script**:
   - Select all (Ctrl+A)
   - Copy (Ctrl+C)

3. **Paste into Supabase SQL Editor**:
   - Paste the script into the SQL Editor
   - Click **Run** button (or press `Ctrl+Enter`)

4. **Wait for Results**:
   - The script will run multiple queries
   - Results will appear in tabs below

---

## 📋 **STEP 3: Review Results (10 minutes)**

### **Section 1: Tables WITHOUT RLS** 🔴

**What to Look For**:
- **Expected**: Should show **0 rows**
- **If you see tables**: Those tables need RLS enabled immediately!

**Action if Tables Found**:
```sql
-- For each table shown, run:
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

---

### **Section 2: All Tables with RLS Status** ✅

**What to Look For**:
- All tables should show: `✅ RLS Enabled`
- Policy count should be > 0 for critical tables

**Action if Issues Found**:
- Tables with `❌ RLS Disabled`: Enable RLS (see Section 1)
- Tables with `⚠️ RLS enabled but NO POLICIES`: Add policies (see Section 5)

---

### **Section 3: All RLS Policies** 📋

**What to Look For**:
- Lists all policies on all tables
- Verify critical tables have policies for:
  - SELECT (read)
  - INSERT (create)
  - UPDATE (modify)
  - DELETE (remove)

**Action if Missing Policies**:
- Review existing schema files for policy examples
- Create missing policies

---

### **Section 4: Critical Tables Status** 🔴

**What to Look For**:
- All critical tables should show: `✅ Protected`
- Critical tables include:
  - `fighter_profiles`
  - `fight_records`
  - `chat_messages`
  - `notifications`
  - `training_camp_invitations`
  - `callout_requests`
  - `disputes`
  - `scheduled_fights`
  - `matchmaking_requests`
  - `profiles`
  - `users`
  - `media_assets`

**Action if Unprotected**:
- Enable RLS immediately
- Create appropriate policies

---

### **Section 5: Tables with RLS but NO POLICIES** ⚠️

**What to Look For**:
- **Expected**: Should show **0 rows**
- **If you see tables**: These tables are completely locked!

**Action if Tables Found**:
- These tables have RLS enabled but no policies
- No one can access them (including admins)
- Create policies immediately:

```sql
-- Example: Basic policy for viewing own data
CREATE POLICY "Users can view own data" ON table_name
    FOR SELECT
    USING (auth.uid() = user_id);
```

---

### **Section 6: Policy Coverage Analysis** 📊

**What to Look For**:
- Each table should have policies for:
  - SELECT (if users need to read)
  - INSERT (if users need to create)
  - UPDATE (if users need to modify)
  - DELETE (if users need to delete)

**Action if Missing Coverage**:
- Add policies for missing operations

---

### **Section 7: Summary Report** 📊

**What to Look For**:
- Check the NOTICE messages at the bottom
- Should see:
  - ✅ All tables have RLS enabled!
  - ✅ All critical tables are protected!
  - ✅ X RLS policies are configured.

**If You See Warnings**:
- Follow the instructions in the warnings
- Fix issues and re-run script

---

## 📋 **STEP 4: Fix Any Issues (10 minutes)**

### **If Tables Don't Have RLS**:

1. **Enable RLS**:
   ```sql
   ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
   ```

2. **Create Policies**:
   - Review existing schema files for examples
   - Create policies based on your requirements

### **If Tables Have RLS but No Policies**:

1. **Create Basic Policies**:
   ```sql
   -- Example: Users can view their own data
   CREATE POLICY "Users can view own data" ON table_name
       FOR SELECT
       USING (auth.uid() = user_id);
   
   -- Example: Users can insert their own data
   CREATE POLICY "Users can insert own data" ON table_name
       FOR INSERT
       WITH CHECK (auth.uid() = user_id);
   
   -- Example: Users can update their own data
   CREATE POLICY "Users can update own data" ON table_name
       FOR UPDATE
       USING (auth.uid() = user_id);
   ```

2. **Review Existing Schema Files**:
   - `database/schema.sql` - Has policy examples
   - `database/fix-*-rls-*.sql` - Has specific policy fixes

---

## 📋 **STEP 5: Re-run Verification (3 minutes)**

1. **Clear SQL Editor**:
   - Delete previous query
   - Paste verification script again

2. **Run Again**:
   - Click **Run**
   - Review all sections

3. **Verify All Green**:
   - All sections should show green checkmarks
   - No warnings in summary

---

## ✅ **SUCCESS CRITERIA**

You're done when:

- ✅ Section 1: **0 rows** (no unprotected tables)
- ✅ Section 2: All tables show `✅ RLS Enabled`
- ✅ Section 4: All critical tables show `✅ Protected`
- ✅ Section 5: **0 rows** (no locked tables)
- ✅ Section 7: Summary shows all green checkmarks
- ✅ No warnings in the summary report

---

## 🚨 **COMMON ISSUES & FIXES**

### Issue 1: "Table is completely locked"

**Symptom**: Table has RLS enabled but no policies

**Fix**: Create policies (see Step 4)

---

### Issue 2: "Users can't access their own data"

**Symptom**: RLS policies are too restrictive

**Fix**: Review and adjust policies:

```sql
-- Check existing policies
SELECT * FROM pg_policies WHERE tablename = 'table_name';

-- Drop and recreate if needed
DROP POLICY IF EXISTS "policy_name" ON table_name;
CREATE POLICY "policy_name" ON table_name
    FOR SELECT
    USING (auth.uid() = user_id);
```

---

### Issue 3: "Admins can't access data"

**Symptom**: No admin policies

**Fix**: Add admin policies:

```sql
-- Check if is_admin_user function exists
SELECT proname FROM pg_proc WHERE proname = 'is_admin_user';

-- Create admin policy
CREATE POLICY "Admins can manage all data" ON table_name
    FOR ALL
    USING (is_admin_user())
    WITH CHECK (is_admin_user());
```

---

## 📚 **RESOURCES**

- **Verification Script**: `database/COMPLETE_RLS_VERIFICATION.sql`
- **Schema Files**: `database/schema.sql`
- **Policy Examples**: `database/fix-*-rls-*.sql`
- **Supabase RLS Docs**: https://supabase.com/docs/guides/auth/row-level-security

---

## 🎯 **QUICK REFERENCE**

### Enable RLS:
```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

### Create Basic Policy:
```sql
CREATE POLICY "policy_name" ON table_name
    FOR SELECT
    USING (auth.uid() = user_id);
```

### Check RLS Status:
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### List Policies:
```sql
SELECT * FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'table_name';
```

---

## ✅ **NEXT STEPS**

After RLS verification:

1. ✅ Run security tests (see `SECURITY_TEST_PLAN.md`)
2. ✅ Test with different user accounts
3. ✅ Verify authorization works correctly
4. ✅ Document any issues found
5. ✅ Fix issues and re-verify

---

**Estimated Total Time**: 30 minutes  
**Difficulty**: Easy  
**Priority**: 🔴 Critical
