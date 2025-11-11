# 🔍 RLS VERIFICATION GUIDE

## Step-by-Step Instructions

### **Step 1: Access Supabase SQL Editor**

1. Go to: https://supabase.com/dashboard
2. Select your project
3. Click **SQL Editor** in the left sidebar
4. Click **New Query**

---

### **Step 2: Run RLS Verification Script**

1. Open the file: `database/verify-rls-security.sql`
2. Copy the **entire contents** of the file
3. Paste into Supabase SQL Editor
4. Click **Run** (or press Ctrl+Enter)

---

### **Step 3: Review Results**

The script will show you:

#### **Check 1: Tables WITHOUT RLS** ⚠️
- **Expected**: Should return **0 rows**
- **If you see tables**: Those tables need RLS enabled (CRITICAL!)

#### **Check 2: All Tables with RLS Status** ✅
- Look for: `✅ RLS Enabled` for all tables
- **Policy Count**: Should be > 0 for critical tables

#### **Check 3: All RLS Policies** 📋
- Lists all policies on all tables
- Verify critical tables have policies

#### **Check 4: Critical Tables Status** 🔒
- Shows security status for important tables:
  - `fighter_profiles`
  - `fight_records`
  - `chat_messages`
  - `notifications`
  - `training_camp_invitations`
  - `callout_requests`
  - `disputes`
  - `scheduled_fights`
  - `matchmaking_requests`

#### **Summary Report** 📊
- Shows total tables, tables with RLS, and total policies
- **Green checkmark** = All good ✅
- **Warning** = Issues found ⚠️

---

### **Step 4: Fix Any Issues**

**If any tables show "RLS NOT ENABLED":**

1. Note which tables need RLS
2. For each table, run:
   ```sql
   ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
   ```
3. Then create appropriate policies (see existing schema files for examples)

**If critical tables show "NOT PROTECTED":**
- These tables MUST have RLS enabled
- Check existing database schema files for policy examples

---

### **Step 5: Verify Critical Tables**

Make sure these tables have RLS enabled AND have policies:

- ✅ `fighter_profiles` - Users can only edit their own
- ✅ `fight_records` - Users can only add their own records
- ✅ `chat_messages` - Users can only edit/delete their own
- ✅ `notifications` - Users can only see their own
- ✅ `training_camp_invitations` - Proper access control
- ✅ `callout_requests` - Users can only see their own
- ✅ `disputes` - Users can only see disputes they're involved in

---

## ✅ **SUCCESS CRITERIA**

You're good to go if:
- ✅ Check 1 returns **0 rows** (no tables without RLS)
- ✅ All critical tables show **✅ Protected**
- ✅ Summary shows **"All tables have RLS enabled!"**
- ✅ Policy count > 0 for critical tables

---

## 🆘 **NEED HELP?**

If you see issues:
1. Take a screenshot of the results
2. Note which tables are missing RLS
3. Check existing database schema files for policy examples
4. Or ask for help creating policies for specific tables

---

**Ready to test?** Run the script and share the results!

